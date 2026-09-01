import assert from "node:assert/strict";
import test from "node:test";

import {
  isSameOrDescendant,
  parseCmuxIdentity,
  parseCmuxWorkspaceTarget,
  selectTerminalBackend,
  shellQuote,
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
