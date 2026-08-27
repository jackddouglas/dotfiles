import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

export type AgentScope = "user" | "project" | "both";
export type SubagentMode = "single" | "parallel" | "chain";
export type SubagentStatus = "running" | "completed" | "failed" | "aborted";

export interface AgentConfig {
  name: string;
  description: string;
  tools?: string[];
  model?: string;
  systemPrompt: string;
  source: "user" | "project";
  filePath: string;
}

export interface TaskInput {
  agent: string;
  task: string;
  cwd?: string;
}

export interface DispatchParams {
  agent?: string;
  task?: string;
  cwd?: string;
  tasks?: TaskInput[];
  chain?: TaskInput[];
  agentScope?: AgentScope;
}

export interface Usage {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  totalTokens: number;
  cost: {
    input: number;
    output: number;
    cacheRead: number;
    cacheWrite: number;
    total: number;
  };
}

export interface ChildMessage {
  role: string;
  content?: string | Array<Record<string, unknown>>;
  model?: string;
  stopReason?: string;
  errorMessage?: string;
  usage?: Usage;
}

export interface SubagentResult {
  agent: string;
  agentSource: AgentConfig["source"] | "unknown";
  task: string;
  status: SubagentStatus;
  exitCode?: number;
  messages: ChildMessage[];
  stderr: string;
  usage: Usage;
  model?: string;
  stopReason?: string;
  errorMessage?: string;
  step?: number;
}

export interface SubagentDetails {
  mode: SubagentMode;
  agentScope: AgentScope;
  results: SubagentResult[];
}

export interface DispatchOutcome {
  text: string;
  details: SubagentDetails;
  usage: Usage;
  failed: boolean;
}

export interface DispatchContext {
  cwd: string;
  model?: string;
  thinkingLevel?: string;
  projectTrusted: boolean;
}

export interface ProcessRequest {
  args: string[];
  cwd: string;
  env: NodeJS.ProcessEnv;
  signal?: AbortSignal;
  onEvent: (event: Record<string, unknown>) => void;
}

export interface ProcessResult {
  exitCode: number;
  stderr: string;
  aborted: boolean;
  spawnError?: string;
}

export type ProcessAdapter = (request: ProcessRequest) => Promise<ProcessResult>;

export interface DispatchDependencies {
  agents: AgentConfig[];
  runProcess: ProcessAdapter;
}

export type DispatchUpdate = (update: {
  text: string;
  details: SubagentDetails;
}) => void;

function normalizeTask(input: unknown): TaskInput {
  const task =
    input && typeof input === "object"
      ? (input as Record<string, unknown>)
      : {};
  return {
    agent:
      typeof task.agent === "string" && task.agent.trim()
        ? task.agent
        : "worker",
    task: typeof task.task === "string" ? task.task : "",
    cwd: typeof task.cwd === "string" ? task.cwd : undefined,
  };
}

export function normalizeDispatchParams(args: unknown): DispatchParams {
  if (!args || typeof args !== "object") return args as DispatchParams;
  const input = args as Record<string, unknown>;
  return {
    ...input,
    agent:
      typeof input.task === "string" &&
      (typeof input.agent !== "string" || !input.agent.trim())
        ? "worker"
        : (input.agent as string | undefined),
    tasks: Array.isArray(input.tasks)
      ? input.tasks.map(normalizeTask)
      : undefined,
    chain: Array.isArray(input.chain)
      ? input.chain.map(normalizeTask)
      : undefined,
  } as DispatchParams;
}

const MAX_PARALLEL_TASKS = 8;
const MAX_CONCURRENCY = 4;
const PER_TASK_OUTPUT_CAP = 50 * 1024;

const EMPTY_USAGE: Usage = {
  input: 0,
  output: 0,
  cacheRead: 0,
  cacheWrite: 0,
  totalTokens: 0,
  cost: {
    input: 0,
    output: 0,
    cacheRead: 0,
    cacheWrite: 0,
    total: 0,
  },
};

function cloneUsage(): Usage {
  return { ...EMPTY_USAGE, cost: { ...EMPTY_USAGE.cost } };
}

function addUsage(total: Usage, usage: Usage | undefined): void {
  if (!usage) return;
  total.input += usage.input ?? 0;
  total.output += usage.output ?? 0;
  total.cacheRead += usage.cacheRead ?? 0;
  total.cacheWrite += usage.cacheWrite ?? 0;
  total.totalTokens += usage.totalTokens ?? 0;
  total.cost.input += usage.cost?.input ?? 0;
  total.cost.output += usage.cost?.output ?? 0;
  total.cost.cacheRead += usage.cost?.cacheRead ?? 0;
  total.cost.cacheWrite += usage.cost?.cacheWrite ?? 0;
  total.cost.total += usage.cost?.total ?? 0;
}

