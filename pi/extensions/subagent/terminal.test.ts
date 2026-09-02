import assert from "node:assert/strict";
import test from "node:test";

import {
  mainTerminalTitle,
  restoreSessionTaskTitle,
  SESSION_TASK_TITLE_ENTRY,
} from "../session-task.ts";

import {
  findCmuxWorkspace,
  findTmuxWindow,
  findTmuxWorkspaceName,
  interactiveChildCommand,
  isSameOrDescendant,
  parseCmuxSurfaceTarget,
  parseFirstCmuxSurface,
  parseCmuxIdentity,
  parseCmuxWorkspaceTarget,
  parseTmuxIdentity,
  parseTmuxWindowCreation,
  selectTerminalBackend,
  setTmuxPaneTitle,
  shellQuote,
  terminalWorkspaceName,
  terminalWorkspaceNameForSession,
  terminalWorkspaceSuffix,
  tmuxChildCommandArgs,
  tmuxClosePaneOnExitArgs,
  tmuxNewWindowArgs,
  tmuxPaneHasExited,
  tmuxSplitWindowArgs,
  tmuxWindowIdentityArgs,
  tmuxWindowNameForSession,
  TMUX_WINDOW_LIST_FORMAT,
} from "./terminal.ts";

test("auto terminal selection prefers the innermost active terminal", () => {
  assert.equal(
    selectTerminalBackend("auto", { CMUX_WORKSPACE_ID: "workspace-id" }),
    "cmux",
  );
  assert.equal(
    selectTerminalBackend("auto", {
      CMUX_WORKSPACE_ID: "outer-cmux-workspace",
      TMUX: "/tmp/tmux,1,0",
      TMUX_PANE: "%9",
    }),
    "tmux",
  );
  assert.equal(
    selectTerminalBackend("auto", {
      TMUX: "/tmp/tmux,1,0",
      TMUX_PANE: "%9",
    }),
    "tmux",
  );
  assert.equal(selectTerminalBackend("cmux", {}), "cmux");
});

test("tmux identity comes from the invoking pane and current server", () => {
  assert.deepEqual(
    parseTmuxIdentity({
      TMUX: "/tmp/socket,with-comma,123,0",
      TMUX_PANE: "%9",
    }),
    { socketPath: "/tmp/socket,with-comma", paneId: "%9" },
  );
  assert.throws(
    () => parseTmuxIdentity({}),
    /requires Pi to be running inside a tmux session/,
  );
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
    "π′ - Session - parentse",
  );
  assert.equal(
    terminalWorkspaceName(
      "session/with:punctuation",
      "Use Generated Session Title!",
    ),
    "π′ - Use Generated Session Title - sessionw",
  );
  assert.equal(
    terminalWorkspaceName("parent-session-id", "  ...  "),
    "π′ - Session - parentse",
  );
  assert.equal(terminalWorkspaceSuffix("parent-session-id"), " - parentse");
});

test("tmux workspace lookup accepts current and legacy title prefixes", () => {
  assert.equal(
    findTmuxWorkspaceName(
      [
        "unrelated - parentse",
        "π′ - Wrong session - otherid",
        "π′ - Current session - parentse",
      ].join("\n"),
      "parent-session-id",
    ),
    "π′ - Current session - parentse",
  );
  assert.equal(
    findTmuxWorkspaceName(
      "π subagents - Previous session - parentse\n",
      "parent-session-id",
    ),
    "π subagents - Previous session - parentse",
  );
  assert.equal(
    findTmuxWorkspaceName(
      "π - Original session - parentse\n",
      "parent-session-id",
    ),
    "π - Original session - parentse",
  );
  assert.equal(
    findTmuxWorkspaceName(
      "π′ - Other session - otherid\n",
      "parent-session-id",
    ),
    undefined,
  );
});

