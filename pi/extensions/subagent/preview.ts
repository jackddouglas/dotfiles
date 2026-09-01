export interface PreviewMetadata {
  startedAt?: number;
  finishedAt?: number;
  now?: number;
  provider: string;
  model: string;
  thinking: string;
  messageCount: number;
  terminal: string;
}

export interface PreviewDetails extends PreviewMetadata {
  status: string;
  task: string;
}

interface ToolResultContent {
  type?: unknown;
  text?: unknown;
}

export function previewTask(task: string, maxLength = 100): string {
  const normalized = task.trim() || "...";
  const firstLine = normalized.split("\n", 1)[0]?.trim() || normalized;
  return firstLine.length > maxLength
    ? `${firstLine.slice(0, maxLength)}…`
    : firstLine;
}

export function formatElapsed(
  startedAt: number | undefined,
  finishedAt: number | undefined,
  now = Date.now(),
): string | undefined {
  if (startedAt === undefined) return undefined;
  const end = finishedAt ?? now;
  const seconds = Math.max(0, Math.floor((end - startedAt) / 1000));
  if (seconds < 60) return `${seconds}s`;
  const minutes = Math.floor(seconds / 60);
  return `${minutes}m ${seconds % 60}s`;
}

export function formatMessageCount(messageCount: number): string {
  return `${messageCount} ${messageCount === 1 ? "msg" : "msgs"}`;
}

export function hasPreviewDetails(value: unknown): value is PreviewDetails {
  if (!value || typeof value !== "object") return false;
  const details = value as Record<string, unknown>;
  return (
    typeof details.status === "string" &&
    typeof details.task === "string" &&
    typeof details.provider === "string" &&
    typeof details.model === "string" &&
    typeof details.thinking === "string" &&
    typeof details.terminal === "string" &&
    Number.isInteger(details.messageCount) &&
    Number(details.messageCount) >= 0
  );
}

export function isCancelledToolResult(
  isError: boolean,
  content: ToolResultContent[],
): boolean {
  if (!isError) return false;
  return content.some(
    (part) =>
      part.type === "text" &&
      typeof part.text === "string" &&
      /\b(?:abort(?:ed)?|cancelled|canceled)\b/i.test(part.text),
  );
}

export function formatPreviewMetadata(metadata: PreviewMetadata): string {
  return [
    formatElapsed(metadata.startedAt, metadata.finishedAt, metadata.now),
    `${metadata.provider}/${metadata.model} (${metadata.thinking})`,
    formatMessageCount(metadata.messageCount),
    metadata.terminal,
  ]
    .filter(Boolean)
    .join(" · ");
}