function assistantOutput(messages: ChildMessage[]): string {
  for (let index = messages.length - 1; index >= 0; index--) {
    const message = messages[index];
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

function isFailed(result: SubagentResult): boolean {
  return (
    result.status === "failed" ||
    result.status === "aborted" ||
    result.exitCode !== 0 ||
    result.stopReason === "error" ||
    result.stopReason === "aborted"
  );
}

function resultText(result: SubagentResult): string {
  if (isFailed(result)) {
    return (
      result.errorMessage ||
      result.stderr.trim() ||
      assistantOutput(result.messages) ||
      `Subagent ${result.agent} failed without diagnostic output`
    );
  }
  return assistantOutput(result.messages) || "(no output)";
}

function aggregateUsage(results: SubagentResult[]): Usage {
  const usage = cloneUsage();
  for (const result of results) addUsage(usage, result.usage);
  return usage;
}

function truncateOutput(output: string): string {
  const bytes = Buffer.from(output, "utf8");
  if (bytes.length <= PER_TASK_OUTPUT_CAP) return output;
  const suffix = "\n\n[Output truncated; full output is preserved in tool details.]";
  const content = bytes
    .subarray(0, PER_TASK_OUTPUT_CAP - Buffer.byteLength(suffix))
    .toString("utf8")
    .replace(/\uFFFD$/, "");
  return `${content}${suffix}`;
}

async function mapWithConcurrency<TInput, TOutput>(
  inputs: TInput[],
  concurrency: number,
  run: (input: TInput, index: number) => Promise<TOutput>,
): Promise<TOutput[]> {
  const outputs = new Array<TOutput>(inputs.length);
  let nextIndex = 0;
  const workers = Array.from(
    { length: Math.min(concurrency, inputs.length) },
    async () => {
      while (true) {
        const index = nextIndex++;
        if (index >= inputs.length) return;
        outputs[index] = await run(inputs[index], index);
      }
    },
  );
  await Promise.all(workers);
  return outputs;
}

function childDepth(): number {
  const parsed = Number.parseInt(process.env.PI_SUBAGENT_DEPTH ?? "0", 10);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : 0;
}

async function runSingleAgent(
  input: TaskInput,
  step: number | undefined,
  context: DispatchContext,
  dependencies: DispatchDependencies,
  signal: AbortSignal | undefined,
  onUpdate: ((result: SubagentResult) => void) | undefined,
): Promise<SubagentResult> {
  const agent = dependencies.agents.find((candidate) => candidate.name === input.agent);
  if (!agent) {
    const available = dependencies.agents.map((candidate) => candidate.name).join(", ") || "none";
    return {
      agent: input.agent,
      agentSource: "unknown",
      task: input.task,
      status: "failed",
      exitCode: 1,
      messages: [],
      stderr: `Unknown agent: ${input.agent}. Available agents: ${available}.`,
      usage: cloneUsage(),
      step,
    };
  }

  const result: SubagentResult = {
    agent: agent.name,
    agentSource: agent.source,
    task: input.task,
    status: "running",
    messages: [],
    stderr: "",
    usage: cloneUsage(),
    model: agent.model ?? context.model,
    step,
  };

  const args = [
    "--mode",
    "json",
    "-p",
    "--no-session",
    "--exclude-tools",
    "subagent",
  ];
  const inheritsParentModel = !agent.model;
  const model = agent.model ?? context.model;
  if (model) args.push("--model", model);
  if (inheritsParentModel && context.thinkingLevel) {
    args.push("--thinking", context.thinkingLevel);
  }
  if (agent.tools?.length) args.push("--tools", agent.tools.join(","));
  args.push(context.projectTrusted ? "--approve" : "--no-approve");

  let promptDirectory: string | undefined;
  try {
    if (agent.systemPrompt.trim()) {
      promptDirectory = await mkdtemp(join(tmpdir(), "pi-subagent-"));
      const promptPath = join(promptDirectory, "system.md");
      await writeFile(promptPath, `${agent.systemPrompt.trim()}\n`, {
        encoding: "utf8",
        mode: 0o600,
      });
      args.push("--append-system-prompt", promptPath);
    }
    args.push(`Task: ${input.task}`);

    const processResult = await dependencies.runProcess({
      args,
      cwd: input.cwd ?? context.cwd,
      env: {
        ...process.env,
        PI_SUBAGENT_DEPTH: String(childDepth() + 1),
      },
      signal,
      onEvent(event) {
        const eventType = event.type;
        const message = event.message;
        if (
          (eventType === "message_end" || eventType === "tool_result_end") &&
          message &&
          typeof message === "object"
        ) {
          const childMessage = message as ChildMessage;
          result.messages.push(childMessage);
          if (childMessage.role === "assistant") {
            addUsage(result.usage, childMessage.usage);
            result.model = childMessage.model ?? result.model;
            result.stopReason = childMessage.stopReason;
            result.errorMessage = childMessage.errorMessage;
          }
          onUpdate?.(result);
        }
      },
    });

    result.exitCode = processResult.exitCode;
    result.stderr = processResult.spawnError
      ? [processResult.stderr, processResult.spawnError].filter(Boolean).join("\n")
      : processResult.stderr;
    if (processResult.aborted || result.stopReason === "aborted") {
      result.status = "aborted";
    } else if (
      processResult.exitCode !== 0 ||
      result.stopReason === "error" ||
      Boolean(processResult.spawnError)
    ) {
      result.status = "failed";
    } else if (!result.messages.some((message) => message.role === "assistant")) {
      result.status = "failed";
      result.errorMessage = "Subagent exited without an assistant response";
    } else {
      result.status = "completed";
    }
    onUpdate?.(result);
    return result;
  } finally {
    if (promptDirectory) {
      await rm(promptDirectory, { recursive: true, force: true });
    }
  }
}

export async function dispatchSubagents(
  params: DispatchParams,
  context: DispatchContext,
  dependencies: DispatchDependencies,
  onUpdate?: DispatchUpdate,
  signal?: AbortSignal,
): Promise<DispatchOutcome> {
  const scope = params.agentScope ?? "user";
  const hasSingle = Boolean(params.agent && params.task);
  const hasParallel = Boolean(params.tasks?.length);
  const hasChain = Boolean(params.chain?.length);
  const modeCount = Number(hasSingle) + Number(hasParallel) + Number(hasChain);

  if (modeCount !== 1) {
    return {
      text: "Provide exactly one subagent mode: agent + task, tasks, or chain.",
      details: { mode: "single", agentScope: scope, results: [] },
      usage: cloneUsage(),
      failed: true,
    };
  }

  if (hasParallel) {
    const tasks = params.tasks!;
    if (tasks.length > MAX_PARALLEL_TASKS) {
      return {
        text: `Parallel mode accepts at most ${MAX_PARALLEL_TASKS} tasks.`,
        details: { mode: "parallel", agentScope: scope, results: [] },
        usage: cloneUsage(),
        failed: true,
      };
    }

    const currentResults: SubagentResult[] = tasks.map((task) => ({
      agent: task.agent,
      agentSource: "unknown",
      task: task.task,
      status: "running",
      messages: [],
      stderr: "",
      usage: cloneUsage(),
    }));
    const emitUpdate = () =>
      onUpdate?.({
        text: `Parallel: ${currentResults.filter((result) => result.status !== "running").length}/${tasks.length} finished`,
        details: {
          mode: "parallel",
          agentScope: scope,
          results: [...currentResults],
        },
      });

    const results = await mapWithConcurrency(
      tasks,
      MAX_CONCURRENCY,
      async (task, index) => {
        const result = await runSingleAgent(
          task,
          undefined,
          context,
          dependencies,
          signal,
          (current) => {
            currentResults[index] = current;
            emitUpdate();
          },
        );
        currentResults[index] = result;
        emitUpdate();
        return result;
      },
    );
    const succeeded = results.filter((result) => !isFailed(result)).length;
    const summaries = results.map((result) => {
      const status = isFailed(result) ? result.status : "completed";
      return `### ${result.agent}: ${status}\n\n${truncateOutput(resultText(result))}`;
    });
    return {
      text: truncateOutput(
        `Parallel: ${succeeded}/${results.length} succeeded\n\n${summaries.join("\n\n---\n\n")}`,
      ),
      details: { mode: "parallel", agentScope: scope, results },
      usage: aggregateUsage(results),
      failed: succeeded === 0,
    };
  }

  if (hasChain) {
    const results: SubagentResult[] = [];
    let previousOutput = "";
    for (let index = 0; index < params.chain!.length; index++) {
      const step = params.chain![index];
      const input = {
        ...step,
        task: step.task.replaceAll("{previous}", previousOutput),
      };
      const result = await runSingleAgent(
        input,
        index + 1,
        context,
        dependencies,
        signal,
        onUpdate
          ? (current) =>
              onUpdate({
                text: assistantOutput(current.messages) || "(running...)",
                details: {
                  mode: "chain",
                  agentScope: scope,
                  results: [...results, current],
                },
              })
          : undefined,
      );
      results.push(result);
      if (isFailed(result)) {
        return {
          text: truncateOutput(
            `Chain stopped at step ${index + 1} (${result.agent}): ${resultText(result)}`,
          ),
          details: { mode: "chain", agentScope: scope, results },
          usage: aggregateUsage(results),
          failed: true,
        };
      }
      previousOutput = truncateOutput(assistantOutput(result.messages));
    }
    return {
      text: truncateOutput(resultText(results[results.length - 1])),
      details: { mode: "chain", agentScope: scope, results },
      usage: aggregateUsage(results),
      failed: false,
    };
  }

  const input = { agent: params.agent!, task: params.task!, cwd: params.cwd };
  const result = await runSingleAgent(
    input,
    undefined,
    context,
    dependencies,
    signal,
    onUpdate
      ? (current) =>
          onUpdate({
            text: assistantOutput(current.messages) || "(running...)",
            details: { mode: "single", agentScope: scope, results: [current] },
          })
      : undefined,
  );
  return {
    text: truncateOutput(resultText(result)),
    details: { mode: "single", agentScope: scope, results: [result] },
    usage: result.usage,
    failed: isFailed(result),
  };
}
