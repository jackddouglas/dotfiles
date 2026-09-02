// Adapted from mitsuhiko/agent-stuff's subagent extension.
// Licensed under Apache-2.0; see LICENSE.

import { spawnSync } from "node:child_process";
import { randomUUID } from "node:crypto";
import { existsSync } from "node:fs";
import { mkdir, readFile, rename, stat, writeFile } from "node:fs/promises";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

import { StringEnum } from "@earendil-works/pi-ai";
import {
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
  getAgentDir,
  truncateHead,
  type ExtensionAPI,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";

import { restoreSessionTaskTitle } from "../session-task.ts";

import {
  findCmuxWorkspace,
  findTmuxWindow,
  interactiveChildCommand,
  isSameOrDescendant,
  parseCmuxIdentity,
  parseCmuxSurfaceTarget,
  parseFirstCmuxSurface,
  parseCmuxWorkspaceTarget,
  parseTmuxIdentity,
  parseTmuxWindowCreation,
  selectTerminalBackend,
  setTmuxPaneTitle,
  shellQuote,
  terminalWorkspaceNameForSession,
  tmuxClosePaneOnExitArgs,
  TMUX_WINDOW_LIST_FORMAT,
  tmuxNewWindowArgs,
  tmuxPaneHasExited,
  tmuxSplitWindowArgs,
  tmuxWindowIdentityArgs,
  tmuxWindowNameForSession,
  type TerminalBackend,
  type TerminalChoice,
} from "./terminal.ts";
import {
  formatElapsed,
  formatPreviewMetadata,
  hasPreviewDetails,
  isCancelledToolResult,
  previewTask,
} from "./preview.ts";

const ATTACH_FLAG = "attach-subagent";
const CHILD_ENV = "PI_SUBAGENT_CHILD";
const RESULT_ENV = "PI_SUBAGENT_RESULT";
const RUNS_DIR = "subagents";
const POLL_INTERVAL_MS = 500;
const PANE_PREVIEW_LINES = 18;
const THINKING_LEVELS = [
  "off",
  "minimal",
  "low",
  "medium",
  "high",
  "xhigh",
  "max",
] as const;
const EXTENSION_PATH = fileURLToPath(import.meta.url);

type RunStatus = "running" | "completed" | "failed";

interface ChildResult {
  version: 1;
  status: "completed" | "failed";
  output: string;
  error?: string;
  stopReason?: string;
  sessionFile?: string;
  provider?: string;
  model?: string;
  thinking?: string;
  messageCount?: number;
  finishedAt?: number;
}

interface ChildProgress {
  version: 1;
  messageCount: number;
}

interface RunDetails {
  status: RunStatus;
  task: string;
  cwd: string;
  terminal: TerminalBackend;
  sessionName: string;
  captureCommand: string;
  killCommand: string;
  provider: string;
  model: string;
  thinking: string;
  messageCount: number;
  pane?: string;
  output?: string;
  sessionFile?: string;
  startedAt?: number;
  finishedAt?: number;
}

interface RunSpec {
  task: string;
  cwd: string;
  terminal: TerminalBackend;
  parentSessionId: string;
  sessionName: string;
  runName: string;
  target: string;
  tmuxSocket?: string;
  workspaceTarget?: string;
  parentWindow?: string;
  captureCommand: string;
  killCommand: string;
  provider: string;
  model: string;
  thinking: string;
  trusted: boolean;
}

interface TmuxWorkspaceState {
  socketPath: string;
  sessionTarget: string;
  windowTarget: string;
  initialPane?: string;
  initialPaneClaimed: boolean;
}

interface CmuxWorkspaceState {
  target: string;
  parentWindow: string;
  initialSurface?: string;
  initialSurfaceClaimed: boolean;
}

function currentTmuxSocket(): string | undefined {
  try {
    return parseTmuxIdentity().socketPath;
  } catch {
    return undefined;
  }
}

function attachFlagValue(argv: string[]): string | undefined {
  const flag = `--${ATTACH_FLAG}`;
  for (let index = 2; index < argv.length; index++) {
    const argument = argv[index];
    if (argument === "--") break;
    if (argument === flag) {
      const value = argv[index + 1];
      return !value || value.startsWith("--") ? "" : value;
    }
    if (argument.startsWith(`${flag}=`)) return argument.slice(flag.length + 1);
  }
  return undefined;
}

function tmuxCommandPrefix(socketPath: string): string {
  return `tmux -S ${shellQuote(socketPath)}`;
}

function tmuxArgs(socketPath: string, ...args: string[]): string[] {
  return ["-S", socketPath, ...args];
}

function updateTerminalCommands(spec: RunSpec): void {
  if (!spec.target) return;
  if (spec.terminal === "tmux") {
    const tmux = tmuxCommandPrefix(spec.tmuxSocket!);
    spec.captureCommand = `${tmux} capture-pane -p -J -t ${shellQuote(spec.target)}`;
    spec.killCommand = `${tmux} kill-pane -t ${shellQuote(spec.target)}`;
    return;
  }
  const window = spec.parentWindow
    ? ` --window ${shellQuote(spec.parentWindow)}`
    : "";
  const workspace = spec.workspaceTarget
    ? ` --workspace ${shellQuote(spec.workspaceTarget)}`
    : "";
  spec.captureCommand = `cmux read-screen${workspace} --surface ${shellQuote(spec.target)}${window} --scrollback --lines 200`;
  spec.killCommand = `cmux close-surface${workspace} --surface ${shellQuote(spec.target)}${window}`;
}

function attachToSubagentAndExit(rawTarget: string): never {
  const target = rawTarget.trim();
  if (!target) {
    console.error(`Error: --${ATTACH_FLAG} requires the parent Pi session id.`);
    process.exit(2);
  }

  if (target.startsWith("v1.")) {
    // Keep attachment working for sessions started on the former dedicated
    // tmux server.
    let socket: string;
    let session: string;
    try {
      const legacy = JSON.parse(
        Buffer.from(target.slice(3), "base64url").toString("utf8"),
      ) as {
        s?: unknown;
        p?: unknown;
      };
      if (
        typeof legacy.s !== "string" ||
        !legacy.s ||
        typeof legacy.p !== "string" ||
        !legacy.p
      ) {
        throw new Error("missing tmux session or socket");
      }
      session = legacy.s;
      socket = legacy.p;
    } catch (error) {
      console.error(
        `Error: invalid legacy subagent target: ${error instanceof Error ? error.message : String(error)}`,
      );
      process.exit(2);
    }

    const sameServer = currentTmuxSocket() === socket;
    const env = { ...process.env };
    if (!sameServer) {
      delete env.TMUX;
      delete env.TMUX_PANE;
    }
    const result = spawnSync(
      "tmux",
      [
        "-S",
        socket,
        sameServer ? "switch-client" : "attach-session",
        "-t",
        session,
      ],
      { stdio: "inherit", env },
    );
    if (result.error)
      console.error(`Failed to run tmux: ${result.error.message}`);
    process.exit(result.status ?? 1);
  }

  if (
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
      target,
    )
  ) {
    console.error(`Error: invalid parent Pi session id: ${target}`);
    process.exit(2);
  }

  let identity: ReturnType<typeof parseTmuxIdentity>;
  try {
    identity = parseTmuxIdentity();
  } catch (error) {
    console.error(
      `Error: ${error instanceof Error ? error.message : String(error)}`,
    );
    process.exit(2);
  }
  const session = spawnSync(
    "tmux",
    [
      "-S",
      identity.socketPath,
      "display-message",
      "-p",
      "-t",
      identity.paneId,
      "#{session_id}",
    ],
    { encoding: "utf8" },
  );
  if (session.error || session.status !== 0) {
    console.error(
      `Error: failed to identify the current tmux session: ${session.error?.message || session.stderr.trim()}`,
    );
    process.exit(1);
  }
  const listed = spawnSync(
    "tmux",
    [
      "-S",
      identity.socketPath,
      "list-windows",
      "-t",
      session.stdout.trim(),
      "-F",
      TMUX_WINDOW_LIST_FORMAT,
    ],
    { encoding: "utf8" },
  );
  const window =
    !listed.error && listed.status === 0
      ? findTmuxWindow(listed.stdout, target)
      : undefined;
  if (!window) {
    console.error("Error: no subagent window exists in this tmux session.");
    process.exit(1);
  }
  const result = spawnSync(
    "tmux",
    ["-S", identity.socketPath, "select-window", "-t", window.target],
    { stdio: "inherit" },
  );
  if (result.error)
    console.error(`Failed to run tmux: ${result.error.message}`);
  process.exit(result.status ?? 1);
}

