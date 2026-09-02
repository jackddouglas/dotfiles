import * as path from "node:path";

export type TerminalBackend = "tmux" | "cmux";
export type TerminalChoice = "auto" | TerminalBackend;

export const TMUX_SESSION_OPTION = "@pi_subagent_session_id";
export const TMUX_WINDOW_LIST_FORMAT =
  "#{window_id}\t#{window_name}\t#{@pi_subagent_session_id}";

interface CmuxIdentity {
  windowId: string;
}

export interface TmuxIdentity {
  socketPath: string;
  paneId: string;
}

export interface TmuxWindow {
  target: string;
  name: string;
}

export interface CmuxWorkspace {
  target: string;
  initialSurface?: string;
}

export function shellQuote(value: string): string {
  if (value.length === 0) return "''";
  return `'${value.replace(/'/g, `'"'"'`)}'`;
}

export function tmuxChildCommandArgs(launcherPath: string): string[] {
  return ["/bin/sh", launcherPath];
}

export function interactiveChildCommand(launcherPath: string): string {
  return `/bin/sh ${shellQuote(launcherPath)}`;
}

export function tmuxNewWindowArgs(
  sessionTarget: string,
  windowName: string,
  cwd: string,
  launcherPath: string,
): string[] {
  return [
    "new-window",
    "-d",
    "-P",
    "-F",
    "#{pane_id}\t#{window_id}",
    "-t",
    sessionTarget,
    "-n",
    windowName,
    "-c",
    cwd,
    ...tmuxChildCommandArgs(launcherPath),
  ];
}

export function tmuxSplitWindowArgs(
  windowTarget: string,
  cwd: string,
  launcherPath: string,
): string[] {
  return [
    "split-window",
    "-d",
    "-P",
    "-F",
    "#{pane_id}",
    "-t",
    windowTarget,
    "-c",
    cwd,
    ...tmuxChildCommandArgs(launcherPath),
  ];
}

export function parseTmuxIdentity(
  environment: NodeJS.ProcessEnv = process.env,
): TmuxIdentity {
  const tmux = environment.TMUX?.trim();
  const paneId = environment.TMUX_PANE?.trim();
  if (!tmux || !paneId) {
    throw new Error(
      "The tmux backend requires Pi to be running inside a tmux session.",
    );
  }
  const fields = tmux.split(",");
  if (fields.length < 3) throw new Error("TMUX has an invalid value.");
  const socketPath = fields.slice(0, -2).join(",").trim();
  if (!socketPath) throw new Error("TMUX does not identify a server socket.");
  return { socketPath, paneId };
}

export function selectTerminalBackend(
  choice: TerminalChoice,
  environment: NodeJS.ProcessEnv = process.env,
): TerminalBackend {
  if (choice !== "auto") return choice;
  if (environment.TMUX && environment.TMUX_PANE) return "tmux";
  return environment.CMUX_WORKSPACE_ID || environment.CMUX_SURFACE_ID
    ? "cmux"
    : "tmux";
}

function shortSessionId(sessionId: string): string {
  const normalizedId = sessionId.trim();
  if (!normalizedId) throw new Error("Pi session id must not be empty.");
  const shortId = normalizedId.replace(/[^A-Za-z0-9]/g, "").slice(0, 8);
  if (!shortId)
    throw new Error("Pi session id must contain letters or numbers.");
  return shortId;
}

function terminalWorkspaceTitle(sessionTitle?: string): string {
  const safeTitle = sessionTitle
    ?.trim()
    .replace(/[^\p{L}\p{N}]+/gu, " ")
    .replaceAll(/\s+/g, " ")
    .trim()
    .slice(0, 52)
    .trimEnd();
  return `π′ - ${safeTitle || "Session"}`;
}

export function terminalWorkspaceName(
  sessionId: string,
  sessionTitle?: string,
): string {
  return `${terminalWorkspaceTitle(sessionTitle)} - ${shortSessionId(sessionId)}`;
}

export function tmuxWindowNameForSession(
  generatedTitle?: string,
  sessionName?: string,
): string {
  return terminalWorkspaceTitle(generatedTitle ?? sessionName);
}

export function terminalWorkspaceSuffix(sessionId: string): string {
  return ` - ${shortSessionId(sessionId)}`;
}

export function terminalWorkspaceNameForSession(
  sessionId: string,
  generatedTitle?: string,
  sessionName?: string,
): string {
  return terminalWorkspaceName(sessionId, generatedTitle ?? sessionName);
}

export function findTmuxWorkspaceName(
  output: string,
  sessionId: string,
): string | undefined {
  const suffix = terminalWorkspaceSuffix(sessionId);
  return output
    .split("\n")
    .map((name) => name.trim())
    .find(
      (name) =>
        (name.startsWith("π′ - ") ||
          name.startsWith("π subagents - ") ||
          name.startsWith("π - ")) &&
        name.endsWith(suffix),
    );
}

export function findTmuxWindow(
  output: string,
  sessionId: string,
): TmuxWindow | undefined {
  const suffix = terminalWorkspaceSuffix(sessionId);
  for (const line of output.split("\n")) {
    const [rawTarget, rawName, rawOwner = ""] = line.split("\t");
    const target = rawTarget?.trim();
    const name = rawName?.trim();
    const owner = rawOwner.trim();
    if (!target || !name) continue;
    if (owner === sessionId) return { target, name };
    if (owner) continue;
    if (
      (name.startsWith("π′ - ") ||
        name.startsWith("π subagents - ") ||
        name.startsWith("π - ")) &&
      name.endsWith(suffix)
    ) {
      return { target, name };
    }
  }
  return undefined;
}

