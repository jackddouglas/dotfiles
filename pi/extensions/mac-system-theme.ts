import { execFile } from "node:child_process";
import { promisify } from "node:util";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const execFileAsync = promisify(execFile);
const POLL_INTERVAL_MS = 2000;
const DETECTION_TIMEOUT_MS = 5000;

type SystemTheme = "dark" | "light";

async function detectSystemTheme(): Promise<SystemTheme | undefined> {
  try {
    const { stdout } = await execFileAsync(
      "/usr/bin/osascript",
      [
        "-e",
        'tell application "System Events" to tell appearance preferences to return dark mode',
      ],
      { timeout: DETECTION_TIMEOUT_MS },
    );
    return stdout.trim() === "true" ? "dark" : "light";
  } catch {
    return undefined;
  }
}

export default function (pi: ExtensionAPI) {
  let currentTheme: SystemTheme | undefined;
  let intervalId: ReturnType<typeof setInterval> | undefined;
  let detectionInFlight = false;
  let detectionFailureReported = false;

  async function syncTheme(ctx: ExtensionContext): Promise<void> {
    if (detectionInFlight) return;

    detectionInFlight = true;
    try {
      const nextTheme = await detectSystemTheme();
      if (!nextTheme) {
        if (!detectionFailureReported) {
          ctx.ui.notify("Could not detect the macOS system appearance", "warning");
          detectionFailureReported = true;
        }
        return;
      }

      detectionFailureReported = false;
      if (nextTheme !== currentTheme) {
        currentTheme = nextTheme;
        ctx.ui.setTheme(nextTheme);
      }
    } finally {
      detectionInFlight = false;
    }
  }

  pi.on("session_start", async (_event, ctx) => {
    if (process.platform !== "darwin" || ctx.mode !== "tui") return;

    await syncTheme(ctx);
    intervalId = setInterval(() => void syncTheme(ctx), POLL_INTERVAL_MS);
  });

  pi.on("session_shutdown", () => {
    if (intervalId) clearInterval(intervalId);
    intervalId = undefined;
    currentTheme = undefined;
    detectionFailureReported = false;
  });
}
