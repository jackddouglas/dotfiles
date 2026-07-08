import { spawn } from "node:child_process";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

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

export default function (pi: ExtensionAPI) {
  pi.on("agent_end", async () => {
    setTmuxAlert("✓");
  });
}