async function startTerminal(
  pi: ExtensionAPI,
  spec: RunSpec,
  launcherPath: string,
  tmuxWorkspaces: Map<string, Promise<TmuxWorkspaceState>>,
  cmuxWorkspaces: Map<string, Promise<CmuxWorkspaceState>>,
): Promise<void> {
  if (spec.terminal === "tmux") {
    const version = await pi.exec("tmux", ["-V"], { timeout: 5_000 });
    if (version.code !== 0)
      throw new Error(
        `tmux is required for this subagent: ${version.stderr.trim() || "tmux not found"}`,
      );
    const workspace = await resolveTmuxWorkspace(
      pi,
      spec,
      launcherPath,
      tmuxWorkspaces,
    );
    spec.tmuxSocket = workspace.socketPath;

    if (workspace.initialPane && !workspace.initialPaneClaimed) {
      workspace.initialPaneClaimed = true;
      spec.target = workspace.initialPane;
    } else {
      const created = await pi.exec(
        "tmux",
        tmuxArgs(
          workspace.socketPath,
          ...tmuxSplitWindowArgs(
            workspace.windowTarget,
            spec.cwd,
            launcherPath,
          ),
        ),
      );
      if (created.code !== 0) {
        throw new Error(
          `Failed to create tmux subagent pane: ${created.stderr.trim() || created.stdout.trim()}`,
        );
      }
      spec.target = created.stdout.trim().split("\n").at(-1)?.trim() ?? "";
      if (!spec.target)
        throw new Error("tmux did not report the created subagent pane.");
    }

    updateTerminalCommands(spec);
    await setTmuxPaneTitle(
      (command, args) => pi.exec(command, args),
      tmuxArgs(workspace.socketPath),
      spec.target,
      spec.runName,
    );
    const tiled = await pi.exec(
      "tmux",
      tmuxArgs(
        workspace.socketPath,
        "select-layout",
        "-t",
        workspace.windowTarget,
        "tiled",
      ),
    );
    if (tiled.code !== 0)
      throw new Error(tiled.stderr.trim() || "Failed to tile subagent panes.");
    const remain = await pi.exec(
      "tmux",
      tmuxArgs(workspace.socketPath, ...tmuxClosePaneOnExitArgs(spec.target)),
    );
    if (remain.code !== 0)
      throw new Error(
        remain.stderr.trim() || "Failed to disable remain-on-exit.",
      );
    return;
  }

  const workspace = await resolveCmuxWorkspace(pi, spec, cmuxWorkspaces);
  spec.parentWindow = workspace.parentWindow;
  spec.workspaceTarget = workspace.target;

  if (workspace.initialSurface && !workspace.initialSurfaceClaimed) {
    workspace.initialSurfaceClaimed = true;
    spec.target = workspace.initialSurface;
  } else {
    const created = await pi.exec(
      "cmux",
      [
        "--json",
        "--id-format",
        "both",
        "new-pane",
        "--type",
        "terminal",
        "--direction",
        "right",
        "--workspace",
        workspace.target,
        "--window",
        workspace.parentWindow,
        "--focus",
        "false",
      ],
      { timeout: 10_000 },
    );
    if (created.code !== 0)
      throw new Error(
        `Failed to create cmux subagent pane: ${created.stderr.trim() || created.stdout.trim()}`,
      );
    spec.target = parseCmuxSurfaceTarget(created.stdout);
  }
  updateTerminalCommands(spec);
  const childCommand = interactiveChildCommand(launcherPath);

  const sent = await pi.exec("cmux", [
    "send",
    "--workspace",
    workspace.target,
    "--surface",
    spec.target,
    "--window",
    workspace.parentWindow,
    `cd ${shellQuote(spec.cwd)} && ${childCommand}`,
  ]);
  if (sent.code !== 0)
    throw new Error(sent.stderr.trim() || "Failed to start child Pi.");
  const entered = await pi.exec("cmux", [
    "send-key",
    "--workspace",
    workspace.target,
    "--surface",
    spec.target,
    "--window",
    workspace.parentWindow,
    "Enter",
  ]);
  if (entered.code !== 0)
    throw new Error(entered.stderr.trim() || "Failed to submit child command.");
}

