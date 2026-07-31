import { spawn } from "node:child_process";
import type {
  AgentEndEvent,
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

function spawnDetached(command: string, args: string[]): void {
  const child = spawn(command, args, { stdio: "ignore" });
  child.on("error", () => {});
  child.unref();
}

function setTmuxAlert(marker: string, ringBell = false): void {
  const pane = process.env.TMUX_PANE;
  if (!pane) return;

  spawnDetached("tmux", [
    "set-option",
    "-w",
    "-t",
    pane,
    "@agent_alert",
    marker,
  ]);

  if (ringBell) {
    spawnDetached("/bin/sh", [
      "-c",
      "tty=$(tmux display-message -p -t \"$1\" '#{pane_tty}') && printf '\\a' >\"$tty\"",
      "tmux-notifications",
      pane,
    ]);
  }
}

function lastAssistantStopReason(event: AgentEndEvent): string | undefined {
  for (let i = event.messages.length - 1; i >= 0; i--) {
    const message = event.messages[i];
    if (message.role === "assistant") return message.stopReason;
  }
  return undefined;
}

function alertOnAgentDialogs(ctx: ExtensionContext): () => void {
  const alert = () => {
    if (!ctx.isIdle()) setTmuxAlert("?", true);
  };
  const select = ctx.ui.select.bind(ctx.ui);
  const confirm = ctx.ui.confirm.bind(ctx.ui);
  const input = ctx.ui.input.bind(ctx.ui);
  const editor = ctx.ui.editor.bind(ctx.ui);
  const custom = ctx.ui.custom.bind(ctx.ui);

  ctx.ui.select = (...args) => {
    alert();
    return select(...args);
  };
  ctx.ui.confirm = (...args) => {
    alert();
    return confirm(...args);
  };
  ctx.ui.input = (...args) => {
    alert();
    return input(...args);
  };
  ctx.ui.editor = (...args) => {
    alert();
    return editor(...args);
  };
  ctx.ui.custom = (...args) => {
    alert();
    return custom(...args);
  };

  return () => {
    ctx.ui.select = select;
    ctx.ui.confirm = confirm;
    ctx.ui.input = input;
    ctx.ui.editor = editor;
    ctx.ui.custom = custom;
  };
}

export default function (pi: ExtensionAPI) {
  let restoreDialogs: (() => void) | undefined;
  let stopReason: string | undefined;

  pi.on("session_start", async (_event, ctx) => {
    restoreDialogs?.();
    restoreDialogs = ctx.hasUI ? alertOnAgentDialogs(ctx) : undefined;
  });

  pi.on("session_shutdown", async () => {
    restoreDialogs?.();
    restoreDialogs = undefined;
  });

  pi.on("input", async () => {
    setTmuxAlert("");
  });

  pi.on("agent_start", async () => {
    stopReason = undefined;
    setTmuxAlert("");
  });

  pi.on("agent_end", async (event) => {
    stopReason = lastAssistantStopReason(event);
  });

  pi.on("agent_settled", async (_event, ctx) => {
    if (!ctx.isIdle()) return;
    if (stopReason === "aborted") {
      setTmuxAlert("");
      return;
    }
    setTmuxAlert(stopReason === "error" ? "!" : "✓", true);
  });
}
