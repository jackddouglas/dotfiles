import assert from "node:assert/strict";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

async function loadAgents() {
  try {
    return await import("./agents.ts");
  } catch (error) {
    assert.fail(
      `agent discovery should be loadable: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
}

function parseFrontmatter(content: string) {
  const [, header = "", body = ""] = content.split("---");
  const frontmatter = Object.fromEntries(
    header
      .trim()
      .split("\n")
      .map((line) => line.split(/:\s*/, 2)),
  );
  return { frontmatter, body: body.trim() };
}

test("project agents are excluded by default and override user agents only when requested", async () => {
  const root = await mkdtemp(join(tmpdir(), "pi-subagent-agents-"));
  const agentDir = join(root, "home");
  const project = join(root, "repo");
  const nestedCwd = join(project, "src", "feature");
  await mkdir(join(agentDir, "agents"), { recursive: true });
  await mkdir(join(project, ".pi", "agents"), { recursive: true });
  await mkdir(nestedCwd, { recursive: true });
  await writeFile(
    join(agentDir, "agents", "worker.md"),
    "---\nname: worker\ndescription: User worker\n---\nUser instructions\n",
  );
  await writeFile(
    join(project, ".pi", "agents", "worker.md"),
    "---\nname: worker\ndescription: Project worker\n---\nProject instructions\n",
  );

  try {
    const { discoverAgents } = await loadAgents();
    const dependencies = {
      agentDir,
      configDirName: ".pi",
      parseFrontmatter,
    };

    const user = discoverAgents(nestedCwd, "user", dependencies);
    assert.deepEqual(
      user.agents.map((agent: any) => [agent.name, agent.description, agent.source]),
      [["worker", "User worker", "user"]],
    );
    assert.equal(user.projectAgentsDir, join(project, ".pi", "agents"));

    const both = discoverAgents(nestedCwd, "both", dependencies);
    assert.deepEqual(
      both.agents.map((agent: any) => [agent.name, agent.description, agent.source]),
      [["worker", "Project worker", "project"]],
    );
    assert.equal(both.agents[0].systemPrompt, "Project instructions");
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});