async function resolveTmuxWorkspace(
  pi: ExtensionAPI,
  spec: RunSpec,
  launcherPath: string,
  workspaces: Map<string, Promise<TmuxWorkspaceState>>,
): Promise<TmuxWorkspaceState> {
  const identity = parseTmuxIdentity();
  const identified = await pi.exec(
    "tmux",
    tmuxArgs(
      identity.socketPath,
      "display-message",
      "-p",
      "-t",
      identity.paneId,
      "#{session_id}",
    ),
    { timeout: 5_000 },
  );
  if (identified.code !== 0) {
    throw new Error(
      `Failed to identify the current tmux session: ${identified.stderr.trim() || identified.stdout.trim()}`,
    );
  }
  const sessionTarget = identified.stdout.trim();
  if (!sessionTarget)
    throw new Error("tmux did not report the current session.");

  const key = `${identity.socketPath}\0${sessionTarget}\0${spec.sessionName}`;
  let workspacePromise = workspaces.get(key);
  if (!workspacePromise) {
    workspacePromise = findOrCreateTmuxWorkspace(
      pi,
      identity.socketPath,
      sessionTarget,
      spec.parentSessionId,
      spec.sessionName,
      spec.cwd,
      launcherPath,
    );
    workspaces.set(key, workspacePromise);
  }
  try {
    return await workspacePromise;
  } finally {
    if (workspaces.get(key) === workspacePromise) workspaces.delete(key);
  }
}

async function findOrCreateTmuxWorkspace(
  pi: ExtensionAPI,
  socketPath: string,
  sessionTarget: string,
  parentSessionId: string,
  name: string,
  cwd: string,
  launcherPath: string,
): Promise<TmuxWorkspaceState> {
  const listed = await pi.exec(
    "tmux",
    tmuxArgs(
      socketPath,
      "list-windows",
      "-t",
      sessionTarget,
      "-F",
      TMUX_WINDOW_LIST_FORMAT,
    ),
    { timeout: 5_000 },
  );
  if (listed.code !== 0) {
    throw new Error(
      `Failed to list windows in the current tmux session: ${listed.stderr.trim() || listed.stdout.trim()}`,
    );
  }
  const existing = findTmuxWindow(listed.stdout, parentSessionId);
  if (existing) {
    const tagged = await pi.exec(
      "tmux",
      tmuxArgs(
        socketPath,
        ...tmuxWindowIdentityArgs(existing.target, parentSessionId),
      ),
    );
    if (tagged.code !== 0) {
      throw new Error(
        `Failed to identify tmux subagent window: ${tagged.stderr.trim() || tagged.stdout.trim()}`,
      );
    }
    const renamed = await pi.exec(
      "tmux",
      tmuxArgs(socketPath, "rename-window", "-t", existing.target, name),
    );
    if (renamed.code !== 0) {
      throw new Error(
        `Failed to rename tmux subagent window: ${renamed.stderr.trim() || renamed.stdout.trim()}`,
      );
    }
    return {
      socketPath,
      sessionTarget,
      windowTarget: existing.target,
      initialPaneClaimed: true,
    };
  }

  const created = await pi.exec(
    "tmux",
    tmuxArgs(
      socketPath,
      ...tmuxNewWindowArgs(sessionTarget, name, cwd, launcherPath),
    ),
  );
  if (created.code !== 0) {
    throw new Error(
      `Failed to create tmux subagent window: ${created.stderr.trim() || created.stdout.trim()}`,
    );
  }
  const targets = parseTmuxWindowCreation(created.stdout);
  const tagged = await pi.exec(
    "tmux",
    tmuxArgs(
      socketPath,
      ...tmuxWindowIdentityArgs(targets.windowTarget, parentSessionId),
    ),
  );
  if (tagged.code !== 0) {
    await pi.exec(
      "tmux",
      tmuxArgs(socketPath, "kill-window", "-t", targets.windowTarget),
    );
    throw new Error(
      `Failed to identify tmux subagent window: ${tagged.stderr.trim() || tagged.stdout.trim()}`,
    );
  }
  return {
    socketPath,
    sessionTarget,
    windowTarget: targets.windowTarget,
    initialPane: targets.paneTarget,
    initialPaneClaimed: false,
  };
}