export function tmuxWindowIdentityArgs(
  windowTarget: string,
  sessionId: string,
): string[] {
  return [
    "set-window-option",
    "-t",
    windowTarget,
    TMUX_SESSION_OPTION,
    sessionId,
  ];
}

export function tmuxClosePaneOnExitArgs(windowTarget: string): string[] {
  return ["set-window-option", "-t", windowTarget, "remain-on-exit", "off"];
}

export function tmuxPaneHasExited(code: number, output: string): boolean {
  return code !== 0 || output.trim() === "1";
}

export function parseTmuxWindowCreation(output: string): {
  paneTarget: string;
  windowTarget: string;
} {
  const line = output.trim().split("\n").at(-1) ?? "";
  const [paneTarget, windowTarget] = line
    .split("\t")
    .map((value) => value.trim());
  if (!paneTarget || !windowTarget) {
    throw new Error("tmux did not report the created subagent window.");
  }
  return { paneTarget, windowTarget };
}

export function tmuxPaneTitleArgs(target: string, title: string): string[] {
  return ["select-pane", "-t", target, "-T", title];
}

export async function setTmuxPaneTitle(
  exec: (
    command: string,
    args: string[],
  ) => Promise<{ code: number; stderr: string }>,
  argsPrefix: string[],
  target: string,
  title: string,
): Promise<void> {
  const result = await exec("tmux", [
    ...argsPrefix,
    ...tmuxPaneTitleArgs(target, title),
  ]);
  if (result.code !== 0)
    throw new Error(result.stderr.trim() || "Failed to title subagent pane.");
}

export function parseCmuxIdentity(output: string): CmuxIdentity {
  let payload: any;
  try {
    payload = JSON.parse(output);
  } catch {
    throw new Error("cmux identify returned invalid JSON.");
  }
  const context = payload?.caller ?? payload?.focused;
  const windowId = context?.window_id ?? context?.window_ref;
  if (typeof windowId !== "string" || !windowId) {
    throw new Error(
      "cmux did not report a caller window. Run Pi inside cmux or select tmux explicitly.",
    );
  }
  return { windowId };
}

export function parseCmuxWorkspaceTarget(output: string): string {
  let payload: any;
  try {
    payload = JSON.parse(output);
  } catch {
    const plainTarget = output.match(/(?:^|\s)(workspace:[^\s]+)/)?.[1];
    if (plainTarget) return plainTarget;
    throw new Error(
      "cmux workspace create did not report valid JSON or a workspace ref.",
    );
  }
  const result = payload?.result ?? payload;
  const workspace = result?.workspace ?? result;
  const target =
    workspace?.workspace_id ??
    workspace?.id ??
    workspace?.workspace_ref ??
    workspace?.ref;
  if (typeof target !== "string" || !target) {
    throw new Error(
      "cmux workspace create did not report the created workspace.",
    );
  }
  return target;
}

function cmuxItemTarget(
  item: any,
  kind: "workspace" | "surface",
): string | undefined {
  const target =
    item?.[`${kind}_id`] ?? item?.id ?? item?.[`${kind}_ref`] ?? item?.ref;
  return typeof target === "string" && target ? target : undefined;
}

export function findCmuxWorkspace(
  output: string,
  name: string,
): CmuxWorkspace | undefined {
  let payload: any;
  try {
    payload = JSON.parse(output);
  } catch {
    throw new Error("cmux workspace list returned invalid JSON.");
  }
  const result = payload?.result ?? payload;
  const workspaces = result?.workspaces;
  if (!Array.isArray(workspaces)) {
    throw new Error("cmux workspace list did not return workspaces.");
  }
  for (const workspace of workspaces) {
    if (workspace?.title !== name) continue;
    const target = cmuxItemTarget(workspace, "workspace");
    if (target) return { target };
  }
  return undefined;
}

export function parseCmuxSurfaceTarget(output: string): string {
  let payload: any;
  try {
    payload = JSON.parse(output);
  } catch {
    const plainTarget = output.match(/(?:^|\s)(surface:[^\s]+)/)?.[1];
    if (plainTarget) return plainTarget;
    throw new Error(
      "cmux surface command did not report valid JSON or a surface ref.",
    );
  }
  const result = payload?.result ?? payload;
  const surface = result?.surface ?? result;
  const target = cmuxItemTarget(surface, "surface");
  if (!target) {
    throw new Error("cmux surface command did not report a surface.");
  }
  return target;
}

export function parseFirstCmuxSurface(output: string): string {
  let payload: any;
  try {
    payload = JSON.parse(output);
  } catch {
    throw new Error("cmux surface list returned invalid JSON.");
  }
  const result = payload?.result ?? payload;
  const surface = Array.isArray(result?.surfaces)
    ? result.surfaces[0]
    : undefined;
  const target = cmuxItemTarget(surface, "surface");
  if (!target) {
    throw new Error("cmux surface list did not return a surface.");
  }
  return target;
}

export function isSameOrDescendant(base: string, candidate: string): boolean {
  const relative = path.relative(base, candidate);
  return (
    relative === "" ||
    (relative !== ".." &&
      !relative.startsWith(`..${path.sep}`) &&
      !path.isAbsolute(relative))
  );
}
