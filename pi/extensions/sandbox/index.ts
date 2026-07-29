import { spawn } from "node:child_process";
import {
  existsSync,
  mkdtempSync,
  realpathSync,
  rmSync,
} from "node:fs";
import { homedir } from "node:os";
import { isAbsolute, relative, sep } from "node:path";
import { SandboxManager } from "@anthropic-ai/sandbox-runtime";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
  type BashOperations,
  createBashTool,
} from "@earendil-works/pi-coding-agent";

function containsPath(parent: string, child: string): boolean {
  const pathFromParent = relative(parent, child);
  return (
    pathFromParent === "" ||
    (!isAbsolute(pathFromParent) &&
      pathFromParent !== ".." &&
      !pathFromParent.startsWith(`..${sep}`))
  );
}

const EXIT_STDIO_GRACE_MS = 100;
const MAX_POST_EXIT_DRAIN_MS = 1000;
const MAX_TIMEOUT_SECONDS = 2_147_483_647 / 1000;
const BROWSER_CLEANUP_HORIZON_MS = 11_000;
const BROWSER_CLEANUP_RETRY_MS = 250;
const BROWSER_SESSION_ID = "pi-browser";
const CHROME_DEVTOOLS_BIN = "@chromeDevtoolsBin@";
const SAFE_BROWSER_START_ARGS = [
  "start",
  "--isolated",
  "--headless",
  "--performanceCrux=false",
  "--blockedUrlPattern=file:*",
  "--chromeArg=--disable-crash-reporter",
];
const EXPECTED_BROWSER_DAEMON_ARGS = [
  "--headless",
  "--isolated",
  "--category-emulation",
  "--category-performance",
  "--category-network",
  "--category-extensions",
  "--no-category-experimental-third-party",
  "--no-performance-crux",
  "--usage-statistics",
  "--no-redact-network-headers",
  "--no-allow-unrestricted-paths",
  "--blocked-url-pattern",
  "file:*",
  "--chrome-arg",
  "--disable-crash-reporter",
  "--viaCli",
  "--experimentalStructuredContent",
].sort();

function waitForChildProcess(
  child: ReturnType<typeof spawn>,
): Promise<number | null> {
  return new Promise((resolvePromise, reject) => {
    let settled = false;
    let exited = false;
    let exitCode: number | null = null;
    let postExitTimer: ReturnType<typeof setTimeout> | undefined;
    let postExitDeadline: ReturnType<typeof setTimeout> | undefined;

    const cleanup = () => {
      if (postExitTimer) clearTimeout(postExitTimer);
      if (postExitDeadline) clearTimeout(postExitDeadline);
      child.removeListener("error", onError);
      child.removeListener("exit", onExit);
      child.removeListener("close", onClose);
      child.stdout?.removeListener("data", onData);
      child.stderr?.removeListener("data", onData);
    };
    const finish = (code: number | null) => {
      if (settled) return;
      settled = true;
      cleanup();
      child.stdout?.destroy();
      child.stderr?.destroy();
      resolvePromise(code);
    };
    const armIdleTimer = () => {
      if (postExitTimer) clearTimeout(postExitTimer);
      postExitTimer = setTimeout(() => finish(exitCode), EXIT_STDIO_GRACE_MS);
    };
    const onData = () => {
      if (exited && !settled) armIdleTimer();
    };
    const onError = (error: Error) => {
      if (settled) return;
      settled = true;
      cleanup();
      reject(error);
    };
    const onExit = (code: number | null) => {
      exited = true;
      exitCode = code;
      armIdleTimer();
      postExitDeadline = setTimeout(
        () => finish(exitCode),
        MAX_POST_EXIT_DRAIN_MS,
      );
    };
    const onClose = (code: number | null) => finish(code);

    child.stdout?.on("data", onData);
    child.stderr?.on("data", onData);
    child.once("error", onError);
    child.once("exit", onExit);
    child.once("close", onClose);
  });
}