async function resolveCmuxWorkspace(
  pi: ExtensionAPI,
  spec: RunSpec,
  workspaces: Map<string, Promise<CmuxWorkspaceState>>,
): Promise<CmuxWorkspaceState> {
  const identified = await pi.exec(
    "cmux",
    ["--json", "--id-format", "both", "identify"],
    { timeout: 5_000 },
  );
  if (identified.code !== 0)
    throw new Error(
      `cmux is required for this subagent: ${identified.stderr.trim() || "cmux is not available"}`,
    );
  const identity = parseCmuxIdentity(identified.stdout);
  const key = `${identity.windowId}\0${spec.sessionName}`;
  let workspacePromise = workspaces.get(key);
  if (!workspacePromise) {
    workspacePromise = findOrCreateCmuxWorkspace(
      pi,
      identity.windowId,
      spec.sessionName,
      spec.cwd,
    );
    workspaces.set(key, workspacePromise);
  }
  try {
    return await workspacePromise;
  } finally {
    if (workspaces.get(key) === workspacePromise) workspaces.delete(key);
  }
}

async function findOrCreateCmuxWorkspace(
  pi: ExtensionAPI,
  parentWindow: string,
  name: string,
  cwd: string,
): Promise<CmuxWorkspaceState> {
  const listed = await pi.exec(
    "cmux",
    [
      "--json",
      "--id-format",
      "both",
      "workspace",
      "list",
      "--window",
      parentWindow,
    ],
    { timeout: 5_000 },
  );
  if (listed.code !== 0)
    throw new Error(
      `Failed to list cmux workspaces: ${listed.stderr.trim() || listed.stdout.trim()}`,
    );
  const existing = findCmuxWorkspace(listed.stdout, name);
  if (existing) {
    return {
      target: existing.target,
      parentWindow,
      initialSurfaceClaimed: true,
    };
  }

  const created = await pi.exec(
    "cmux",
    [
      "--json",
      "--id-format",
      "both",
      "workspace",
      "create",
      "--name",
      name,
      "--cwd",
      cwd,
      "--window",
      parentWindow,
      "--focus",
      "false",
    ],
    { timeout: 10_000 },
  );
  if (created.code !== 0)
    throw new Error(
      `Failed to create cmux workspace: ${created.stderr.trim() || created.stdout.trim()}`,
    );
  const target = parseCmuxWorkspaceTarget(created.stdout);
  const surfaces = await pi.exec(
    "cmux",
    [
      "--json",
      "--id-format",
      "both",
      "list-pane-surfaces",
      "--workspace",
      target,
      "--window",
      parentWindow,
    ],
    { timeout: 5_000 },
  );
  if (surfaces.code !== 0)
    throw new Error(
      `Failed to resolve the cmux workspace surface: ${surfaces.stderr.trim() || surfaces.stdout.trim()}`,
    );
  return {
    target,
    parentWindow,
    initialSurface: parseFirstCmuxSurface(surfaces.stdout),
    initialSurfaceClaimed: false,
  };
}

async function captureTerminal(
  pi: ExtensionAPI,
  spec: RunSpec,
): Promise<{ code: number; stdout: string; stderr: string }> {
  if (spec.terminal === "tmux") {
    return pi.exec(
      "tmux",
      tmuxArgs(spec.tmuxSocket!, "capture-pane", "-p", "-J", "-t", spec.target),
      { timeout: 5_000 },
    );
  }
  return pi.exec(
    "cmux",
    [
      "read-screen",
      "--workspace",
      spec.workspaceTarget!,
      "--surface",
      spec.target,
      ...(spec.parentWindow ? ["--window", spec.parentWindow] : []),
      "--scrollback",
      "--lines",
      "200",
    ],
    { timeout: 5_000 },
  );
}

async function terminalExited(
  pi: ExtensionAPI,
  spec: RunSpec,
): Promise<boolean> {
  if (spec.terminal !== "tmux") return false;
  const result = await pi.exec(
    "tmux",
    tmuxArgs(
      spec.tmuxSocket!,
      "display-message",
      "-p",
      "-t",
      spec.target,
      "#{pane_dead}",
    ),
  );
  return tmuxPaneHasExited(result.code, result.stdout);
}

