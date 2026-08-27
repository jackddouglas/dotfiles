import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { basename } from "node:path";
import type { ProcessAdapter, ProcessRequest } from "./runtime.ts";

const ABORT_GRACE_MS = 5_000;

export interface ProcessInvocation {
  command: string;
  prefixArgs: string[];
}

function currentPiInvocation(): ProcessInvocation {
  const script = process.argv[1];
  if (script && !script.startsWith("/$bunfs/root/") && existsSync(script)) {
    return { command: process.execPath, prefixArgs: [script] };
  }

  const executable = basename(process.execPath).toLowerCase();
  if (!/^(node|bun)(\.exe)?$/.test(executable)) {
    return { command: process.execPath, prefixArgs: [] };
  }
  return { command: "pi", prefixArgs: [] };
}

function parseLine(line: string, request: ProcessRequest): void {
  if (!line.trim()) return;
  try {
    const event = JSON.parse(line);
    if (event && typeof event === "object") {
      request.onEvent(event as Record<string, unknown>);
    }
  } catch {
    // JSON mode should emit one event per line. Ignore incidental process output.
  }
}

export function createProcessAdapter(
  invocation: ProcessInvocation = currentPiInvocation(),
): ProcessAdapter {
  return (request) =>
    new Promise((resolve) => {
      const child = spawn(
        invocation.command,
        [...invocation.prefixArgs, ...request.args],
        {
          cwd: request.cwd,
          env: request.env,
          shell: false,
          stdio: ["ignore", "pipe", "pipe"],
        },
      );
      let stdoutBuffer = "";
      let stderr = "";
      let aborted = false;
      let spawnError: string | undefined;
      let forceKillTimer: ReturnType<typeof setTimeout> | undefined;

      child.stdout.on("data", (chunk) => {
        stdoutBuffer += chunk.toString();
        const lines = stdoutBuffer.split("\n");
        stdoutBuffer = lines.pop() ?? "";
        for (const line of lines) parseLine(line, request);
      });
      child.stderr.on("data", (chunk) => {
        stderr += chunk.toString();
      });
      child.on("error", (error) => {
        spawnError = error.message;
      });

      const abort = () => {
        if (aborted) return;
        aborted = true;
        child.kill("SIGTERM");
        forceKillTimer = setTimeout(() => {
          if (child.exitCode === null && child.signalCode === null) {
            child.kill("SIGKILL");
          }
        }, ABORT_GRACE_MS);
        forceKillTimer.unref?.();
      };
      if (request.signal?.aborted) abort();
      else request.signal?.addEventListener("abort", abort, { once: true });

      child.on("close", (code) => {
        if (stdoutBuffer.trim()) parseLine(stdoutBuffer, request);
        if (forceKillTimer) clearTimeout(forceKillTimer);
        request.signal?.removeEventListener("abort", abort);
        resolve({
          exitCode: code ?? 1,
          stderr,
          aborted,
          spawnError,
        });
      });
    });
}

export const runPiProcess = createProcessAdapter();
