import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

function messageText(message: Record<string, unknown>): string {
  const content = message.content;
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  return content
    .filter(
      (part): part is { type: "text"; text: string } =>
        Boolean(
          part &&
          typeof part === "object" &&
          part.type === "text" &&
          typeof part.text === "string",
        ),
    )
    .map((part) => part.text)
    .join(" ");
}

function shortTaskLabel(prompt: string): string | undefined {
  const normalized = prompt.replaceAll(/\s+/g, " ").trim();
  if (!normalized) return undefined;
  const clauses = normalized.split(/(?<=[.!?])\s+|;\s+/);
  const boilerplate = /^(you are|do not|already isolated|work directly|execute this workflow)/i;
  const candidate = clauses.find((clause) => !boilerplate.test(clause) && clause.length >= 8)
    ?? clauses[0];
  if (!candidate) return undefined;
  const cleaned = candidate
    .replace(/^(task:\s*|your task is to\s+|please\s+)/i, "")
    .replaceAll(/[`*_#]/g, "")
    .trim();
  if (!cleaned) return undefined;
  return cleaned.length > 52 ? `${cleaned.slice(0, 49).trimEnd()}…` : cleaned;
}

function initialUserPrompt(ctx: ExtensionContext): string | undefined {
  for (const entry of ctx.sessionManager.getBranch()) {
    if (entry.type !== "message") continue;
    const message = entry.message as unknown as Record<string, unknown>;
    if (message.role !== "user") continue;
    const text = messageText(message);
    if (text) return text;
  }
  return undefined;
}

export default function (pi: ExtensionAPI) {
  const nameFrom = (prompt: string | undefined) => {
    if (pi.getSessionName() || !prompt) return;
    const label = shortTaskLabel(prompt);
    if (label) pi.setSessionName(label);
  };

  pi.on("session_start", (_event, ctx) => {
    nameFrom(initialUserPrompt(ctx));
  });

  pi.on("before_agent_start", (event) => {
    nameFrom(event.prompt);
  });
}
