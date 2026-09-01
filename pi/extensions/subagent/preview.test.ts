import assert from "node:assert/strict";
import test from "node:test";

import {
  formatElapsed,
  formatMessageCount,
  formatPreviewMetadata,
  hasPreviewDetails,
  isCancelledToolResult,
  previewTask,
} from "./preview.ts";

test("previewTask keeps only a compact first line", () => {
  assert.equal(
    previewTask("  Map the repository\nThen inspect tests  "),
    "Map the repository",
  );
  assert.equal(previewTask("123456", 5), "12345…");
  assert.equal(previewTask("  "), "...");
});

test("formatElapsed presents stable seconds and minutes", () => {
  assert.equal(formatElapsed(1_000, undefined, 60_999), "59s");
  assert.equal(formatElapsed(1_000, 62_000), "1m 1s");
  assert.equal(formatElapsed(undefined, undefined, 62_000), undefined);
});

test("formatMessageCount uses the singular only for one", () => {
  assert.equal(formatMessageCount(0), "0 msgs");
  assert.equal(formatMessageCount(1), "1 msg");
  assert.equal(formatMessageCount(2), "2 msgs");
});

test("formatPreviewMetadata contains only compact run essentials", () => {
  assert.equal(
    formatPreviewMetadata({
      startedAt: 1_000,
      now: 36_000,
      provider: "openai-codex",
      model: "gpt-5.6-sol",
      thinking: "medium",
      messageCount: 4,
      terminal: "cmux",
    }),
    "35s · openai-codex/gpt-5.6-sol (medium) · 4 msgs · cmux",
  );
});

test("preview details validation rejects Pi's empty error details", () => {
  assert.equal(hasPreviewDetails({}), false);
  assert.equal(
    hasPreviewDetails({
      status: "running",
      task: "Inspect the repository",
      provider: "openai-codex",
      model: "gpt-5.6-luna",
      thinking: "low",
      messageCount: 4,
      terminal: "cmux",
    }),
    true,
  );
});

test("cancelled tool results are distinguished from ordinary failures", () => {
  assert.equal(
    isCancelledToolResult(true, [
      { type: "text", text: "This operation was aborted" },
    ]),
    true,
  );
  assert.equal(
    isCancelledToolResult(true, [{ type: "text", text: "Network failed" }]),
    false,
  );
  assert.equal(
    isCancelledToolResult(false, [
      { type: "text", text: "This operation was aborted" },
    ]),
    false,
  );
});