test("tmux window lookup uses hidden session identity", () => {
  assert.equal(
    TMUX_WINDOW_LIST_FORMAT,
    "#{window_id}\t#{window_name}\t#{@pi_subagent_session_id}",
  );
  const output = [
    "@1\tmain\t",
    "@2\tπ′ - Current session\tparent-session-id",
    "@3\tπ′ - Current session\tother-session-id",
    "@4\tπ′ - Legacy session - legacyse\t",
  ].join("\n");
  assert.deepEqual(findTmuxWindow(output, "parent-session-id"), {
    target: "@2",
    name: "π′ - Current session",
  });
  assert.deepEqual(findTmuxWindow(output, "legacy-session-id"), {
    target: "@4",
    name: "π′ - Legacy session - legacyse",
  });
  assert.equal(findTmuxWindow(output, "missing-session-id"), undefined);
  assert.deepEqual(tmuxWindowIdentityArgs("@2", "parent-session-id"), [
    "set-window-option",
    "-t",
    "@2",
    "@pi_subagent_session_id",
    "parent-session-id",
  ]);
  assert.deepEqual(parseTmuxWindowCreation("%42\t@2\n"), {
    paneTarget: "%42",
    windowTarget: "@2",
  });
  assert.throws(
    () => parseTmuxWindowCreation("%42\n"),
    /did not report the created subagent window/,
  );
});

test("tmux panes are exited when dead or already removed", () => {
  assert.equal(tmuxPaneHasExited(0, "0\n"), false);
  assert.equal(tmuxPaneHasExited(0, "1\n"), true);
  assert.equal(tmuxPaneHasExited(1, ""), true);
});

test("tmux pane titles use the child run name", async () => {
  const calls: Array<{ command: string; args: string[] }> = [];
  await setTmuxPaneTitle(
    async (command, args) => {
      calls.push({ command, args });
      return { code: 0, stderr: "" };
    },
    ["-S", "/tmp/subagents.sock"],
    "%42",
    "subagent-12345678",
  );

  assert.deepEqual(calls, [
    {
      command: "tmux",
      args: [
        "-S",
        "/tmp/subagents.sock",
        "select-pane",
        "-t",
        "%42",
        "-T",
        "subagent-12345678",
      ],
    },
  ]);
  await assert.rejects(
    setTmuxPaneTitle(
      async () => ({ code: 1, stderr: "title denied" }),
      [],
      "%42",
      "subagent-12345678",
    ),
    /title denied/,
  );
});

test("generated titles take precedence in subagent workspace names", () => {
  assert.equal(
    tmuxWindowNameForSession("Generated title", "Manual name"),
    "π′ - Generated title",
  );
  assert.equal(
    tmuxWindowNameForSession(undefined, "Manual name"),
    "π′ - Manual name",
  );
  assert.equal(
    terminalWorkspaceNameForSession(
      "parent-session-id",
      "Generated title",
      "Manual name",
    ),
    "π′ - Generated title - parentse",
  );
  assert.equal(
    terminalWorkspaceNameForSession(
      "parent-session-id",
      undefined,
      "Manual name",
    ),
    "π′ - Manual name - parentse",
  );
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

test("the main terminal title prefers the session name", () => {
  assert.equal(
    mainTerminalTitle("/work/project", "Review workspace titles"),
    "π - Review workspace titles",
  );
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

test("child launch commands do not exec through an interactive shell", () => {
  const launcherPath = "/tmp/Jack's task/run.sh";
  assert.deepEqual(tmuxChildCommandArgs(launcherPath), [
    "/bin/sh",
    launcherPath,
  ]);
  assert.deepEqual(
    tmuxNewWindowArgs("$0", "π′ - Session", "/work", launcherPath),
    [
      "new-window",
      "-d",
      "-P",
      "-F",
      "#{pane_id}\t#{window_id}",
      "-t",
      "$0",
      "-n",
      "π′ - Session",
      "-c",
      "/work",
      "/bin/sh",
      launcherPath,
    ],
  );
  assert.deepEqual(tmuxClosePaneOnExitArgs("@2"), [
    "set-window-option",
    "-t",
    "@2",
    "remain-on-exit",
    "off",
  ]);
  assert.deepEqual(tmuxSplitWindowArgs("@2", "/work", launcherPath), [
    "split-window",
    "-d",
    "-P",
    "-F",
    "#{pane_id}",
    "-t",
    "@2",
    "-c",
    "/work",
    "/bin/sh",
    launcherPath,
  ]);
  assert.equal(
    interactiveChildCommand(launcherPath),
    `/bin/sh '/tmp/Jack'"'"'s task/run.sh'`,
  );
});
