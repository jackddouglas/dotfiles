import { spawn } from "node:child_process";
import type { Plugin } from "@opencode-ai/plugin";

function setTmuxAlert(marker: string): void {
  const pane = process.env.TMUX_PANE;
  if (!pane) return;

  const tmux = spawn(
    "tmux",
    ["set-option", "-w", "-t", pane, "@agent_alert", marker],
    { stdio: "ignore" },
  );
  tmux.on("error", () => {});
  tmux.unref();
}

export const TmuxNotifications: Plugin = async () => ({
  event: async ({ event }) => {
    if (event.type === "permission.asked") setTmuxAlert("?");
    if (event.type === "session.idle") setTmuxAlert("✓");
  },
});