function createSandboxedBashOperations(
  shell: string,
  browserRuntime: string,
  prepareBrowser: () => Promise<void>,
  markBrowserUse: () => void,
  getFailure: () => string | undefined,
): BashOperations {
  return {
    async exec(command, cwd, { onData, signal, timeout, env }) {
      const failure = getFailure();
      if (failure) throw new Error(`Shell sandbox unavailable: ${failure}`);
      if (!existsSync(cwd)) {
        throw new Error(`Working directory does not exist: ${cwd}`);
      }
      if (signal?.aborted) throw new Error("aborted");
      if (
        timeout !== undefined &&
        (!Number.isFinite(timeout) || timeout <= 0 || timeout > MAX_TIMEOUT_SECONDS)
      ) {
        throw new Error(
          `Invalid timeout: must be between 0 and ${MAX_TIMEOUT_SECONDS} seconds`,
        );
      }

      if (command.includes("chrome-devtools")) {
        markBrowserUse();
        await prepareBrowser();
        if (signal?.aborted) throw new Error("aborted");
      }
      const wrappedCommand = await SandboxManager.wrapWithSandbox(
        command,
        shell,
        undefined,
        signal,
      );
      const child = spawn(shell, ["-c", wrappedCommand], {
        cwd,
        detached: true,
        env: {
          ...process.env,
          ...env,
          PI_BROWSER_RUNTIME_DIR: browserRuntime,
          PI_BROWSER_SESSION_ID: BROWSER_SESSION_ID,
        },
        stdio: ["ignore", "pipe", "pipe"],
      });
      let timedOut = false;
      let timeoutHandle: ReturnType<typeof setTimeout> | undefined;

      const killChild = () => {
        if (!child.pid) return;
        try {
          process.kill(-child.pid, "SIGKILL");
        } catch {
          child.kill("SIGKILL");
        }
      };
      const onAbort = () => killChild();

      try {
        if (timeout !== undefined) {
          timeoutHandle = setTimeout(() => {
            timedOut = true;
            killChild();
          }, timeout * 1000);
        }

        child.stdout?.on("data", onData);
        child.stderr?.on("data", onData);
        if (signal?.aborted) onAbort();
        else signal?.addEventListener("abort", onAbort, { once: true });

        const exitCode = await waitForChildProcess(child);
        killChild();
        if (signal?.aborted) throw new Error("aborted");
        if (timedOut) throw new Error(`timeout:${timeout}`);
        return { exitCode };
      } finally {
        if (timeoutHandle) clearTimeout(timeoutHandle);
        signal?.removeEventListener("abort", onAbort);
      }
    },
  };
}

function runBrowserCli(
  browserRuntime: string,
  args: string[],
): Promise<{ code: number | null; output: string }> {
  return new Promise((resolve) => {
    const child = spawn(
      CHROME_DEVTOOLS_BIN,
      [...args, "--sessionId", BROWSER_SESSION_ID],
      {
        env: {
          ...process.env,
          XDG_RUNTIME_DIR: browserRuntime,
          TMPDIR: browserRuntime,
        },
        stdio: ["ignore", "pipe", "pipe"],
      },
    );
    let output = "";
    let settled = false;
    const append = (chunk: Buffer) => {
      if (output.length < 50 * 1024) output += chunk.toString();
    };
    const finish = (code: number | null) => {
      if (settled) return;
      settled = true;
      clearTimeout(timeout);
      resolve({ code, output: output.trim() });
    };
    const timeout = setTimeout(() => {
      child.kill("SIGKILL");
      finish(null);
    }, 15_000);
    child.stdout.on("data", append);
    child.stderr.on("data", append);
    child.once("error", () => finish(null));
    child.once("close", finish);
  });
}

function hasSafeBrowserDaemonArgs(output: string): boolean {
  const argsLine = output.split("\n").find((line) => line.startsWith("args="));
  if (!argsLine) return false;
  try {
    const args = JSON.parse(argsLine.slice("args=".length)) as unknown;
    if (!Array.isArray(args) || !args.every((arg) => typeof arg === "string")) {
      return false;
    }
    const sorted = [...args].sort();
    return (
      sorted.length === EXPECTED_BROWSER_DAEMON_ARGS.length &&
      sorted.every((arg, index) => arg === EXPECTED_BROWSER_DAEMON_ARGS[index])
    );
  } catch {
    return false;
  }
}

async function stopBrowserSession(browserRuntime: string): Promise<void> {
  await runBrowserCli(browserRuntime, ["stop"]);
}

async function ensureBrowserSession(browserRuntime: string): Promise<void> {
  const status = await runBrowserCli(browserRuntime, ["status"]);
  if (status.code === 0 && hasSafeBrowserDaemonArgs(status.output)) return;

  await stopBrowserSession(browserRuntime);
  const started = await runBrowserCli(browserRuntime, SAFE_BROWSER_START_ARGS);
  if (started.code !== 0) {
    throw new Error(started.output || "Could not start Chrome DevTools CLI daemon");
  }
  const verified = await runBrowserCli(browserRuntime, ["status"]);
  if (verified.code !== 0 || !hasSafeBrowserDaemonArgs(verified.output)) {
    await stopBrowserSession(browserRuntime);
    throw new Error("Chrome DevTools CLI daemon did not retain its safe settings");
  }
}

