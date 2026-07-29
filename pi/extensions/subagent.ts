import { randomUUID } from "node:crypto";
import type { Dirent } from "node:fs";
import {
  chmod,
  mkdir,
  readFile,
  readdir,
  rename,
  stat,
  writeFile,
} from "node:fs/promises";
import { join } from "node:path";
import {
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
  getAgentDir,
  truncateHead,
  type ExtensionAPI,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import {
  Key,
  matchesKey,
  truncateToWidth,
  visibleWidth,
} from "@earendil-works/pi-tui";
import { Type } from "typebox";

const TMUX_BIN = "@tmuxBin@";
const CHILD_ENV = "PI_CURRENT_TMUX_SUBAGENT_CHILD";
const RESULT_ENV = "PI_CURRENT_TMUX_SUBAGENT_RESULT";
const POLL_INTERVAL_MS = 500;
const MANAGER_REFRESH_MS = 1000;

type SubagentStatus = "running" | "completed" | "failed";

interface ChildResult {
  status: "completed" | "failed";
  output: string;
  error?: string;
  sessionFile?: string;
}

interface SubagentRecord {
  childId: string;
  paneId: string;
  paneName: string;
  task: string;
  status: SubagentStatus;
  startedAt: number;
  finishedAt?: number;
  runDir: string;
  sessionFile?: string;
  error?: string;
  closed?: boolean;
}

interface StoredSubagentRecord
  extends Omit<SubagentRecord, "runDir"> {}

interface SubagentDetails {
  status: SubagentStatus;
  paneId: string;
  paneName: string;
  output?: string;
}

function shellQuote(value: string): string {
  return `'${value.replaceAll("'", `'"'"'`)}'`;
}

function textFromAssistant(message: Record<string, unknown>): string {
  const content = message.content;
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  return content
    .filter(
      (part): part is { type: "text"; text: string } =>
        Boolean(
          part &&
          typeof part === "object" &&
          part.type === "text" &&
          typeof part.text === "string",
        ),
    )
    .map((part) => part.text)
    .join("\n");
}

function lastAssistant(ctx: ExtensionContext): Record<string, unknown> | undefined {
  const branch = ctx.sessionManager.getBranch();
  for (let index = branch.length - 1; index >= 0; index--) {
    const entry = branch[index];
    if (entry.type !== "message") continue;
    const message = entry.message as unknown as Record<string, unknown>;
    if (message.role === "assistant") return message;
  }
  return undefined;
}

async function writeChildResult(
  ctx: ExtensionContext,
  resultPath: string,
  fallbackError?: string,
): Promise<void> {
  const assistant = lastAssistant(ctx);
  const stopReason = typeof assistant?.stopReason === "string"
    ? assistant.stopReason
    : undefined;
  const assistantError = typeof assistant?.errorMessage === "string"
    ? assistant.errorMessage
    : undefined;
  const failed =
    !assistant ||
    stopReason === "error" ||
    stopReason === "aborted" ||
    Boolean(fallbackError);
  const result: ChildResult = {
    status: failed ? "failed" : "completed",
    output: assistant ? textFromAssistant(assistant) : "",
    error:
      fallbackError ??
      assistantError ??
      (!assistant ? "Subagent exited without an assistant response" : undefined),
    sessionFile: ctx.sessionManager.getSessionFile(),
  };
  const temporaryPath = `${resultPath}.${process.pid}.${randomUUID()}.tmp`;
  await writeFile(temporaryPath, `${JSON.stringify(result)}\n`, {
    encoding: "utf8",
    mode: 0o600,
  });
  await rename(temporaryPath, resultPath);
}

function registerChildReporter(pi: ExtensionAPI, resultPath: string): void {
  let reported = false;

  const report = async (ctx: ExtensionContext, fallbackError?: string) => {
    if (reported) return;
    reported = true;
    try {
      await writeChildResult(ctx, resultPath, fallbackError);
    } catch (error) {
      console.error(
        `Failed to write subagent result: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  };

  pi.on("agent_settled", async (_event, ctx) => {
    await report(ctx);
    ctx.shutdown();
  });
  pi.on("session_shutdown", async (_event, ctx) => {
    await report(ctx, "Subagent shut down before the task settled");
  });
}

function piInvocation(): string[] {
  const script = process.argv[1];
  return script ? [process.execPath, script] : [process.execPath];
}

function truncateOutput(output: string): string {
  const truncated = truncateHead(output, {
    maxBytes: DEFAULT_MAX_BYTES,
    maxLines: DEFAULT_MAX_LINES,
  });
  return truncated.truncated
    ? `${truncated.content}\n\n[Output truncated; inspect the child session for the full result.]`
    : truncated.content;
}

function taskSummary(task: string): string {
  return task.replaceAll(/\s+/g, " ").trim();
}

function shortTaskLabel(task: string): string {
  const clauses = taskSummary(task).split(/(?<=[.!?])\s+|;\s+/);
  const boilerplate = /^(you are|do not|already isolated|work directly|execute this workflow)/i;
  const candidate = clauses.find((clause) => !boilerplate.test(clause) && clause.length >= 8)
    ?? clauses[0]
    ?? "Subagent";
  const cleaned = candidate
    .replace(/^(task:\s*|your task is to\s+|please\s+)/i, "")
    .replaceAll(/[`*_#]/g, "")
    .trim();
  return cleaned.length > 52 ? `${cleaned.slice(0, 49).trimEnd()}…` : cleaned;
}

function elapsed(startedAt: number, finishedAt = Date.now()): string {
  const totalSeconds = Math.max(0, Math.floor((finishedAt - startedAt) / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return minutes > 0 ? `${minutes}m${seconds.toString().padStart(2, "0")}s` : `${seconds}s`;
}

function delay(ms: number, signal: AbortSignal | undefined): Promise<void> {
  return new Promise((resolve, reject) => {
    if (signal?.aborted) {
      reject(new Error("Subagent aborted"));
      return;
    }
    const cleanup = () => signal?.removeEventListener("abort", onAbort);
    const timer = setTimeout(() => {
      cleanup();
      resolve();
    }, ms);
    const onAbort = () => {
      clearTimeout(timer);
      cleanup();
      reject(new Error("Subagent aborted"));
    };
    signal?.addEventListener("abort", onAbort, { once: true });
  });
}

export default function (pi: ExtensionAPI) {
  const childResultPath = process.env[RESULT_ENV];
  if (process.env[CHILD_ENV] === "1") {
    if (childResultPath) registerChildReporter(pi, childResultPath);
    return;
  }

  const records = new Map<string, SubagentRecord>();
  const activePanes = new Set<string>();
  let managerOpen = false;
  let managerRefresh: (() => void) | undefined;
  let managerTimer: ReturnType<typeof setInterval> | undefined;
  let reloading = false;

  function metadataPath(runDir: string): string {
    return join(runDir, "metadata.json");
  }

  function resultPath(record: SubagentRecord): string {
    return join(record.runDir, "result.json");
  }

  async function persistRecord(record: SubagentRecord): Promise<void> {
    const stored: StoredSubagentRecord = {
      childId: record.childId,
      paneId: record.paneId,
      paneName: record.paneName,
      task: record.task,
      status: record.status,
      startedAt: record.startedAt,
      finishedAt: record.finishedAt,
      sessionFile: record.sessionFile,
      error: record.error,
      closed: record.closed,
    };
    const destination = metadataPath(record.runDir);
    const temporary = `${destination}.${process.pid}.${randomUUID()}.tmp`;
    await writeFile(temporary, `${JSON.stringify(stored)}\n`, {
      encoding: "utf8",
      mode: 0o600,
    });
    await rename(temporary, destination);
  }

  async function paneMatchesRecord(record: SubagentRecord): Promise<boolean> {
    const result = await pi.exec(
      TMUX_BIN,
      ["display-message", "-p", "-t", record.paneId, "#{pane_start_command}"],
      { timeout: 5000 },
    );
    return result.code === 0 && result.stdout.includes(join(record.runDir, "run.sh"));
  }

  async function closeSettledPane(
    paneId: string,
    signal: AbortSignal | undefined,
  ): Promise<void> {
    const deadline = Date.now() + 10_000;
    while (Date.now() < deadline) {
      if (signal?.aborted) throw new Error("Subagent aborted");
      const state = await pi.exec(
        TMUX_BIN,
        ["display-message", "-p", "-t", paneId, "#{pane_dead}"],
        { timeout: 5000, signal },
      );
      if (state.code !== 0) return;
      if (state.stdout.trim() === "1") {
        await pi.exec(TMUX_BIN, ["kill-pane", "-t", paneId]);
        return;
      }
      await delay(100, signal);
    }
    await pi.exec(TMUX_BIN, ["kill-pane", "-t", paneId]);
  }

  async function rollbackSplit(parentPane: string, scriptPath: string): Promise<void> {
    const listed = await pi.exec(
      TMUX_BIN,
      ["list-panes", "-t", parentPane, "-F", "#{pane_id}\t#{pane_start_command}"],
      { timeout: 5000 },
    );
    if (listed.code !== 0) return;
    const paneIds = listed.stdout
      .split("\n")
      .map((line) => line.split("\t", 2))
      .filter((parts) => parts.length === 2 && parts[1].includes(scriptPath))
      .map((parts) => parts[0]);
    await Promise.allSettled(
      paneIds.map((paneId) => pi.exec(TMUX_BIN, ["kill-pane", "-t", paneId])),
    );
  }

  function updateStatus(ctx: ExtensionContext): void {
    const all = [...records.values()];
    if (all.length === 0) {
      ctx.ui.setStatus("subagents", undefined);
    } else {
      const running = all.filter((record) => record.status === "running").length;
      const finished = all.length - running;
      const label = finished > 0
        ? `agents:${running} running/${finished} done`
        : `agents:${running} running`;
      ctx.ui.setStatus("subagents", ctx.ui.theme.fg(running > 0 ? "accent" : "muted", label));
    }
    managerRefresh?.();
  }

  async function retireRecord(
    record: SubagentRecord,
    ctx: ExtensionContext,
  ): Promise<void> {
    activePanes.delete(record.paneId);
    records.delete(record.paneId);
    record.closed = true;
    record.finishedAt ??= Date.now();
    await persistRecord(record).catch(() => undefined);
    updateStatus(ctx);
  }

  async function closeRecord(
    record: SubagentRecord,
    ctx: ExtensionContext,
  ): Promise<void> {
    await pi.exec(TMUX_BIN, ["kill-pane", "-t", record.paneId]);
    await retireRecord(record, ctx);
  }

  async function refreshRecord(
    record: SubagentRecord,
    ctx: ExtensionContext,
  ): Promise<void> {
    if (!(await paneMatchesRecord(record))) {
      activePanes.delete(record.paneId);
      records.delete(record.paneId);
      record.closed = true;
      await persistRecord(record).catch(() => undefined);
      return;
    }
    if (record.status !== "running") return;

    try {
      const childResult = JSON.parse(
        await readFile(resultPath(record), "utf8"),
      ) as ChildResult;
      record.status = childResult.status;
      record.finishedAt = Date.now();
      record.sessionFile = childResult.sessionFile;
      record.error = childResult.error;
      await closeSettledPane(record.paneId, undefined);
      await retireRecord(record, ctx);
    } catch {
      // The active tool call or a later refresh will observe the result.
    }
  }

  async function refreshRecords(ctx: ExtensionContext): Promise<void> {
    await Promise.allSettled(
      [...records.values()].map((record) => refreshRecord(record, ctx)),
    );
    updateStatus(ctx);
  }

  async function restoreRecords(ctx: ExtensionContext): Promise<void> {
    const root = join(
      getAgentDir(),
      "current-tmux-subagents",
      ctx.sessionManager.getSessionId(),
    );
    let directories: Dirent<string>[];
    try {
      directories = await readdir(root, { withFileTypes: true });
    } catch {
      updateStatus(ctx);
      return;
    }

    for (const directory of directories) {
      if (!directory.isDirectory()) continue;
      const runDir = join(root, directory.name);
      try {
        const stored = JSON.parse(
          await readFile(metadataPath(runDir), "utf8"),
        ) as StoredSubagentRecord;
        if (stored.closed) continue;
        const record: SubagentRecord = { ...stored, runDir };
        if (!(await paneMatchesRecord(record))) {
          record.closed = true;
          record.finishedAt ??= Date.now();
          await persistRecord(record).catch(() => undefined);
          continue;
        }
        records.set(record.paneId, record);
        if (record.status === "running") activePanes.add(record.paneId);
        await refreshRecord(record, ctx);
      } catch {
        // Ignore incomplete runs and metadata from older extension versions.
      }
    }
    updateStatus(ctx);
  }

  async function showManager(ctx: ExtensionContext): Promise<void> {
    if (ctx.mode !== "tui") {
      ctx.ui.notify("The subagent manager requires TUI mode", "error");
      return;
    }
    if (managerOpen) return;
    managerOpen = true;
    await refreshRecords(ctx);

    try {
      await ctx.ui.custom<void>(
        (tui, theme, _keybindings, done) => {
          let selectedIndex = 0;
          const sortedRecords = () =>
            [...records.values()].sort((left, right) => {
              if (left.status === "running" && right.status !== "running") return -1;
              if (right.status === "running" && left.status !== "running") return 1;
              return right.startedAt - left.startedAt;
            });
          const requestRender = () => tui.requestRender();
          managerRefresh = requestRender;

          const selectedRecord = () => {
            const items = sortedRecords();
            selectedIndex = Math.max(0, Math.min(selectedIndex, items.length - 1));
            return items[selectedIndex];
          };

          return {
            render(width: number): string[] {
              const items = sortedRecords();
              selectedIndex = Math.max(0, Math.min(selectedIndex, items.length - 1));
              const innerWidth = Math.max(1, width - 2);
              const contentWidth = Math.max(1, innerWidth - 2);
              const edge = (left: string, right: string) =>
                theme.bg(
                  "customMessageBg",
                  theme.fg(
                    "borderAccent",
                    `${left}${"─".repeat(innerWidth)}${right}`,
                  ),
                );
              const row = (content: string, selected = false) => {
                const clipped = truncateToWidth(content, contentWidth, "");
                const body = ` ${clipped}${" ".repeat(
                  Math.max(0, contentWidth - visibleWidth(clipped)),
                )} `;
                return [
                  theme.bg("customMessageBg", theme.fg("borderAccent", "│")),
                  theme.bg(selected ? "selectedBg" : "customMessageBg", body),
                  theme.bg("customMessageBg", theme.fg("borderAccent", "│")),
                ].join("");
              };
              const lines = [
                edge("╭", "╮"),
                row(theme.fg("customMessageLabel", theme.bold("Subagents"))),
                row(""),
              ];

              if (items.length === 0) {
                lines.push(
                  row(theme.fg("muted", "No active subagents in this Pi session.")),
                );
              } else {
                for (let index = 0; index < items.length; index++) {
                  const record = items[index];
                  const selected = index === selectedIndex;
                  const statusColor = record.status === "running"
                    ? "accent"
                    : record.status === "completed"
                    ? "success"
                    : "error";
                  const status = theme.fg(statusColor, record.status.padEnd(9));
                  const prefix = selected ? theme.fg("accent", "> ") : "  ";
                  const age = elapsed(record.startedAt, record.finishedAt);
                  const task = taskSummary(record.task);
                  lines.push(
                    row(
                      `${prefix}${status} ${record.paneId.padEnd(5)} ${age.padStart(6)}  ${task}`,
                      selected,
                    ),
                  );
                }
              }

              lines.push(
                row(""),
                row(
                  theme.fg(
                    "dim",
                    "↑↓ select • enter focus • x terminate • r refresh • esc close",
                  ),
                ),
                edge("╰", "╯"),
              );
              return lines;
            },
            invalidate() {},
            handleInput(data: string) {
              const items = sortedRecords();
              if (matchesKey(data, Key.up)) {
                selectedIndex = Math.max(0, selectedIndex - 1);
                requestRender();
              } else if (matchesKey(data, Key.down)) {
                selectedIndex = Math.min(Math.max(0, items.length - 1), selectedIndex + 1);
                requestRender();
              } else if (matchesKey(data, Key.enter)) {
                const record = selectedRecord();
                if (!record) return;
                done(undefined);
                void pi.exec(TMUX_BIN, ["select-pane", "-t", record.paneId]);
              } else if (data === "x") {
                const record = selectedRecord();
                if (!record) return;
                void closeRecord(record, ctx).finally(requestRender);
              } else if (data === "r") {
                void refreshRecords(ctx).finally(requestRender);
              } else if (
                matchesKey(data, Key.escape) ||
                matchesKey(data, Key.ctrl("c"))
              ) {
                done(undefined);
              }
            },
          };
        },
        {
          overlay: true,
          overlayOptions: {
            width: "85%",
            minWidth: 60,
            maxHeight: "80%",
            anchor: "center",
            margin: 1,
          },
        },
      );
    } finally {
      managerRefresh = undefined;
      managerOpen = false;
    }
  }

  pi.registerCommand("subagents", {
    description: "Manage subagent panes spawned by this Pi session",
    handler: async (_args, ctx) => showManager(ctx),
  });

  pi.registerShortcut("ctrl+shift+a", {
    description: "Open the subagent pane manager",
    handler: showManager,
  });

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description:
      "Run a fresh Pi context in a visible pane in the current tmux window. The child inherits the current model, thinking level, working directory, and project trust. Manage it with /subagents while it runs; the pane closes automatically when the child settles.",
    promptSnippet: "Delegate a task to a fresh Pi context in the current tmux window",
    promptGuidelines: [
      "Use subagent for workflows that require a fresh context; do not create detached tmux sessions through bash.",
    ],
    executionMode: "parallel",
    parameters: Type.Object({
      task: Type.String({ description: "Complete instructions for the fresh context" }),
    }),
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const task = params.task.trim();
      if (!task) throw new Error("Subagent task must not be empty");

      const parentPane = process.env.TMUX_PANE;
      if (!parentPane) throw new Error("Subagents require Pi to be running inside tmux");

      const childId = randomUUID();
      const paneName = shortTaskLabel(task);
      const runDir = join(
        getAgentDir(),
        "current-tmux-subagents",
        ctx.sessionManager.getSessionId(),
        childId,
      );
      const promptPath = join(runDir, "task.md");
      const childResultPath = join(runDir, "result.json");
      const scriptPath = join(runDir, "run.sh");
      const sessionDir = join(runDir, "session");
      await mkdir(sessionDir, { recursive: true, mode: 0o700 });
      await writeFile(promptPath, `${task}\n`, { encoding: "utf8", mode: 0o600 });

      const model = ctx.model;
      if (!model) throw new Error("Subagents require an active model");
      const childArgs = [
        ...piInvocation(),
        "--provider",
        model.provider,
        "--model",
        model.id,
        "--thinking",
        pi.getThinkingLevel(),
        "--session-dir",
        sessionDir,
        "--session-id",
        childId,
        "--name",
        paneName,
        ctx.isProjectTrusted() ? "--approve" : "--no-approve",
        `@${promptPath}`,
      ];
      const script = [
        "#!/bin/sh",
        `export ${CHILD_ENV}=1`,
        `export ${RESULT_ENV}=${shellQuote(childResultPath)}`,
        childArgs.map(shellQuote).join(" "),
        "child_status=$?",
        `if [ ! -f ${shellQuote(childResultPath)} ]; then`,
        `  printf '%s\\n' '{"status":"failed","output":"","error":"Child Pi exited before reporting a result"}' > ${shellQuote(childResultPath)}`,
        "fi",
        `printf '\\nSubagent finished. Pane: %s. Exit status: %s\\n' ${shellQuote(paneName)} "$child_status"`,
        "exit \"$child_status\"",
        "",
      ].join("\n");
      await writeFile(scriptPath, script, { encoding: "utf8", mode: 0o700 });
      await chmod(scriptPath, 0o700);

      let created: Awaited<ReturnType<typeof pi.exec>>;
      try {
        created = await pi.exec(TMUX_BIN, [
          "split-window",
          "-h",
          "-d",
          "-P",
          "-F",
          "#{pane_id}",
          "-t",
          parentPane,
          "-c",
          ctx.cwd,
          shellQuote(scriptPath),
        ]);
      } catch (error) {
        await rollbackSplit(parentPane, scriptPath);
        throw error;
      }
      if (created.code !== 0) {
        await rollbackSplit(parentPane, scriptPath);
        throw new Error(`Could not create subagent pane: ${created.stderr.trim()}`);
      }

      const paneId = created.stdout.trim();
      let record: SubagentRecord;
      try {
        if (!/^%\d+$/.test(paneId)) {
          throw new Error(`tmux returned an invalid subagent pane id: ${paneId}`);
        }
        const titled = await pi.exec(
          TMUX_BIN,
          ["select-pane", "-t", paneId, "-T", paneName],
        );
        if (titled.code !== 0) {
          throw new Error(`Could not name subagent pane: ${titled.stderr.trim()}`);
        }
        await pi.exec(TMUX_BIN, [
          "select-layout",
          "-t",
          parentPane,
          "even-horizontal",
        ]);

        record = {
          childId,
          paneId,
          paneName,
          task,
          status: "running",
          startedAt: Date.now(),
          runDir,
        };
        records.set(paneId, record);
        activePanes.add(paneId);
        await persistRecord(record);
        updateStatus(ctx);
      } catch (error) {
        records.delete(paneId);
        activePanes.delete(paneId);
        await rollbackSplit(parentPane, scriptPath);
        throw error;
      }

      if (signal?.aborted) {
        await closeRecord(record, ctx);
        throw new Error("Subagent aborted");
      }

      const inspectCommand = `tmux select-pane -t ${paneId}`;

      try {
        while (true) {
          if (signal?.aborted) throw new Error("Subagent aborted");

          try {
            await stat(childResultPath);
            break;
          } catch {
            // The child writes its result when the fresh context settles.
          }

          const dead = await pi.exec(
            TMUX_BIN,
            ["display-message", "-p", "-t", paneId, "#{pane_dead}"],
          );
          if (dead.code !== 0) {
            throw new Error(
              `Subagent pane disappeared before reporting a result: ${paneId}`,
            );
          }
          if (dead.stdout.trim() === "1") {
            await delay(100, signal);
            try {
              await stat(childResultPath);
              break;
            } catch {
              throw new Error(
                `Subagent exited without reporting a result. Inspect: ${inspectCommand}`,
              );
            }
          }

          await delay(POLL_INTERVAL_MS, signal);
        }

        const childResult = JSON.parse(
          await readFile(childResultPath, "utf8"),
        ) as ChildResult;
        const output = truncateOutput(
          childResult.output.trim() || childResult.error || "(no text output)",
        );
        record.status = childResult.status;
        record.finishedAt = Date.now();
        record.sessionFile = childResult.sessionFile;
        record.error = childResult.error;
        await closeSettledPane(paneId, signal);
        await retireRecord(record, ctx);

        const details: SubagentDetails = {
          status: record.status,
          paneId,
          paneName,
          output,
        };
        const text = [
          `Subagent ${record.status} in ${paneName} (${paneId}); pane closed automatically.`,
          childResult.sessionFile ? `Child session: ${childResult.sessionFile}` : undefined,
          "",
          output,
        ]
          .filter((line) => line !== undefined)
          .join("\n");

        if (record.status === "failed") throw new Error(text);
        return { content: [{ type: "text", text }], details };
      } catch (error) {
        activePanes.delete(paneId);
        if (signal?.aborted) {
          if (reloading) {
            activePanes.delete(paneId);
          } else if (records.has(paneId)) {
            await closeRecord(record, ctx);
          }
        } else if (records.has(paneId)) {
          if (await paneMatchesRecord(record)) {
            record.status = "failed";
            record.finishedAt = Date.now();
            record.error = error instanceof Error ? error.message : String(error);
            await persistRecord(record).catch(() => undefined);
          } else {
            records.delete(paneId);
            record.closed = true;
            await persistRecord(record).catch(() => undefined);
          }
          updateStatus(ctx);
        }
        throw error;
      }
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    await restoreRecords(ctx);
    if (managerTimer) clearInterval(managerTimer);
    managerTimer = setInterval(() => {
      void refreshRecords(ctx);
    }, MANAGER_REFRESH_MS);
  });

  pi.on("session_shutdown", async (event, ctx) => {
    if (managerTimer) clearInterval(managerTimer);
    if (event.reason === "reload") {
      reloading = true;
      activePanes.clear();
      return;
    }
    await Promise.allSettled(
      [...activePanes]
        .map((paneId) => records.get(paneId))
        .filter((record): record is SubagentRecord => Boolean(record))
        .map((record) => closeRecord(record, ctx)),
    );
  });
}
