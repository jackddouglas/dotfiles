import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

async function loadRuntime() {
  try {
    return await import("./runtime.ts");
  } catch (error) {
    assert.fail(
      `subagent runtime should be loadable: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
}

test("defaults omitted agent names to worker in every mode", async () => {
  const runtime = await loadRuntime();

  assert.deepEqual(runtime.normalizeDispatchParams({ task: "single" }), {
    task: "single",
    agent: "worker",
    tasks: undefined,
    chain: undefined,
  });
  assert.deepEqual(
    runtime.normalizeDispatchParams({
      tasks: [{ task: "parallel" }],
      chain: [{ agent: "reviewer", task: "chain" }],
    }),
    {
      tasks: [{ agent: "worker", task: "parallel", cwd: undefined }],
      chain: [{ agent: "reviewer", task: "chain", cwd: undefined }],
      agent: undefined,
    },
  );
});

test("runs a worker in an isolated Pi process with inherited dispatch settings", async () => {
  const runtime = await loadRuntime();
  const requests: any[] = [];
  const updates: any[] = [];

  const outcome = await runtime.dispatchSubagents(
    { agent: "worker", task: "Inspect the authentication flow." },
    {
      cwd: "/work/project",
      model: "openai-codex/gpt-5.6-luna",
      thinkingLevel: "high",
      projectTrusted: true,
    },
    {
      agents: [
        {
          name: "worker",
          description: "General-purpose worker",
          systemPrompt: "Work autonomously and report concise findings.",
          source: "user",
          filePath: "/agents/worker.md",
        },
      ],
      runProcess: async (request: any) => {
        requests.push(request);
        const promptIndex = request.args.indexOf("--append-system-prompt");
        assert.notEqual(promptIndex, -1);
        assert.equal(
          await readFile(request.args[promptIndex + 1], "utf8"),
          "Work autonomously and report concise findings.\n",
        );
        request.onEvent({
          type: "message_end",
          message: {
            role: "assistant",
            content: [{ type: "text", text: "Authentication is handled in auth.ts." }],
            model: "gpt-5.6-luna",
            stopReason: "stop",
            usage: {
              input: 120,
              output: 30,
              cacheRead: 20,
              cacheWrite: 0,
              totalTokens: 170,
              cost: {
                input: 0.001,
                output: 0.002,
                cacheRead: 0.0001,
                cacheWrite: 0,
                total: 0.0031,
              },
            },
          },
        });
        return { exitCode: 0, stderr: "", aborted: false };
      },
    },
    (update: any) => updates.push(update),
  );

  assert.equal(requests.length, 1);
  assert.equal(requests[0].cwd, "/work/project");
  assert.equal(requests[0].env.PI_SUBAGENT_DEPTH, "1");
  assert.deepEqual(requests[0].args.slice(0, 12), [
    "--mode",
    "json",
    "-p",
    "--no-session",
    "--exclude-tools",
    "subagent",
    "--model",
    "openai-codex/gpt-5.6-luna",
    "--thinking",
    "high",
    "--approve",
    "--append-system-prompt",
  ]);
  assert.equal(requests[0].args.at(-1), "Task: Inspect the authentication flow.");
  assert.equal(updates.at(-1)?.details.results[0].status, "completed");
  assert.equal(outcome.failed, false);
  assert.equal(outcome.text, "Authentication is handled in auth.ts.");
  assert.equal(outcome.usage.totalTokens, 170);
});

test("runs parallel tasks with bounded concurrency and stable result order", async () => {
  const runtime = await loadRuntime();
  let active = 0;
  let maxActive = 0;

  const outcome = await runtime.dispatchSubagents(
    {
      tasks: Array.from({ length: 6 }, (_, index) => ({
        agent: "worker",
        task: `task-${index + 1}`,
      })),
    },
    {
      cwd: "/work/project",
      model: "openrouter/stealth/ox-alpha",
      thinkingLevel: "high",
      projectTrusted: true,
    },
    {
      agents: [
        {
          name: "worker",
          description: "General-purpose worker",
          systemPrompt: "Work autonomously.",
          source: "user",
          filePath: "/agents/worker.md",
        },
      ],
      runProcess: async (request: any) => {
        active++;
        maxActive = Math.max(maxActive, active);
        const task = request.args.at(-1).replace(/^Task: /, "");
        await new Promise((resolve) => setTimeout(resolve, 10));
        request.onEvent({
          type: "message_end",
          message: {
            role: "assistant",
            content: [{ type: "text", text: `finished ${task}` }],
            stopReason: "stop",
          },
        });
        active--;
        return { exitCode: 0, stderr: "", aborted: false };
      },
    },
  );

  assert.equal(maxActive, 4);
  assert.equal(outcome.failed, false);
  assert.deepEqual(
    outcome.details.results.map((result: any) => result.task),
    ["task-1", "task-2", "task-3", "task-4", "task-5", "task-6"],
  );
  assert.match(outcome.text, /Parallel: 6\/6 succeeded/);
  assert.ok(outcome.text.indexOf("finished task-1") < outcome.text.indexOf("finished task-6"));
});

test("preserves successful parallel results when a sibling fails", async () => {
  const runtime = await loadRuntime();

  const outcome = await runtime.dispatchSubagents(
    {
      tasks: [
        { agent: "worker", task: "succeed" },
        { agent: "worker", task: "fail" },
      ],
    },
    {
      cwd: "/work/project",
      model: "openrouter/stealth/ox-alpha",
      thinkingLevel: "high",
      projectTrusted: true,
    },
    {
      agents: [
        {
          name: "worker",
          description: "General-purpose worker",
          systemPrompt: "Work autonomously.",
          source: "user",
          filePath: "/agents/worker.md",
        },
      ],
      runProcess: async (request: any) => {
        const task = request.args.at(-1).replace(/^Task: /, "");
        if (task === "fail") {
          return { exitCode: 2, stderr: "child failed", aborted: false };
        }
        request.onEvent({
          type: "message_end",
          message: {
            role: "assistant",
            content: [{ type: "text", text: "useful result" }],
            stopReason: "stop",
          },
        });
        return { exitCode: 0, stderr: "", aborted: false };
      },
    },
  );

  assert.equal(outcome.failed, false);
  assert.deepEqual(
    outcome.details.results.map((result: any) => result.status),
    ["completed", "failed"],
  );
  assert.match(outcome.text, /Parallel: 1\/2 succeeded/);
  assert.match(outcome.text, /useful result/);
  assert.match(outcome.text, /child failed/);
});

test("runs chains sequentially with the previous output substituted", async () => {
  const runtime = await loadRuntime();
  const prompts: string[] = [];

  const outcome = await runtime.dispatchSubagents(
    {
      chain: [
        { agent: "worker", task: "Find the relevant files." },
        { agent: "worker", task: "Use these findings to plan: {previous}" },
      ],
    },
    {
      cwd: "/work/project",
      model: "openrouter/stealth/ox-alpha",
      thinkingLevel: "high",
      projectTrusted: false,
    },
    {
      agents: [
        {
          name: "worker",
          description: "General-purpose worker",
          systemPrompt: "Work autonomously.",
          source: "user",
          filePath: "/agents/worker.md",
        },
      ],
      runProcess: async (request: any) => {
        const prompt = request.args.at(-1);
        prompts.push(prompt);
        request.onEvent({
          type: "message_end",
          message: {
            role: "assistant",
            content: [
              {
                type: "text",
                text: prompts.length === 1 ? "src/auth.ts and test/auth.test.ts" : "Update auth and its tests.",
              },
            ],
            stopReason: "stop",
          },
        });
        return { exitCode: 0, stderr: "", aborted: false };
      },
    },
  );

  assert.deepEqual(prompts, [
    "Task: Find the relevant files.",
    "Task: Use these findings to plan: src/auth.ts and test/auth.test.ts",
  ]);
  assert.equal(outcome.details.results[0].step, 1);
  assert.equal(outcome.details.results[1].step, 2);
  assert.equal(outcome.text, "Update auth and its tests.");
  assert.equal(outcome.failed, false);
});

test("treats a child with no assistant response as failed", async () => {
  const runtime = await loadRuntime();

  const outcome = await runtime.dispatchSubagents(
    { agent: "worker", task: "Inspect the project." },
    {
      cwd: "/work/project",
      model: "openrouter/stealth/ox-alpha",
      thinkingLevel: "high",
      projectTrusted: true,
    },
    {
      agents: [
        {
          name: "worker",
          description: "General-purpose worker",
          systemPrompt: "Work autonomously.",
          source: "user",
          filePath: "/agents/worker.md",
        },
      ],
      runProcess: async () => ({ exitCode: 0, stderr: "", aborted: false }),
    },
  );

  assert.equal(outcome.failed, true);
  assert.equal(outcome.details.results[0].status, "failed");
  assert.match(outcome.text, /without an assistant response/);
});

test("stops a chain at the first failed child", async () => {
  const runtime = await loadRuntime();
  let calls = 0;

  const outcome = await runtime.dispatchSubagents(
    {
      chain: [
        { agent: "worker", task: "first" },
        { agent: "worker", task: "must not run: {previous}" },
      ],
    },
    {
      cwd: "/work/project",
      model: "openrouter/stealth/ox-alpha",
      thinkingLevel: "high",
      projectTrusted: true,
    },
    {
      agents: [
        {
          name: "worker",
          description: "General-purpose worker",
          systemPrompt: "Work autonomously.",
          source: "user",
          filePath: "/agents/worker.md",
        },
      ],
      runProcess: async () => {
        calls++;
        return { exitCode: 1, stderr: "first child failed", aborted: false };
      },
    },
  );

  assert.equal(calls, 1);
  assert.equal(outcome.failed, true);
  assert.equal(outcome.details.results.length, 1);
  assert.match(outcome.text, /Chain stopped at step 1/);
  assert.match(outcome.text, /first child failed/);
});

test("caps model-visible output while preserving full messages in details", async () => {
  const runtime = await loadRuntime();
  const fullOutput = "x".repeat(60 * 1024);

  const outcome = await runtime.dispatchSubagents(
    { agent: "worker", task: "Produce a large report." },
    {
      cwd: "/work/project",
      model: "openrouter/stealth/ox-alpha",
      thinkingLevel: "high",
      projectTrusted: true,
    },
    {
      agents: [
        {
          name: "worker",
          description: "General-purpose worker",
          systemPrompt: "Work autonomously.",
          source: "user",
          filePath: "/agents/worker.md",
        },
      ],
      runProcess: async (request: any) => {
        request.onEvent({
          type: "message_end",
          message: {
            role: "assistant",
            content: [{ type: "text", text: fullOutput }],
            stopReason: "stop",
          },
        });
        return { exitCode: 0, stderr: "", aborted: false };
      },
    },
  );

  assert.ok(Buffer.byteLength(outcome.text, "utf8") <= 50 * 1024);
  assert.match(outcome.text, /Output truncated/);
  const preservedContent = outcome.details.results[0].messages[0]
    .content as Array<{ type: string; text: string }>;
  assert.equal(preservedContent[0].text.length, fullOutput.length);

  const parallel = await runtime.dispatchSubagents(
    {
      tasks: [
        { agent: "worker", task: "report one" },
        { agent: "worker", task: "report two" },
      ],
    },
    {
      cwd: "/work/project",
      model: "openrouter/stealth/ox-alpha",
      thinkingLevel: "high",
      projectTrusted: true,
    },
    {
      agents: [
        {
          name: "worker",
          description: "General-purpose worker",
          systemPrompt: "Work autonomously.",
          source: "user",
          filePath: "/agents/worker.md",
        },
      ],
      runProcess: async (request: any) => {
        request.onEvent({
          type: "message_end",
          message: {
            role: "assistant",
            content: [{ type: "text", text: "y".repeat(30 * 1024) }],
            stopReason: "stop",
          },
        });
        return { exitCode: 0, stderr: "", aborted: false };
      },
    },
  );
  assert.ok(Buffer.byteLength(parallel.text, "utf8") <= 50 * 1024);
  assert.match(parallel.text, /Output truncated/);
});
