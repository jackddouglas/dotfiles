import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { tmpdir } from "node:os";
import test from "node:test";
import subagent from "./subagent.ts";

type ExecCall = { command: string; args: string[] };

function loadExtension() {
  let tool: any;
  const execCalls: ExecCall[] = [];
  let scriptPath: string | undefined;

  const pi = {
    on() {},
    registerCommand() {},
    registerShortcut() {},
    registerTool(definition: any) {
      tool = definition;
    },
    getThinkingLevel() {
      return "high";
    },
    async exec(command: string, args: string[]) {
      execCalls.push({ command, args });
      if (args[0] === "split-window") {
        scriptPath = args.at(-1)?.replace(/^'|'$/g, "");
        assert.ok(scriptPath);
        await writeFile(
          join(dirname(scriptPath), "result.json"),
          `${JSON.stringify({ status: "completed", output: "Done" })}\n`,
        );
        return { code: 0, stdout: "%7\n", stderr: "", killed: false };
      }
      if (args[0] === "display-message") {
        return { code: 0, stdout: "1\n", stderr: "", killed: false };
      }
      return { code: 0, stdout: "", stderr: "", killed: false };
    },
  };

  subagent(pi as any);
  assert.ok(tool);
  return {
    tool,
    execCalls,
    getScriptPath: () => scriptPath,
  };
}

function context() {
  return {
    cwd: "/work/project",
    model: { provider: "openai-codex", id: "gpt-5.6-luna" },
    isProjectTrusted: () => true,
    sessionManager: {
      getSessionId: () => "parent-session",
    },
    ui: {
      theme: {
        fg(_color: string, text: string) {
          return text;
        },
      },
      setStatus() {},
    },
  };
}

test("spawns a named subagent with distinct session and pane identity", async () => {
  const agentDir = await mkdtemp(join(tmpdir(), "pi-subagent-test-"));
  const previousAgentDir = process.env.PI_CODING_AGENT_DIR;
  const previousTmuxPane = process.env.TMUX_PANE;
  process.env.PI_CODING_AGENT_DIR = agentDir;
  process.env.TMUX_PANE = "%1";

  try {
    const extension = loadExtension();
    assert.ok(extension.tool.parameters.required.includes("name"));

    const result = await extension.tool.execute(
      "tool-call",
      {
        name: "Audit sandbox escapes",
        task: "Inspect the sandbox boundary for escape paths.",
      },
      undefined,
      undefined,
      context(),
    );

    assert.equal(result.details.paneName, "Audit sandbox escapes");
    const titleCall = extension.execCalls.find(
      ({ args }) => args[0] === "select-pane" && args.includes("-T"),
    );
    assert.deepEqual(titleCall?.args.slice(-2), [
      "-T",
      "↳ Audit sandbox escapes",
    ]);

    const scriptPath = extension.getScriptPath();
    assert.ok(scriptPath);
    const script = await readFile(scriptPath, "utf8");
    assert.match(script, /export PI_SESSION_ROLE='subagent'/);
    assert.ok(script.includes("'--name' 'Audit sandbox escapes'"));
  } finally {
    if (previousAgentDir === undefined) delete process.env.PI_CODING_AGENT_DIR;
    else process.env.PI_CODING_AGENT_DIR = previousAgentDir;
    if (previousTmuxPane === undefined) delete process.env.TMUX_PANE;
    else process.env.TMUX_PANE = previousTmuxPane;
    await rm(agentDir, { recursive: true, force: true });
  }
});

test("fills the name for stored task-only tool calls", () => {
  const extension = loadExtension();

  assert.deepEqual(
    extension.tool.prepareArguments({ task: "Audit sandbox escapes" }),
    {
      name: "Audit sandbox escapes",
      task: "Audit sandbox escapes",
    },
  );
});
