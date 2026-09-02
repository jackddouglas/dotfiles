import * as path from "node:path";

export type TerminalBackend = "tmux" | "cmux";
export type TerminalChoice = "auto" | TerminalBackend;

interface CmuxIdentity {
  windowId: string;
}

export interface CmuxWorkspace {
  target: string;
  initialSurface?: string;
}

export function shellQuote(value: string): string {
  if (value.length === 0) return "''";
  return `'${value.replace(/'/g, `'"'"'`)}'`;
}

export function selectTerminalBackend(
  choice: TerminalChoice,
  environment: NodeJS.ProcessEnv = process.env,
): TerminalBackend {
  if (choice !== "auto") return choice;
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

export function terminalWorkspaceName(
  sessionId: string,
  sessionTitle?: string,
): string {
  const shortId = shortSessionId(sessionId);
  const safeTitle = sessionTitle
    ?.trim()
    .replace(/[^\p{L}\p{N}]+/gu, " ")
    .replaceAll(/\s+/g, " ")
    .trim()
    .slice(0, 52)
    .trimEnd();
  return `π′ - ${safeTitle || "Session"} - ${shortId}`;
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
