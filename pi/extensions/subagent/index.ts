import { StringEnum } from "@earendil-works/pi-ai";
import {
  CONFIG_DIR_NAME,
  type ExtensionAPI,
  getAgentDir,
  getMarkdownTheme,
  parseFrontmatter,
} from "@earendil-works/pi-coding-agent";
import { Container, Markdown, Spacer, Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import { discoverAgents } from "./agents.ts";
import { runPiProcess } from "./process.ts";
import {
  dispatchSubagents,
  type DispatchParams,
  normalizeDispatchParams,
  type SubagentDetails,
  type SubagentResult,
} from "./runtime.ts";

const TaskItem = Type.Object({
  agent: Type.Optional(
    Type.String({
      description: 'Agent profile name. Defaults to "worker".',
      minLength: 1,
    }),
  ),
  task: Type.String({ description: "Self-contained task to delegate", minLength: 1 }),
  cwd: Type.Optional(
    Type.String({ description: "Working directory for the child Pi process" }),
  ),
});

const SubagentParameters = Type.Object({
  agent: Type.Optional(
    Type.String({
      description: 'Agent profile for single mode. Defaults to "worker".',
      minLength: 1,
    }),
  ),
  task: Type.Optional(
    Type.String({ description: "Task for single mode", minLength: 1 }),
  ),
  cwd: Type.Optional(
    Type.String({ description: "Working directory for single mode" }),
  ),
  tasks: Type.Optional(
    Type.Array(TaskItem, {
      description: "Independent tasks to run in parallel",
      minItems: 1,
      maxItems: 8,
    }),
  ),
  chain: Type.Optional(
    Type.Array(TaskItem, {
      description:
        "Sequential tasks; {previous} in a task is replaced with the prior result",
      minItems: 1,
      maxItems: 8,
    }),
  ),
  agentScope: Type.Optional(
    StringEnum(["user", "project", "both"] as const, {
      description:
        'Agent profile scope. Defaults to "user"; project profiles require explicit selection.',
      default: "user",
    }),
  ),
});

function requestedAgentNames(params: DispatchParams): string[] {
  const names = new Set<string>();
  if (params.agent) names.add(params.agent);
  for (const task of params.tasks ?? []) names.add(task.agent);
  for (const task of params.chain ?? []) names.add(task.agent);
  return [...names];
}

function finalOutput(result: SubagentResult): string {
  for (let index = result.messages.length - 1; index >= 0; index--) {
    const message = result.messages[index];
    if (message.role !== "assistant") continue;
    if (typeof message.content === "string") return message.content;
    if (!Array.isArray(message.content)) continue;
    return message.content
      .filter(
        (part): part is { type: "text"; text: string } =>
          part.type === "text" && typeof part.text === "string",
      )
      .map((part) => part.text)
      .join("\n");
  }
  return "";
}

interface ToolCallItem {
  name: string;
  arguments: Record<string, unknown>;
}

function toolCalls(result: SubagentResult): ToolCallItem[] {
  const calls: ToolCallItem[] = [];
  for (const message of result.messages) {
    if (message.role !== "assistant" || !Array.isArray(message.content)) continue;
    for (const part of message.content) {
      if (
        part.type === "toolCall" &&
        typeof part.name === "string" &&
        part.arguments &&
        typeof part.arguments === "object"
      ) {
        calls.push({
          name: part.name,
          arguments: part.arguments as Record<string, unknown>,
        });
      }
    }
  }
  return calls;
}

function formatToolCall(call: ToolCallItem, theme: any): string {
  if (call.name === "bash" && typeof call.arguments.command === "string") {
    const command = call.arguments.command;
    const preview = command.length > 300 ? `${command.slice(0, 297)}...` : command;
    return `${theme.fg("muted", "→ $ ")}${theme.fg("toolOutput", preview)}`;
  }
  const serialized = JSON.stringify(call.arguments);
  const preview =
    serialized.length > 300 ? `${serialized.slice(0, 297)}...` : serialized;
  return `${theme.fg("muted", "→ ")}${theme.fg("accent", call.name)} ${theme.fg("dim", preview)}`;
}

function statusIcon(result: SubagentResult, theme: any): string {
  if (result.status === "running") return theme.fg("warning", "…");
  if (result.status === "completed") return theme.fg("success", "✓");
  return theme.fg("error", "✗");
}

function resultSummary(result: SubagentResult, theme: any): string {
  const calls = toolCalls(result).slice(-5).map((call) => formatToolCall(call, theme));
  const output = finalOutput(result).trim();
  const summary = output
    ? output.split("\n").slice(-3).join("\n")
    : result.status === "running"
      ? "(running...)"
      : result.errorMessage || result.stderr.trim() || "(no output)";
  const preview =
    summary.length > 2_000 ? `…${summary.slice(summary.length - 1_999)}` : summary;
  return [
    `${statusIcon(result, theme)} ${theme.fg("accent", result.agent)} ${theme.fg("muted", `(${result.agentSource})`)}`,
    ...calls,
    theme.fg("toolOutput", preview),
  ].join("\n");
}

function childDepth(): number {
  const depth = Number.parseInt(process.env.PI_SUBAGENT_DEPTH ?? "0", 10);
  return Number.isFinite(depth) && depth > 0 ? depth : 0;
}

export default function subagentExtension(pi: ExtensionAPI) {
  if (childDepth() > 0) return;

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description: [
      "Delegate work to fresh, isolated Pi subprocesses.",
      "Use task for one worker, tasks for parallel independent work, or chain for sequential work with {previous} handoff.",
      `User agent profiles are loaded from ${getAgentDir()}/agents; project profiles require agentScope project or both.`,
    ].join(" "),
    promptSnippet:
      "Delegate self-contained work to fresh Pi contexts, singly, in parallel, or as a chain",
    promptGuidelines: [
      "Use subagent when a task materially benefits from a fresh context; keep small or tightly coupled work in the current context.",
      "Give subagent complete, self-contained instructions because children do not receive the parent conversation.",
      "Use subagent parallel mode only for independent tasks and chain mode only when a later task needs an earlier result.",
    ],
    executionMode: "parallel",
    parameters: SubagentParameters,
    prepareArguments: normalizeDispatchParams,

    async execute(_toolCallId, rawParams, signal, onUpdate, ctx) {
      const params = normalizeDispatchParams(rawParams);
      const scope = params.agentScope ?? "user";
      const discovery = discoverAgents(ctx.cwd, scope, {
        agentDir: getAgentDir(),
        configDirName: CONFIG_DIR_NAME,
        parseFrontmatter: (content) => parseFrontmatter(content),
      });

      const projectAgents = requestedAgentNames(params)
        .map((name) => discovery.agents.find((agent) => agent.name === name))
        .filter((agent) => agent?.source === "project");
      if (projectAgents.length && !ctx.isProjectTrusted()) {
        if (!ctx.hasUI) {
          throw new Error(
            "Project-local subagents require a trusted project or interactive confirmation.",
          );
        }
        const approved = await ctx.ui.confirm(
          "Run project-local subagents?",
          `Agents: ${projectAgents.map((agent) => agent!.name).join(", ")}\nSource: ${discovery.projectAgentsDir}\n\nThese prompts are controlled by the repository.`,
        );
        if (!approved) throw new Error("Project-local subagents were not approved.");
      }

      const outcome = await dispatchSubagents(
        params,
        {
          cwd: ctx.cwd,
          model: ctx.model
            ? `${ctx.model.provider}/${ctx.model.id}`
            : undefined,
          thinkingLevel: ctx.thinkingLevel,
          projectTrusted: ctx.isProjectTrusted(),
        },
        { agents: discovery.agents, runProcess: runPiProcess },
        onUpdate
          ? (update) =>
              onUpdate({
                content: [{ type: "text", text: update.text }],
                details: update.details,
              })
          : undefined,
        signal,
      );

      if (outcome.failed) throw new Error(outcome.text);
      return {
        content: [{ type: "text", text: outcome.text }],
        details: outcome.details,
        usage: outcome.usage,
      };
    },

    renderCall(args, theme) {
      const params = normalizeDispatchParams(args);
      const scope = params.agentScope ?? "user";
      if (params.tasks?.length) {
        return new Text(
          `${theme.fg("toolTitle", theme.bold("subagent "))}${theme.fg("accent", `${params.tasks.length} parallel tasks`)} ${theme.fg("muted", `[${scope}]`)}`,
          0,
          0,
        );
      }
      if (params.chain?.length) {
        return new Text(
          `${theme.fg("toolTitle", theme.bold("subagent "))}${theme.fg("accent", `${params.chain.length} chained tasks`)} ${theme.fg("muted", `[${scope}]`)}`,
          0,
          0,
        );
      }
      const task = params.task ?? "...";
      const preview = task.length > 80 ? `${task.slice(0, 77)}...` : task;
      return new Text(
        `${theme.fg("toolTitle", theme.bold("subagent "))}${theme.fg("accent", params.agent ?? "worker")} ${theme.fg("muted", `[${scope}]`)}\n${theme.fg("dim", preview)}`,
        0,
        0,
      );
    },

    renderResult(result, { expanded }, theme) {
      const details = result.details as SubagentDetails | undefined;
      if (!details?.results.length) {
        const content = result.content[0];
        return new Text(
          content?.type === "text" ? content.text : "(no output)",
          0,
          0,
        );
      }
      if (!expanded) {
        return new Text(
          details.results.map((child) => resultSummary(child, theme)).join("\n\n"),
          0,
          0,
        );
      }

      const container = new Container();
      const markdownTheme = getMarkdownTheme();
      for (const child of details.results) {
        container.addChild(
          new Text(
            `${statusIcon(child, theme)} ${theme.fg("toolTitle", theme.bold(child.agent))} ${theme.fg("muted", `(${child.agentSource})`)}`,
            0,
            0,
          ),
        );
        container.addChild(new Text(theme.fg("dim", child.task), 0, 0));
        for (const call of toolCalls(child)) {
          container.addChild(new Text(formatToolCall(call, theme), 0, 0));
        }
        const output = finalOutput(child).trim();
        if (output) container.addChild(new Markdown(output, 0, 0, markdownTheme));
        else {
          container.addChild(
            new Text(
              theme.fg(
                child.status === "failed" || child.status === "aborted"
                  ? "error"
                  : "muted",
                child.errorMessage || child.stderr.trim() || "(no output)",
              ),
              0,
              0,
            ),
          );
        }
        container.addChild(new Spacer(1));
      }
      return container;
    },
  });
}
