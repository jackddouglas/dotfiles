import assert from "node:assert/strict";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

async function loadProcessAdapter() {
  try {
    return await import("./process.ts");
  } catch (error) {
    assert.fail(
      `process adapter should be loadable: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
}

test("streams complete JSON events and preserves child diagnostics", async () => {
  const directory = await mkdtemp(join(tmpdir(), "pi-subagent-process-"));
  const script = join(directory, "child.mjs");
  await writeFile(
    script,
    [
      'process.stdout.write(\'{"type":"message_\');',
      'setTimeout(() => process.stdout.write(\'end","sequence":1}\\nnot-json\\n{"type":"message_end","sequence":2}\'), 5);',
      'setTimeout(() => { process.stderr.write("diagnostic\\n"); process.exit(7); }, 10);',
    ].join("\n"),
  );

  try {
    const { createProcessAdapter } = await loadProcessAdapter();
    const events: any[] = [];
    const runProcess = createProcessAdapter({
      command: process.execPath,
      prefixArgs: [script],
    });
    const result = await runProcess({
      args: [],
      cwd: directory,
      env: process.env,
      onEvent: (event: any) => events.push(event),
    });

    assert.deepEqual(
      events.map((event) => [event.type, event.sequence]),
      [
        ["message_end", 1],
        ["message_end", 2],
      ],
    );
    assert.equal(result.exitCode, 7);
    assert.equal(result.stderr, "diagnostic\n");
    assert.equal(result.aborted, false);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test("aborting a dispatch terminates its child process", async () => {
  const directory = await mkdtemp(join(tmpdir(), "pi-subagent-abort-"));
  const script = join(directory, "child.mjs");
  await writeFile(
    script,
    'process.stdout.write(\'{"type":"ready"}\\n\'); setInterval(() => {}, 1000);\n',
  );

  try {
    const { createProcessAdapter } = await loadProcessAdapter();
    const controller = new AbortController();
    const runProcess = createProcessAdapter({
      command: process.execPath,
      prefixArgs: [script],
    });
    const result = await runProcess({
      args: [],
      cwd: directory,
      env: process.env,
      signal: controller.signal,
      onEvent: () => controller.abort(),
    });

    assert.equal(result.aborted, true);
    assert.notEqual(result.exitCode, 0);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});
