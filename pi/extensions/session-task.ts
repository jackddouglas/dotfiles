import { execFile } from "node:child_process";
import { mkdir, readFile, rename, stat, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

const run = promisify(execFile);

// Compiled on demand into ~/.cache/pi/apple-intelligence and invoked to name
// sessions with on-device Apple Intelligence (macOS 26+ FoundationModels).
const APPLE_LABEL_SCRIPT = `\
import Foundation
import FoundationModels

let instructions = """
Write a concise title that captures the intent of this coding session. \\
Return only a 3-6 word title with no quotes, Markdown, or trailing punctuation.
"""

guard CommandLine.arguments.count > 1 else { exit(2) }
guard case .available = SystemLanguageModel.default.availability else {
  FileHandle.standardError.write(Data("Apple Intelligence is unavailable\\n".utf8))
  exit(3)
}

let session = LanguageModelSession(instructions: instructions)
do {
  let response = try await session.respond(to: CommandLine.arguments[1])
  print(response.content.trimmingCharacters(in: .whitespacesAndNewlines))
} catch {
  FileHandle.standardError.write(Data("error: \\(error)\\n".utf8))
  exit(1)
}
`;

function messageText(message: Record<string, unknown>): string {
  const content = message.content;
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  return content
    .filter((part): part is { type: "text"; text: string } =>
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
  const boilerplate =
    /^(you are|do not|already isolated|work directly|execute this workflow)/i;
  const candidate =
    clauses.find((clause) => !boilerplate.test(clause) && clause.length >= 8) ??
    clauses[0];
  if (!candidate) return undefined;
  const cleaned = candidate
    .replace(/^(task:\s*|your task is to\s+|please\s+)/i, "")
    .replaceAll(/[`*_#]/g, "")
    .trim();
  if (!cleaned) return undefined;
  return cleaned.length > 52 ? `${cleaned.slice(0, 49).trimEnd()}…` : cleaned;
}

function excerpt(text: string, limit = 6_000): string {
  if (text.length <= limit) return text;
  const half = Math.floor((limit - 5) / 2);
  return `${text.slice(0, half)}\n…\n${text.slice(-half)}`;
}

function responseTitle(text: string): string | undefined {
  const line = text
    .replaceAll("```", "")
    .split("\n")
    .map((candidate) => candidate.trim())
    .find(Boolean);
  if (!line) return undefined;
  const cleaned = line
    .replace(/^title:\s*/i, "")
    .replace(/^["'`]+|["'`]+$/g, "")
    .replaceAll(/[*_#]/g, "")
    .replace(/[.!?;:]+$/, "")
    .replaceAll(/\s+/g, " ")
    .trim();
  if (!cleaned) return undefined;
  return cleaned.length > 52 ? `${cleaned.slice(0, 49).trimEnd()}…` : cleaned;
}

async function ensureAppleHelper(): Promise<string | undefined> {
  if (process.platform !== "darwin") return undefined;
  if (process.env.PI_APPLE_INTELLIGENCE === "off") return undefined;

  const cacheDir = join(homedir(), ".cache", "pi", "apple-intelligence");
  const sourcePath = join(cacheDir, "ask.swift");
  const binaryPath = join(cacheDir, "ask");
  try {
    await mkdir(cacheDir, { recursive: true });
    const current = await readFile(sourcePath, "utf8").catch(() => undefined);
    if (current !== APPLE_LABEL_SCRIPT)
      await writeFile(sourcePath, APPLE_LABEL_SCRIPT);

    const [source, binary] = await Promise.all([
      stat(sourcePath),
      stat(binaryPath).catch(() => null),
    ]);
    if (!binary || binary.mtimeMs < source.mtimeMs) {
      // Compile out of the way and rename so concurrent sessions never see a
      // partially written binary.
      const staged = join(cacheDir, `.ask.${process.pid}`);
      await run(
        "/usr/bin/swiftc",
        ["-O", "-o", staged, sourcePath],
        { timeout: 120_000 },
      );
      await rename(staged, binaryPath);
    }
    return binaryPath;
  } catch {
    return undefined;
  }
}

async function appleIntelligenceLabel(
  prompt: string,
): Promise<string | undefined> {
  try {
    const binary = await ensureAppleHelper();
    if (!binary) return undefined;
    const { stdout } = await run(binary, [excerpt(prompt, 2_000)], {
      timeout: 10_000,
    });
    return responseTitle(stdout.trim());
  } catch {
    // Fall through to the hosted model.
    return undefined;
  }
}

async function generateTaskLabel(
  prompt: string,
  ctx: ExtensionContext,
): Promise<string | undefined> {
  const appleLabel = await appleIntelligenceLabel(prompt);
  if (appleLabel) return appleLabel;

  let label: string | undefined;
  try {
    const model = ctx.modelRegistry.find("openai-codex", "gpt-5.6-luna");
    const provider = ctx.modelRegistry.getProvider("openai-codex");
    const auth = await ctx.modelRegistry.getProviderAuth("openai-codex");
    if (!model || !provider || !auth)
      throw new Error("OpenAI Codex OAuth is unavailable");

    const result = await provider
      .streamSimple(
        model,
        {
          systemPrompt:
            "Write a concise title that captures the intent of this coding session. Return only a 3-6 word title with no quotes, Markdown, or trailing punctuation.",
          messages: [
            {
              role: "user",
              content: `Initial request:\n${excerpt(prompt)}`,
              timestamp: Date.now(),
            },
          ],
        },
        {
          apiKey: auth.auth.apiKey,
          headers: auth.auth.headers,
          env: auth.env,
          reasoning: "minimal",
          maxTokens: 64,
          timeoutMs: 5_000,
          maxRetries: 0,
          sessionId: ctx.sessionManager.getSessionId(),
        },
      )
      .result();
    label = responseTitle(messageText(result as unknown as Record<string, unknown>));
  } catch {
    // A naming failure should not fail the user's session.
  }

  return label ?? shortTaskLabel(prompt);
}

export default function (pi: ExtensionAPI) {
  const isSubagent = process.env.PI_SESSION_ROLE === "subagent";
  let attempted = false;

  pi.on("session_start", (_event, ctx) => {
    attempted = Boolean(pi.getSessionName());
    if (isSubagent) {
      ctx.ui.setStatus("session-role", ctx.ui.theme.fg("muted", "↳ subagent"));
    }
  });

  pi.on("agent_start", (_event, ctx) => {
    if (!isSubagent) return;
    ctx.ui.setTitle(`↳ ${pi.getSessionName() ?? "subagent"}`);
  });

  pi.on("before_agent_start", (event, ctx) => {
    if (attempted || pi.getSessionName() || !event.prompt.trim()) return;
    attempted = true;

    void generateTaskLabel(event.prompt, ctx)
      .then((label) => {
        if (label && !pi.getSessionName()) pi.setSessionName(label);
      })
      .catch(() => {
        // The session may have been replaced while naming was in flight.
      });
  });
}
