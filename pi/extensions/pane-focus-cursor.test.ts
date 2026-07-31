import assert from "node:assert/strict";
import test from "node:test";
import paneFocusCursor from "./pane-focus-cursor.ts";

type Handler = (event: any, ctx: any) => Promise<void> | void;
type TerminalInputResult = { consume?: boolean; data?: string } | undefined;

function loadExtension() {
  const handlers = new Map<string, Handler[]>();
  paneFocusCursor({
    on(event: string, handler: Handler) {
      handlers.set(event, [...(handlers.get(event) ?? []), handler]);
    },
  } as any);

  return async (event: string, ctx: object = {}) => {
    for (const handler of handlers.get(event) ?? []) {
      await handler({ type: event }, ctx);
    }
  };
}

test("re-registers managed terminal input across reload", async () => {
  const emit = loadExtension();
  const terminalHandlers: Array<(data: string) => TerminalInputResult> = [];
  const unsubscribed: number[] = [];
  const editorFactories: unknown[] = [];
  const originalTmuxPane = process.env.TMUX_PANE;
  const originalWrite = process.stdout.write;
  const originalStdinOn = process.stdin.on;
  const originalStdinRemoveListener = process.stdin.removeListener;
  const terminalWrites: string[] = [];

  delete process.env.TMUX_PANE;
  process.stdin.on = (() => process.stdin) as typeof process.stdin.on;
  process.stdin.removeListener = (() =>
    process.stdin) as typeof process.stdin.removeListener;
  process.stdout.write = ((chunk: string | Uint8Array) => {
    terminalWrites.push(chunk.toString());
    return true;
  }) as typeof process.stdout.write;

  const ctx = {
    mode: "tui",
    ui: {
      onTerminalInput(handler: (data: string) => TerminalInputResult) {
        const index = terminalHandlers.push(handler) - 1;
        return () => unsubscribed.push(index);
      },
      setEditorComponent(factory: unknown) {
        editorFactories.push(factory);
      },
    },
  };

  try {
    await emit("session_start", ctx);
    assert.equal(terminalHandlers.length, 1);
    assert.deepEqual(terminalHandlers[0]!("\x1b[Otyped"), { data: "typed" });

    await emit("session_shutdown");
    assert.deepEqual(unsubscribed, [0]);

    await emit("session_start", ctx);
    assert.equal(terminalHandlers.length, 2);
    assert.equal(editorFactories.length, 2);
    assert.deepEqual(terminalWrites, [
      "\x1b[?1004h",
      "\x1b[?1004l",
      "\x1b[?1004h",
    ]);
  } finally {
    await emit("session_shutdown");
    process.stdout.write = originalWrite;
    process.stdin.on = originalStdinOn;
    process.stdin.removeListener = originalStdinRemoveListener;
    if (originalTmuxPane === undefined) delete process.env.TMUX_PANE;
    else process.env.TMUX_PANE = originalTmuxPane;
  }
});
