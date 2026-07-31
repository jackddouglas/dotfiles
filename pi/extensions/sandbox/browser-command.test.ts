import assert from "node:assert/strict";
import test from "node:test";
import {
  BROWSER_SESSION_ID,
  createSandboxedCommandEnvironment,
} from "./browser-command.ts";

const processEnvironment = {
  PATH: "/base/bin",
  TMPDIR: "/base/tmp",
  XDG_RUNTIME_DIR: "/base/runtime",
};
const commandEnvironment = {
  CUSTOM: "command",
  TMPDIR: "/command/tmp",
  XDG_RUNTIME_DIR: "/command/runtime",
};

test("uses the private browser runtime only for chrome-devtools commands", () => {
  const browserRuntime = "/private/tmp/browser-runtime";

  const browser = createSandboxedCommandEnvironment(
    "chrome-devtools status --sessionId agent-browser",
    browserRuntime,
    processEnvironment,
    commandEnvironment,
  );
  assert.equal(BROWSER_SESSION_ID, "agent-browser");
  assert.deepEqual(browser, {
    PATH: "/base/bin",
    CUSTOM: "command",
    TMPDIR: browserRuntime,
    XDG_RUNTIME_DIR: browserRuntime,
  });

  const ordinary = createSandboxedCommandEnvironment(
    "git status --short",
    browserRuntime,
    processEnvironment,
    commandEnvironment,
  );
  assert.deepEqual(ordinary, {
    PATH: "/base/bin",
    CUSTOM: "command",
    TMPDIR: "/command/tmp",
    XDG_RUNTIME_DIR: "/command/runtime",
  });
});
