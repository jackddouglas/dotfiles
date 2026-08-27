import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join } from "node:path";
import type { AgentConfig, AgentScope } from "./runtime.ts";

interface ParsedFrontmatter {
  frontmatter: Record<string, unknown>;
  body: string;
}

export interface AgentDiscoveryDependencies {
  agentDir: string;
  configDirName: string;
  parseFrontmatter: (content: string) => ParsedFrontmatter;
}

export interface AgentDiscoveryResult {
  agents: AgentConfig[];
  projectAgentsDir: string | null;
}

function parseToolList(value: unknown): string[] | undefined {
  const values = Array.isArray(value)
    ? value
    : typeof value === "string"
      ? value.split(",")
      : [];
  const tools = values
    .filter((tool): tool is string => typeof tool === "string")
    .map((tool) => tool.trim())
    .filter(Boolean);
  return tools.length ? tools : undefined;
}

function loadAgents(
  directory: string,
  source: AgentConfig["source"],
  parseFrontmatter: AgentDiscoveryDependencies["parseFrontmatter"],
): AgentConfig[] {
  if (!existsSync(directory)) return [];

  let entries;
  try {
    entries = readdirSync(directory, { withFileTypes: true });
  } catch {
    return [];
  }

  const agents: AgentConfig[] = [];
  for (const entry of entries.sort((left, right) => left.name.localeCompare(right.name))) {
    if (!entry.name.endsWith(".md")) continue;
    if (!entry.isFile() && !entry.isSymbolicLink()) continue;

    const filePath = join(directory, entry.name);
    try {
      const { frontmatter, body } = parseFrontmatter(readFileSync(filePath, "utf8"));
      if (
        typeof frontmatter.name !== "string" ||
        typeof frontmatter.description !== "string"
      ) {
        continue;
      }
      agents.push({
        name: frontmatter.name,
        description: frontmatter.description,
        tools: parseToolList(frontmatter.tools),
        model:
          typeof frontmatter.model === "string" ? frontmatter.model : undefined,
        systemPrompt: body,
        source,
        filePath,
      });
    } catch {
      // One malformed or unreadable profile must not hide the other agents.
    }
  }
  return agents;
}

function isDirectory(path: string): boolean {
  try {
    return statSync(path).isDirectory();
  } catch {
    return false;
  }
}

function nearestProjectAgentsDirectory(
  cwd: string,
  configDirName: string,
): string | null {
  let current = cwd;
  while (true) {
    const candidate = join(current, configDirName, "agents");
    if (isDirectory(candidate)) return candidate;
    const parent = dirname(current);
    if (parent === current) return null;
    current = parent;
  }
}

export function discoverAgents(
  cwd: string,
  scope: AgentScope,
  dependencies: AgentDiscoveryDependencies,
): AgentDiscoveryResult {
  const projectAgentsDir = nearestProjectAgentsDirectory(
    cwd,
    dependencies.configDirName,
  );
  const userAgents =
    scope === "project"
      ? []
      : loadAgents(
          join(dependencies.agentDir, "agents"),
          "user",
          dependencies.parseFrontmatter,
        );
  const projectAgents =
    scope === "user" || !projectAgentsDir
      ? []
      : loadAgents(projectAgentsDir, "project", dependencies.parseFrontmatter);

  const agents = new Map<string, AgentConfig>();
  for (const agent of userAgents) agents.set(agent.name, agent);
  for (const agent of projectAgents) agents.set(agent.name, agent);
  return { agents: [...agents.values()], projectAgentsDir };
}