async function stopTerminal(pi: ExtensionAPI, spec: RunSpec): Promise<void> {
  if (!spec.target) return;
  if (spec.terminal === "tmux") {
    await pi.exec(
      "tmux",
      tmuxArgs(spec.tmuxSocket!, "kill-pane", "-t", spec.target),
    );
    return;
  }
  const args = [
    "close-surface",
    "--workspace",
    spec.workspaceTarget!,
    "--surface",
    spec.target,
  ];
  if (spec.parentWindow) args.push("--window", spec.parentWindow);
  await pi.exec("cmux", args);
}

function getPiInvocationParts(): string[] {
  const currentScript = process.argv[1];
  if (currentScript && existsSync(currentScript)) {
    return [process.execPath, currentScript];
  }

  const execName = path.basename(process.execPath).toLowerCase();
  if (!/^(node|bun)(\.exe)?$/.test(execName)) {
    return [process.execPath];
  }

  return ["pi"];
}

function textFromAssistant(message: Record<string, unknown>): string {
  const content = message.content;
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  return content
    .filter((part): part is { type: "text"; text: string } => {
      return Boolean(
        part &&
          typeof part === "object" &&
          part.type === "text" &&
          typeof part.text === "string",
      );
    })
    .map((part) => part.text)
    .join("\n");
}

function findLastAssistant(
  ctx: ExtensionContext,
): Record<string, unknown> | undefined {
  const branch = ctx.sessionManager.getBranch();
  for (let index = branch.length - 1; index >= 0; index--) {
    const entry = branch[index];
    if (entry.type !== "message") continue;
    const message = entry.message as unknown as Record<string, unknown>;
    if (message.role === "assistant") return message;
  }
  return undefined;
}

async function writeJsonAtomic(
  filePath: string,
  value: unknown,
): Promise<void> {
  const temporaryPath = `${filePath}.${process.pid}.${randomUUID()}.tmp`;
  await writeFile(temporaryPath, `${JSON.stringify(value)}\n`, {
    encoding: "utf8",
    mode: 0o600,
  });
  await rename(temporaryPath, filePath);
}

