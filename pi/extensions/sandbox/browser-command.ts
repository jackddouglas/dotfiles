export type CommandEnvironment = Record<string, string | undefined>;

export const BROWSER_SESSION_ID = "agent-browser";

export function isBrowserCommand(command: string): boolean {
  return command.includes("chrome-devtools");
}

export function createSandboxedCommandEnvironment(
  command: string,
  browserRuntime: string,
  processEnvironment: CommandEnvironment,
  commandEnvironment: CommandEnvironment | undefined,
): CommandEnvironment {
  return {
    ...processEnvironment,
    ...commandEnvironment,
    ...(isBrowserCommand(command)
      ? {
          XDG_RUNTIME_DIR: browserRuntime,
          TMPDIR: browserRuntime,
        }
      : {}),
  };
}