async function cleanupBrowserSession(
  browserRuntime: string,
  lastBrowserUse: number | undefined,
): Promise<void> {
  if (lastBrowserUse === undefined) return;
  const deadline = lastBrowserUse + BROWSER_CLEANUP_HORIZON_MS;
  do {
    await stopBrowserSession(browserRuntime);
    const remaining = deadline - Date.now();
    if (remaining > 0) {
      await new Promise((resolve) =>
        setTimeout(resolve, Math.min(BROWSER_CLEANUP_RETRY_MS, remaining)),
      );
    }
  } while (Date.now() < deadline);
  await stopBrowserSession(browserRuntime);
}

export default function (pi: ExtensionAPI) {
  const workspace = realpathSync(process.cwd());
  const home = realpathSync(homedir());
  const temp = realpathSync("/tmp");
  const shell = realpathSync("/bin/bash");
  const browserRuntime = realpathSync(
    mkdtempSync(`${temp}/pi-chrome-devtools-`),
  );
  const localBash = createBashTool(workspace);
  let sandboxFailure: string | undefined = "not initialized";
  let lastBrowserUse: number | undefined;
  let browserPreparation: Promise<void> = Promise.resolve();

  const prepareBrowser = () => {
    const next = browserPreparation.then(() => ensureBrowserSession(browserRuntime));
    browserPreparation = next.catch(() => undefined);
    return next;
  };
  const sandboxedOperations = createSandboxedBashOperations(
    shell,
    browserRuntime,
    prepareBrowser,
    () => {
      lastBrowserUse = Date.now();
    },
    () => sandboxFailure,
  );

  pi.registerTool({
    ...localBash,
    label: "bash (workspace sandbox)",
    async execute(id, params, signal, onUpdate) {
      const sandboxedBash = createBashTool(workspace, {
        operations: sandboxedOperations,
      });
      return sandboxedBash.execute(id, params, signal, onUpdate);
    },
  });

  pi.on("user_bash", () => ({ operations: sandboxedOperations }));

  pi.on("session_start", async (_event, ctx) => {
    sandboxFailure = "initialization failed";

    if (process.platform !== "darwin") {
      sandboxFailure = `unsupported platform: ${process.platform}`;
      ctx.ui.notify(`Shell sandbox unavailable: ${sandboxFailure}`, "error");
      return;
    }

    if (containsPath(workspace, home)) {
      sandboxFailure = `workspace ${workspace} contains the home directory`;
      ctx.ui.notify(`Shell sandbox refused to start: ${sandboxFailure}`, "error");
      return;
    }

    try {
      await SandboxManager.initialize(
        {
          enableWeakerNetworkIsolation: true,
          network: {
            allowedDomains: [],
            deniedDomains: [],
            allowLocalBinding: true,
            allowUnixSockets: [browserRuntime],
          },
          filesystem: {
            denyRead: [],
            allowWrite: [workspace, temp],
            denyWrite: [
              `${home}/.npm/_logs`,
              `${home}/.claude/debug`,
            ],
          },
        },
        async () => true,
      );
      sandboxFailure = undefined;
      ctx.ui.setStatus("sandbox", undefined);
    } catch (error) {
      sandboxFailure = error instanceof Error ? error.message : String(error);
      ctx.ui.notify(`Shell sandbox initialization failed: ${sandboxFailure}`, "error");
    }
  });

  pi.on("session_shutdown", async () => {
    sandboxFailure = "session shutting down";
    await browserPreparation;
    await cleanupBrowserSession(browserRuntime, lastBrowserUse);
    try {
      await SandboxManager.reset();
    } catch {
      // The sandbox remains fail-closed because shell execution is already disabled.
    }
    rmSync(browserRuntime, { recursive: true, force: true });
  });

  pi.registerCommand("sandbox", {
    description: "Show the shell sandbox boundary",
    handler: async (_args, ctx) => {
      const status = sandboxFailure
        ? `Shell sandbox unavailable: ${sandboxFailure}`
        : `Ordinary file writes are limited to ${workspace} and ${temp}. Reads are unrestricted; outbound domains are allowed through the sandbox proxy. Unix sockets are limited to the private Chrome CLI runtime.`;
      ctx.ui.notify(status, sandboxFailure ? "error" : "info");
    },
  });
}