function registerChildReporter(pi: ExtensionAPI, resultPath: string): void {
  let reported = false;
  let messageCount = 0;
  const progressPath = `${resultPath}.progress`;

  pi.on("message_end", async () => {
    messageCount += 1;
    try {
      await writeJsonAtomic(progressPath, {
        version: 1,
        messageCount,
      } satisfies ChildProgress);
    } catch (error) {
      console.error(
        `[subagent] Failed to write progress: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  });

  const report = async (
    ctx: ExtensionContext,
    fallbackError?: string,
  ): Promise<void> => {
    if (reported) return;
    reported = true;

    const assistant = findLastAssistant(ctx);
    const stopReason =
      typeof assistant?.stopReason === "string"
        ? assistant.stopReason
        : undefined;
    const assistantError =
      typeof assistant?.errorMessage === "string"
        ? assistant.errorMessage
        : undefined;
    const failed =
      !assistant ||
      stopReason === "error" ||
      stopReason === "aborted" ||
      Boolean(fallbackError);
    const output = assistant ? textFromAssistant(assistant) : "";
    const result: ChildResult = {
      version: 1,
      status: failed ? "failed" : "completed",
      output,
      error:
        fallbackError ??
        assistantError ??
        (!assistant
          ? "Subagent exited without an assistant response."
          : undefined),
      stopReason,
      sessionFile: ctx.sessionManager.getSessionFile(),
      provider:
        typeof assistant?.provider === "string"
          ? assistant.provider
          : ctx.model?.provider,
      model:
        typeof assistant?.model === "string" ? assistant.model : ctx.model?.id,
      thinking: pi.getThinkingLevel(),
      messageCount,
      finishedAt: Date.now(),
    };

    try {
      await writeJsonAtomic(resultPath, result);
    } catch (error) {
      console.error(
        `[subagent] Failed to write result: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  };

  // agent_settled was added after older peer type declarations but is present
  // in the Pi runtime this extension targets.
  (
    pi.on as unknown as (
      event: "agent_settled",
      handler: (event: unknown, ctx: ExtensionContext) => void | Promise<void>,
    ) => void
  )("agent_settled", async (_event, ctx) => {
    await report(ctx);
    ctx.shutdown();
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    if (!reported)
      await report(ctx, "Subagent session shut down before the task settled.");
  });
}

function trimPane(output: string): string {
  const lines = output.replace(/\r/g, "").split("\n");
  while (lines.length > 0 && !lines[0]?.trim()) lines.shift();
  while (lines.length > 0 && !lines[lines.length - 1]?.trim()) lines.pop();
  return lines.slice(-PANE_PREVIEW_LINES).join("\n");
}

function detailsFor(
  spec: RunSpec,
  status: RunStatus,
  extra: Partial<RunDetails> = {},
): RunDetails {
  return {
    status,
    task: spec.task,
    cwd: spec.cwd,
    terminal: spec.terminal,
    sessionName: spec.sessionName,
    captureCommand: spec.captureCommand,
    killCommand: spec.killCommand,
    provider: spec.provider,
    model: spec.model,
    thinking: spec.thinking,
    messageCount: 0,
    ...extra,
  };
}

function partialText(details: RunDetails): string {
  const lines = [`Subagent ${details.status} in ${details.terminal}.`];
  if (details.pane) lines.push("", details.pane);
  return lines.join("\n");
}

function truncateToolText(text: string): string {
  const truncated = truncateHead(text, {
    maxBytes: DEFAULT_MAX_BYTES,
    maxLines: DEFAULT_MAX_LINES,
  });
  if (!truncated.truncated) return truncated.content;
  return `${truncated.content}\n\n[Output truncated. Full output is available in the child session file.]`;
}

function resultText(details: RunDetails): string {
  const duration = formatElapsed(details.startedAt, details.finishedAt);
  const lines = [
    `Subagent ${details.status}${duration ? ` after ${duration}` : ""}.`,
    `Model: ${details.provider}/${details.model} (${details.thinking})`,
    `Messages: ${details.messageCount}`,
  ];
  if (details.output) lines.push("", details.output);
  return truncateToolText(lines.join("\n"));
}

async function abortableDelay(
  ms: number,
  signal: AbortSignal | undefined,
): Promise<void> {
  if (signal?.aborted) throw new Error("Subagent aborted.");
  await new Promise<void>((resolve, reject) => {
    const cleanup = () => signal?.removeEventListener("abort", onAbort);
    const timer = setTimeout(() => {
      cleanup();
      resolve();
    }, ms);
    const onAbort = () => {
      clearTimeout(timer);
      cleanup();
      reject(new Error("Subagent aborted."));
    };
    signal?.addEventListener("abort", onAbort, { once: true });
  });
}

async function validateCwd(cwd: string): Promise<void> {
  let info;
  try {
    info = await stat(cwd);
  } catch {
    throw new Error(`Subagent working directory does not exist: ${cwd}`);
  }
  if (!info.isDirectory())
    throw new Error(`Subagent working directory is not a directory: ${cwd}`);
}

function resolveModel(
  ctx: ExtensionContext,
  providerOverride: string | undefined,
  modelOverride: string | undefined,
): { provider: string; model: string } {
  const explicitProvider = providerOverride?.trim();
  const explicitModel = modelOverride?.trim();
  let provider = explicitProvider || ctx.model?.provider || "";
  let model = explicitModel || ctx.model?.id || "";

  // A slash in an inherited id can be part of the id itself (for example,
  // OpenRouter's openai/gpt-* models). Only interpret an explicit model as
  // provider/model when no separate provider was supplied. If both are given
  // and the prefixes agree, accept the redundant canonical provider/model form.
  const slashIndex = explicitModel?.indexOf("/") ?? -1;
  if (explicitModel && slashIndex > 0) {
    const modelProvider = explicitModel.slice(0, slashIndex);
    if (!explicitProvider) {
      provider = modelProvider;
      model = explicitModel.slice(slashIndex + 1);
    } else if (explicitProvider === modelProvider) {
      model = explicitModel.slice(slashIndex + 1);
    }
  }

  if (!provider || !model) {
    throw new Error(
      "No model is active. Pass both provider and model to the subagent tool.",
    );
  }
  return { provider, model };
}

export default function subagentExtension(pi: ExtensionAPI): void {
  pi.registerFlag(ATTACH_FLAG, {
    description:
      "Select the shared tmux subagent window for a parent Pi session id",
    type: "string",
  });
  const attachTarget = attachFlagValue(process.argv);
  if (attachTarget !== undefined) attachToSubagentAndExit(attachTarget);

  if (process.env[CHILD_ENV] === "1") {
    const resultPath = process.env[RESULT_ENV];
    if (!resultPath) {
      console.error(`[subagent] ${RESULT_ENV} is required in child mode.`);
      return;
    }
    registerChildReporter(pi, resultPath);
    return;
  }

  const activeRuns = new Set<RunSpec>();
  const tmuxWorkspaces = new Map<string, Promise<TmuxWorkspaceState>>();
  const cmuxWorkspaces = new Map<string, Promise<CmuxWorkspaceState>>();
  pi.on("session_shutdown", async () => {
    await Promise.all([...activeRuns].map((spec) => stopTerminal(pi, spec)));
    activeRuns.clear();
  });

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description:
      "Run one delegated task in a separate observable Pi process inside tmux or cmux. Calls may run concurrently without an extension-level limit. The child inherits the current provider, model, and thinking level unless overridden. The expanded view separates the delegated task from live terminal or response output. Output is capped at 50KB or 2000 lines; the complete child session is preserved on disk.",
    promptSnippet:
      "Run one delegated task in an observable tmux or cmux Pi session",
    promptGuidelines: [
      "Use one subagent call per delegated task. Independent calls can run concurrently.",
      "Give each child a complete task because it does not inherit the parent conversation.",
    ],
    executionMode: "parallel",
    parameters: Type.Object({
      task: Type.String({
        description: "The complete task for the child Pi process",
      }),
      cwd: Type.Optional(
        Type.String({
          description: "Working directory. Defaults to the current project.",
        }),
      ),
      provider: Type.Optional(
        Type.String({
          description: "Provider override. Defaults to the current provider.",
        }),
      ),
      model: Type.Optional(
        Type.String({
          description:
            "Model id or provider/model override. Defaults to the current model.",
        }),
      ),
      thinking: Type.Optional(
        StringEnum(THINKING_LEVELS, {
          description:
            "Thinking level override. Defaults to the current thinking level.",
        }),
      ),
      terminal: Type.Optional(
        StringEnum(["auto", "tmux", "cmux"] as const, {
          description:
            "Terminal backend. Auto uses an active tmux pane first (including tmux nested in cmux), then cmux when available.",
          default: "auto",
        }),
      ),
    }),

    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      if (!params.task.trim())
        throw new Error("Subagent task must not be empty.");
      const cwd = path.resolve(ctx.cwd, params.cwd?.trim() || ".");
      await validateCwd(cwd);
      const selectedModel = resolveModel(ctx, params.provider, params.model);
      const thinking = params.thinking ?? pi.getThinkingLevel();
      const parentSessionId = ctx.sessionManager.getSessionId();
      const childSessionId = randomUUID();
      const generatedTitle = restoreSessionTaskTitle(
        ctx.sessionManager.getBranch(),
      );
      const terminal = selectTerminalBackend(
        (params.terminal ?? "auto") as TerminalChoice,
      );
      const sessionName =
        terminal === "tmux"
          ? tmuxWindowNameForSession(generatedTitle, pi.getSessionName())
          : terminalWorkspaceNameForSession(
              parentSessionId,
              generatedTitle,
              pi.getSessionName(),
            );
      const runDir = path.join(
        getAgentDir(),
        RUNS_DIR,
        parentSessionId,
        childSessionId,
      );
      const resultPath = path.join(runDir, "result.json");
      const progressPath = `${resultPath}.progress`;
      const spec: RunSpec = {
        task: params.task,
        cwd,
        terminal,
        parentSessionId,
        sessionName,
        runName: `subagent-${childSessionId.slice(0, 8)}`,
        target: "",
        captureCommand: "",
        killCommand: "",
        provider: selectedModel.provider,
        model: selectedModel.model,
        thinking,
        trusted:
          isSameOrDescendant(path.resolve(ctx.cwd), cwd) &&
          ctx.isProjectTrusted(),
      };

      await mkdir(runDir, { recursive: true, mode: 0o700 });
      const promptPath = path.join(runDir, "task.md");
      const sessionDir = path.join(runDir, "session");
      const launcherPath = path.join(runDir, "run.sh");
      await mkdir(sessionDir, { recursive: true, mode: 0o700 });
      await writeFile(promptPath, `# Delegated task\n\n${params.task}\n`, {
        encoding: "utf8",
        mode: 0o600,
      });

      const piArgs = [
        ...getPiInvocationParts(),
        "--provider",
        selectedModel.provider,
        "--model",
        selectedModel.model,
        "--thinking",
        thinking,
        "--session-dir",
        sessionDir,
        "--session-id",
        childSessionId,
        "--name",
        spec.runName,
        spec.trusted ? "--approve" : "--no-approve",
        "--extension",
        EXTENSION_PATH,
        `@${promptPath}`,
      ];
      const fallbackResult = JSON.stringify({
        version: 1,
        status: "failed",
        output: "",
        error: "Child Pi exited before reporting a result.",
      });
      const fallbackPath = `${resultPath}.launcher.tmp`;
      const launcher = [
        "#!/bin/sh",
        `${CHILD_ENV}=1 ${RESULT_ENV}=${shellQuote(resultPath)} ${piArgs.map(shellQuote).join(" ")}`,
        "status=$?",
        `if [ ! -f ${shellQuote(resultPath)} ]; then`,
        `  printf '%s\\n' ${shellQuote(fallbackResult)} > ${shellQuote(fallbackPath)}`,
        `  mv ${shellQuote(fallbackPath)} ${shellQuote(resultPath)}`,
        "fi",
        'exit "$status"',
        "",
      ].join("\n");
      await writeFile(launcherPath, launcher, {
        encoding: "utf8",
        mode: 0o700,
      });
      const startedAt = Date.now();
      let terminalStarted = false;

      try {
        await startTerminal(
          pi,
          spec,
          launcherPath,
          tmuxWorkspaces,
          cmuxWorkspaces,
        );
        terminalStarted = true;
        activeRuns.add(spec);
        const initialDetails = detailsFor(spec, "running", { startedAt });
        onUpdate?.({
          content: [{ type: "text", text: partialText(initialDetails) }],
          details: initialDetails,
        });

        let lastPane = "";
        let messageCount = 0;
        let lastRenderedSecond = 0;
        let lastRenderedMessageCount = 0;
        let childResult: ChildResult | undefined;
        while (!childResult) {
          if (signal?.aborted) throw new Error("Subagent aborted.");
          try {
            childResult = JSON.parse(
              await readFile(resultPath, "utf8"),
            ) as ChildResult;
            break;
          } catch {}

          try {
            const progress = JSON.parse(
              await readFile(progressPath, "utf8"),
            ) as ChildProgress;
            if (
              progress.version === 1 &&
              Number.isInteger(progress.messageCount) &&
              progress.messageCount >= 0
            ) {
              messageCount = progress.messageCount;
            }
          } catch {}

          const paneResult = await captureTerminal(pi, spec);
          if (paneResult.code === 0) {
            const pane = trimPane(paneResult.stdout);
            if (pane) lastPane = pane;
          }
          const elapsedSecond = Math.floor((Date.now() - startedAt) / 1000);
          if (
            elapsedSecond !== lastRenderedSecond ||
            messageCount !== lastRenderedMessageCount
          ) {
            lastRenderedSecond = elapsedSecond;
            lastRenderedMessageCount = messageCount;
            const details = detailsFor(spec, "running", {
              pane: lastPane,
              messageCount,
              startedAt,
            });
            onUpdate?.({
              content: [{ type: "text", text: partialText(details) }],
              details,
            });
          }
          if (await terminalExited(pi, spec)) {
            await abortableDelay(100, signal);
            try {
              childResult = JSON.parse(
                await readFile(resultPath, "utf8"),
              ) as ChildResult;
              break;
            } catch {
              throw new Error(
                `Child Pi exited before reporting a result.\n\n${lastPane || "No terminal output."}\n\nInspect: ${spec.captureCommand}`,
              );
            }
          }
          await abortableDelay(POLL_INTERVAL_MS, signal);
        }

        const finalPaneResult = await captureTerminal(pi, spec);
        const finalPane =
          finalPaneResult.code === 0
            ? trimPane(finalPaneResult.stdout)
            : lastPane;
        const status: RunStatus =
          childResult.status === "completed" ? "completed" : "failed";
        let rawOutput = childResult.output.trim();
        if (childResult.status === "failed" && childResult.error?.trim()) {
          rawOutput += `${rawOutput ? "\n\n" : ""}Error: ${childResult.error.trim()}`;
        }
        const output = truncateToolText(rawOutput || "(no text output)");
        const details = detailsFor(spec, status, {
          pane: finalPane,
          output,
          sessionFile: childResult.sessionFile,
          provider: childResult.provider ?? spec.provider,
          model: childResult.model ?? spec.model,
          thinking: childResult.thinking ?? spec.thinking,
          messageCount: childResult.messageCount ?? messageCount,
          startedAt,
          finishedAt: childResult.finishedAt ?? Date.now(),
        });
        if (childResult.status === "failed")
          throw new Error(resultText(details));
        return {
          content: [{ type: "text", text: resultText(details) }],
          details,
        };
      } catch (error) {
        if (signal?.aborted || !terminalStarted) await stopTerminal(pi, spec);
        throw error;
      } finally {
        activeRuns.delete(spec);
      }
    },
    renderCall(args, theme) {
      const text =
        theme.fg("toolTitle", theme.bold("subagent ")) +
        theme.fg("dim", previewTask(args.task ?? ""));
      return new Text(text, 0, 0);
    },

    renderResult(result, { expanded, isPartial }, theme, context) {
      const incomingDetails = hasPreviewDetails(result.details)
        ? (result.details as RunDetails)
        : undefined;
      if (incomingDetails) context.state.subagentRunDetails = incomingDetails;
      const savedDetails = context.state.subagentRunDetails;
      const details =
        incomingDetails ??
        (hasPreviewDetails(savedDetails)
          ? (savedDetails as RunDetails)
          : undefined);
      const cancelled = isCancelledToolResult(context.isError, result.content);
      if (!details) {
        const content = result.content.find((part) => part.type === "text");
        if (cancelled)
          return new Text(
            `${theme.fg("muted", "○")} ${theme.fg("muted", "cancelled")}`,
            0,
            0,
          );
        return new Text(
          content?.type === "text" ? content.text : "(no output)",
          0,
          0,
        );
      }

      const failed = context.isError && !cancelled;
      const running =
        !context.isError && (isPartial || details.status === "running");
      const icon = cancelled
        ? theme.fg("muted", "○")
        : running
          ? theme.fg("warning", "●")
          : failed || details.status === "failed"
            ? theme.fg("error", "✗")
            : theme.fg("success", "✓");
      const outcome = cancelled ? "cancelled · " : failed ? "failed · " : "";
      let text = `${icon} ${theme.fg(
        "muted",
        `${outcome}${formatPreviewMetadata({
          startedAt: details.startedAt,
          finishedAt: details.finishedAt,
          provider: details.provider,
          model: details.model,
          thinking: details.thinking,
          messageCount: details.messageCount,
          terminal: details.terminal,
        })}`,
      )}`;

      if (!expanded) return new Text(text, 0, 0);

      const fullTask = details.task.trim();
      if (fullTask && fullTask !== previewTask(details.task)) {
        text += `\n\n${theme.fg("toolTitle", theme.bold("Delegated task"))}`;
        text += `\n${theme.fg("dim", fullTask)}`;
      }
      if ((running || context.isError) && details.pane) {
        const paneLines = details.pane.split("\n");
        const terminalLabel = running
          ? "Live subagent terminal"
          : "Last subagent terminal output";
        text += `\n\n${theme.fg("toolTitle", theme.bold(terminalLabel))}`;
        text += `\n${paneLines.map((line) => theme.fg("dim", line)).join("\n")}`;
      } else if (!running && details.output) {
        const outputLines = details.output.split("\n");
        text += `\n\n${theme.fg("toolTitle", theme.bold("Subagent response"))}`;
        text += `\n${outputLines.map((line) => theme.fg("toolOutput", line)).join("\n")}`;
      }
      if (failed) {
        const error = result.content.find((part) => part.type === "text");
        if (error?.type === "text" && error.text.trim()) {
          text += `\n\n${theme.fg("toolTitle", theme.bold("Error"))}`;
          text += `\n${theme.fg("error", error.text.trim())}`;
        }
      }
      return new Text(text, 0, 0);
    },
  });
}
