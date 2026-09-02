import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

const FAST_MODE_ENTRY = "codex-fast-mode";
const FAST_MODE_STATUS = "codex-fast-mode";
const CODEX_PROVIDER = "openai-codex";

type FastModeAction = "toggle" | "on" | "off" | "status";

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function parseFastModeAction(args: string): FastModeAction | undefined {
  const action = args.trim().toLowerCase();
  if (!action) return "toggle";
  if (action === "on" || action === "off" || action === "status") {
    return action;
  }
  return undefined;
}

export function restoreFastMode(entries: readonly unknown[]): boolean {
  let enabled = false;

  for (const entry of entries) {
    if (
      !isRecord(entry) ||
      entry.type !== "custom" ||
      entry.customType !== FAST_MODE_ENTRY ||
      !isRecord(entry.data) ||
      typeof entry.data.enabled !== "boolean"
    ) {
      continue;
    }
    enabled = entry.data.enabled;
  }

  return enabled;
}

export function enableFastMode(payload: unknown): unknown | undefined {
  if (!isRecord(payload)) return undefined;

  // Pi 0.84's bundled OpenAI SDK predates the `fast` spelling, but OpenAI
  // documents `priority` as the exact same service tier.
  return { ...payload, service_tier: "priority" };
}

function updateStatus(ctx: ExtensionContext, enabled: boolean): void {
  const active = enabled && ctx.model?.provider === CODEX_PROVIDER;
  ctx.ui.setStatus(FAST_MODE_STATUS, active ? "fast" : undefined);
}

export default function (pi: ExtensionAPI) {
  let enabled = false;

  pi.on("session_start", (_event, ctx) => {
    enabled = restoreFastMode(ctx.sessionManager.getBranch());
    updateStatus(ctx, enabled);
  });

  pi.on("model_select", (_event, ctx) => {
    updateStatus(ctx, enabled);
  });

  pi.on("before_provider_request", (event, ctx) => {
    if (!enabled || ctx.model?.provider !== CODEX_PROVIDER) return undefined;
    return enableFastMode(event.payload);
  });

  pi.registerCommand("fast", {
    description: "Toggle OpenAI Codex Fast mode",
    handler: async (args, ctx) => {
      const action = parseFastModeAction(args);
      if (!action) {
        ctx.ui.notify("Usage: /fast [on|off|status]", "error");
        return;
      }

      if (action === "status") {
        ctx.ui.notify(`Codex Fast mode is ${enabled ? "on" : "off"}.`, "info");
        return;
      }

      enabled = action === "toggle" ? !enabled : action === "on";
      pi.appendEntry(FAST_MODE_ENTRY, { enabled });
      updateStatus(ctx, enabled);

      const suffix =
        enabled && ctx.model?.provider !== CODEX_PROVIDER
          ? " It will apply when an OpenAI Codex model is active."
          : "";
      ctx.ui.notify(
        `Codex Fast mode ${enabled ? "enabled" : "disabled"}.${suffix}`,
        "info",
      );
    },
  });
}
