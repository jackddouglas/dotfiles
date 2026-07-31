import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import tmuxNotifications from "./tmux-notifications.ts";

type Handler = (event: any, ctx: any) => Promise<void> | void;

function loadExtension() {
  const handlers = new Map<string, Handler[]>();
  tmuxNotifications({
    on(event: string, handler: Handler) {
      handlers.set(event, [...(handlers.get(event) ?? []), handler]);
    },
  } as any);

  return async (event: string, payload: object = {}, ctx: object = {}) => {
    for (const handler of handlers.get(event) ?? []) {
      await handler({ type: event, ...payload }, ctx);
    }
  };
}

async function waitFor(check: () => Promise<boolean>): Promise<void> {
  const deadline = Date.now() + 2_000;
  while (!(await check())) {
    if (Date.now() >= deadline) throw new Error("timed out waiting for tmux notification");
    await new Promise((resolve) => setTimeout(resolve, 10));
  }
}

test("matches agent tmux notification lifecycle", async () => {
  const directory = await mkdtemp(join(tmpdir(), "pi-tmux-notifications-"));
  const tmux = join(directory, "tmux");
  const log = join(directory, "tmux.log");
  const tty = join(directory, "pane.tty");
  const originalEnv = { ...process.env };

  await writeFile(
    tmux,
    "#!/bin/sh\nprintf '%s|' \"$@\" >>\"$TMUX_TEST_LOG\"\nprintf '\\n' >>\"$TMUX_TEST_LOG\"\nif [ \"$1\" = display-message ]; then printf '%s\\n' \"$TMUX_TEST_TTY\"; fi\n",
    { mode: 0o755 },
  );
  await writeFile(log, "");
  await writeFile(tty, "");

  Object.assign(process.env, {
    PATH: `${directory}:${originalEnv.PATH}`,
    TMUX_PANE: "%42",
    TMUX_TEST_LOG: log,
    TMUX_TEST_TTY: tty,
  });

  try {
    const emit = loadExtension();
    const ui = {
      select: async (_title: string, _options: string[]) => undefined,
      confirm: async (_title: string, _message: string) => true,
      input: async (_title: string) => undefined,
      editor: async (_title: string) => undefined,
      custom: async (_factory: unknown) => undefined,
    };
    let idle = true;
    const ctx = { ui, hasUI: true, isIdle: () => idle };

    await emit("session_start", {}, ctx);
    await ui.confirm("User command", "This is not an agent wait");
    await new Promise((resolve) => setTimeout(resolve, 50));
    assert.equal(await readFile(log, "utf8"), "");

    await emit("session_shutdown");
    await emit("session_start", {}, ctx);
    await emit("input");
    await waitFor(async () => (await readFile(log, "utf8")).includes("@agent_alert||"));

    idle = false;
    await ui.confirm("Continue?", "Agent needs input");
    await waitFor(async () => (await readFile(tty, "utf8")) === "\u0007");
    const dialogLog = await readFile(log, "utf8");
    assert.equal(dialogLog.match(/@agent_alert\|\?\|/g)?.length, 1);
    assert.equal(dialogLog.match(/display-message\|/g)?.length, 1);

    await writeFile(log, "");
    await writeFile(tty, "");
    await emit("agent_end", {
      messages: [{ role: "assistant", stopReason: "stop" }],
    });
    await emit("agent_settled", {}, ctx);
    await new Promise((resolve) => setTimeout(resolve, 50));
    assert.equal(await readFile(log, "utf8"), "");

    idle = true;
    await emit("agent_settled", {}, ctx);
    await waitFor(async () => (await readFile(tty, "utf8")) === "\u0007");
    assert.match(await readFile(log, "utf8"), /@agent_alert\|✓\|/);

    await writeFile(log, "");
    await writeFile(tty, "");
    await emit("agent_end", {
      messages: [{ role: "assistant", stopReason: "error" }],
    });
    await emit("agent_settled", {}, ctx);
    await waitFor(async () => (await readFile(tty, "utf8")) === "\u0007");
    assert.match(await readFile(log, "utf8"), /@agent_alert\|!\|/);

    await writeFile(log, "");
    await writeFile(tty, "");
    idle = false;
    await ui.confirm("Pause?", "The aborted agent needs input");
    await waitFor(async () => (await readFile(tty, "utf8")) === "\u0007");
    await writeFile(log, "");
    await writeFile(tty, "");

    await emit("agent_end", {
      messages: [{ role: "assistant", stopReason: "aborted" }],
    });
    idle = true;
    await emit("agent_settled", {}, ctx);
    await waitFor(async () => (await readFile(log, "utf8")).includes("@agent_alert||"));
    assert.doesNotMatch(await readFile(log, "utf8"), /display-message\|/);
    assert.equal(await readFile(tty, "utf8"), "");
  } finally {
    process.env = originalEnv;
    await rm(directory, { recursive: true, force: true });
  }
});
