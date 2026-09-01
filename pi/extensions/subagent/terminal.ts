import * as path from "node:path";

export type TerminalBackend = "tmux" | "cmux";
export type TerminalChoice = "auto" | TerminalBackend;

interface CmuxIdentity {
  windowId: string;
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

export function isSameOrDescendant(base: string, candidate: string): boolean {
  const relative = path.relative(base, candidate);
  return (
    relative === "" ||
    (relative !== ".." &&
      !relative.startsWith(`..${path.sep}`) &&
      !path.isAbsolute(relative))
  );
}
