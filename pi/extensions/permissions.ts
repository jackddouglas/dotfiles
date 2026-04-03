import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  // ── Commands that need confirmation ──
  const dangerousPatterns = [
    // destructive filesystem
    /\brm\b/,
    /\bsudo\b/,
    /\bmkfs\b/,
    /\bdd\b.*\bof=/,
    />\s*\/dev\/(?!null)/,

    // remote interaction
    /\bgit\s+push\b/,
    /\bgit\s+fetch\b/,
    /\bgit\s+pull\b/,
    /\bgit\s+remote\s+add\b/,
    /\bgit\s+remote\s+set-url\b/,
    /\bjj\s+git\s+push\b/,
    /\bjj\s+git\s+fetch\b/,
    /\bcurl\b.*\|\s*(bash|sh)\b/,
    /\bwget\b.*\|\s*(bash|sh)\b/,

    // hard resets / data loss
    /\bgit\s+reset\s+--hard\b/,
    /\bgit\s+clean\s+-[^\s]*f/,
    /\bjj\s+abandon\b/,
  ];

  // ── Protected paths that need confirmation for writes ──
  const protectedPaths = [
    /\.env($|\.)/,
    /\/\.ssh\//,
    /\/\.gnupg\//,
    /\/\.aws\//,
  ];

  function isDangerous(command: string): boolean {
    return dangerousPatterns.some((p) => p.test(command));
  }

  function isProtectedPath(path: string): boolean {
    return protectedPaths.some((p) => p.test(path));
  }

  pi.on("tool_call", async (event, ctx) => {
    if (!ctx.hasUI) {
      // Non-interactive: block dangerous bash and protected file writes
      if (event.toolName === "bash") {
        const cmd = (event.input as { command: string }).command;
        if (isDangerous(cmd)) {
          return { block: true, reason: "Dangerous command blocked (no UI)" };
        }
      }
      if (event.toolName === "write" || event.toolName === "edit") {
        const path = (event.input as { path: string }).path;
        if (isProtectedPath(path)) {
          return { block: true, reason: "Protected path blocked (no UI)" };
        }
      }
      return undefined;
    }

    // ── Protected file paths ──
    if (isToolCallEventType("write", event) && isProtectedPath(event.input.path)) {
      const ok = await ctx.ui.confirm("Write to protected path", event.input.path);
      if (!ok) return { block: true, reason: "Blocked by user" };
    }

    if (isToolCallEventType("edit", event) && isProtectedPath(event.input.path)) {
      const ok = await ctx.ui.confirm("Edit protected path", event.input.path);
      if (!ok) return { block: true, reason: "Blocked by user" };
    }

    // ── Dangerous bash commands ──
    if (isToolCallEventType("bash", event) && isDangerous(event.input.command)) {
      const ok = await ctx.ui.confirm("Confirm command", event.input.command);
      if (!ok) return { block: true, reason: "Blocked by user" };
    }

    return undefined;
  });
}
