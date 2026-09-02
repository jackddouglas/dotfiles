import assert from "node:assert/strict";
import test from "node:test";

import {
  mainTerminalTitle,
  restoreSessionTaskTitle,
  SESSION_TASK_TITLE_ENTRY,
} from "../session-task.ts";

import {
  findCmuxWorkspace,
  isSameOrDescendant,
  parseCmuxSurfaceTarget,
  parseFirstCmuxSurface,
  parseCmuxIdentity,
  parseCmuxWorkspaceTarget,
  selectTerminalBackend,
  shellQuote,
  terminalWorkspaceName,
  terminalWorkspaceSuffix,
} from "./terminal.ts";

test("auto terminal selection prefers the active cmux environment", () => {
  assert.equal(
    selectTerminalBackend("auto", { CMUX_WORKSPACE_ID: "workspace-id" }),
    "cmux",
  );
  assert.equal(
    selectTerminalBackend("auto", { TMUX: "/tmp/tmux,1,0" }),
    "tmux",
  );
  assert.equal(selectTerminalBackend("cmux", {}), "cmux");
});

test("cmux response parsers prefer stable UUIDs and accept refs", () => {
  assert.deepEqual(
    parseCmuxIdentity(
      JSON.stringify({
        caller: { window_id: "window-uuid", window_ref: "window:1" },
      }),
    ),
    { windowId: "window-uuid" },
  );
  assert.equal(
    parseCmuxWorkspaceTarget(
      JSON.stringify({
        ok: true,
        result: {
          workspace_id: "workspace-uuid",
          workspace_ref: "workspace:2",
        },
      }),
    ),
    "workspace-uuid",
  );
  assert.equal(
    parseCmuxWorkspaceTarget(JSON.stringify({ workspace_ref: "workspace:3" })),
    "workspace:3",
  );
  assert.equal(parseCmuxWorkspaceTarget("OK workspace:4\n"), "workspace:4");
  assert.equal(
    parseCmuxWorkspaceTarget("cmux: legacy notice\nOK workspace:5\n"),
    "workspace:5",
  );
  assert.deepEqual(
    findCmuxWorkspace(
      JSON.stringify({
        workspaces: [
          { id: "other-uuid", title: "Other" },
          {
            id: "workspace-uuid",
            ref: "workspace:2",
            title: "pi-subagents-parent-id",
          },
        ],
      }),
      "pi-subagents-parent-id",
    ),
    { target: "workspace-uuid" },
  );
  assert.equal(
    findCmuxWorkspace(JSON.stringify({ workspaces: [] }), "missing"),
    undefined,
  );
  assert.equal(
    parseCmuxSurfaceTarget(
      JSON.stringify({ surface_id: "surface-uuid", surface_ref: "surface:3" }),
    ),
    "surface-uuid",
  );
  assert.equal(parseCmuxSurfaceTarget("OK surface:4\n"), "surface:4");
  assert.equal(
    parseFirstCmuxSurface(
      JSON.stringify({
        surfaces: [{ id: "first-surface", ref: "surface:1" }],
      }),
    ),
    "first-surface",
  );
});

test("workspace names are deterministic for the parent Pi session", () => {
  assert.equal(
    terminalWorkspaceName("parent-session-id"),
    "π - Session - parentse",
  );
  assert.equal(
    terminalWorkspaceName(
      "session/with:punctuation",
      "Use Generated Session Title!",
    ),
    "π - Use Generated Session Title - sessionw",
  );
  assert.equal(
    terminalWorkspaceName("parent-session-id", "  ...  "),
    "π - Session - parentse",
  );
  assert.equal(terminalWorkspaceSuffix("parent-session-id"), " - parentse");
});

test("generated session titles restore from hidden session entries", () => {
  assert.equal(
    restoreSessionTaskTitle([
      {
        type: "custom",
        customType: SESSION_TASK_TITLE_ENTRY,
        data: { title: "First title" },
      },
      {
        type: "custom",
        customType: SESSION_TASK_TITLE_ENTRY,
        data: { title: "Shared Subagent Workspace" },
      },
    ]),
    "Shared Subagent Workspace",
  );
});

test("the main terminal title stays directory-based", () => {
  assert.equal(mainTerminalTitle("/work/project"), "π - project");
});

test("trust inheritance stays inside the parent directory", () => {
  assert.equal(isSameOrDescendant("/work/project", "/work/project/src"), true);
  assert.equal(
    isSameOrDescendant("/work/project", "/work/project-other"),
    false,
  );
  assert.equal(isSameOrDescendant("/work/project", "/tmp/project"), false);
});

test("shell quoting preserves apostrophes", () => {
  assert.equal(shellQuote("Jack's task"), `'Jack'"'"'s task'`);
});
