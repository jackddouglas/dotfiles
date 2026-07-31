import assert from "node:assert/strict";
import test from "node:test";
import sessionTask from "./session-task.ts";

type Handler = (event: any, ctx: any) => Promise<void> | void;

function deferred<T>() {
  let resolve!: (value: T) => void;
  const promise = new Promise<T>((resolvePromise) => {
    resolve = resolvePromise;
  });
  return { promise, resolve };
}

function conversation() {
  return [
    {
      type: "message",
      message: {
        role: "user",
        content:
          "Please replace deterministic session names with an intent summary.",
      },
    },
    {
      type: "message",
      message: {
        role: "assistant",
        content: [
          {
            type: "text",
            text: "I reviewed the extension and proposed naming after the first response.",
          },
        ],
      },
    },
  ];
}

function loadExtension(
  options: {
    initialName?: string;
    sessionRole?: string;
    result?: string | Promise<string>;
    error?: Error;
  } = {},
) {
  const handlers = new Map<string, Handler[]>();
  const requests: Array<{ model: any; context: any; options: any }> = [];
  const statuses: Array<{ key: string; text: string | undefined }> = [];
  const titles: string[] = [];
  const namingStarted = deferred<void>();
  const nameChanged = deferred<void>();
  let name = options.initialName;
  const previousSessionRole = process.env.PI_SESSION_ROLE;
  if (options.sessionRole === undefined) delete process.env.PI_SESSION_ROLE;
  else process.env.PI_SESSION_ROLE = options.sessionRole;

  try {
    sessionTask({
      on(event: string, handler: Handler) {
        handlers.set(event, [...(handlers.get(event) ?? []), handler]);
      },
      getSessionName() {
        return name;
      },
      setSessionName(next: string) {
        name = next;
        nameChanged.resolve();
      },
    } as any);
  } finally {
    if (previousSessionRole === undefined) delete process.env.PI_SESSION_ROLE;
    else process.env.PI_SESSION_ROLE = previousSessionRole;
  }

  const model = { provider: "openai-codex", id: "gpt-5.6-luna" };
  const provider = {
    streamSimple(requestModel: any, context: any, requestOptions: any) {
      requests.push({ model: requestModel, context, options: requestOptions });
      namingStarted.resolve();
      return {
        async result() {
          if (options.error) throw options.error;
          const title = await (options.result ??
            '"Summarize Session Naming Intent"');
          return {
            role: "assistant",
            content: [
              {
                type: "text",
                text: title,
              },
            ],
            stopReason: "stop",
          };
        },
      };
    },
  };
  const ctx = {
    ui: {
      theme: {
        fg(_color: string, text: string) {
          return text;
        },
      },
      setStatus(key: string, text: string | undefined) {
        statuses.push({ key, text });
      },
      setTitle(title: string) {
        titles.push(title);
      },
    },
    sessionManager: {
      getBranch: conversation,
      getSessionId: () => "session-id",
    },
    modelRegistry: {
      find(providerId: string, modelId: string) {
        assert.equal(providerId, "openai-codex");
        assert.equal(modelId, "gpt-5.6-luna");
        return model;
      },
      getProvider(providerId: string) {
        assert.equal(providerId, "openai-codex");
        return provider;
      },
      async getProviderAuth(providerId: string) {
        assert.equal(providerId, "openai-codex");
        return {
          auth: {
            apiKey: "oauth-token",
            headers: { authorization: "Bearer oauth-token" },
          },
          env: { OPENAI_ACCOUNT_ID: "account" },
        };
      },
    },
  };

  return {
    emit: async (event: string, data: Record<string, unknown> = {}) => {
      for (const handler of handlers.get(event) ?? []) {
        await handler({ type: event, ...data }, ctx);
      }
    },
    getName: () => name,
    requests,
    statuses,
    titles,
    namingStarted: namingStarted.promise,
    nameChanged: nameChanged.promise,
  };
}

test("marks a named subagent session in the footer", async () => {
  const extension = loadExtension({
    initialName: "Audit sandbox escapes",
    sessionRole: "subagent",
  });

  await extension.emit("session_start");
  await extension.emit("agent_start");

  assert.equal(extension.getName(), "Audit sandbox escapes");
  assert.deepEqual(extension.statuses, [
    { key: "session-role", text: "↳ subagent" },
  ]);
  assert.deepEqual(extension.titles, ["↳ Audit sandbox escapes"]);
  assert.equal(extension.requests.length, 0);
});

test("generates an unnamed session title without blocking agent startup", async () => {
  const title = deferred<string>();
  const extension = loadExtension({ result: title.promise });

  await extension.emit("session_start");
  assert.equal(extension.getName(), undefined);
  assert.equal(extension.requests.length, 0);

  let promptStarted = false;
  const promptStart = extension
    .emit("before_agent_start", {
      prompt: conversation()[0].message.content,
    })
    .then(() => {
      promptStarted = true;
    });

  await extension.namingStarted;
  await Promise.resolve();
  const startedBeforeTitle = promptStarted;

  title.resolve('"Summarize Session Naming Intent"');
  await Promise.all([promptStart, extension.nameChanged]);

  assert.equal(startedBeforeTitle, true);
  assert.equal(extension.getName(), "Summarize Session Naming Intent");
  assert.equal(extension.requests.length, 1);
  assert.deepEqual(extension.requests[0].model, {
    provider: "openai-codex",
    id: "gpt-5.6-luna",
  });
  assert.match(
    extension.requests[0].context.messages[0].content,
    /deterministic session names/,
  );
  assert.equal(extension.requests[0].options.apiKey, "oauth-token");
  assert.equal(extension.requests[0].options.reasoning, "minimal");
  assert.equal(extension.requests[0].options.maxTokens, 64);

  await extension.emit("agent_settled");
  assert.equal(extension.requests.length, 1);
});

test("preserves an existing session name without making a model request", async () => {
  const extension = loadExtension({ initialName: "Manual session name" });

  await extension.emit("session_start");
  await extension.emit("agent_start");
  await extension.emit("before_agent_start", {
    prompt: conversation()[0].message.content,
  });

  assert.equal(extension.getName(), "Manual session name");
  assert.deepEqual(extension.statuses, []);
  assert.deepEqual(extension.titles, []);
  assert.equal(extension.requests.length, 0);
});

test("falls back to a deterministic label when OAuth naming fails", async () => {
  const extension = loadExtension({ error: new Error("OAuth unavailable") });

  await extension.emit("session_start");
  await extension.emit("before_agent_start", {
    prompt: conversation()[0].message.content,
  });
  await extension.nameChanged;

  assert.equal(
    extension.getName(),
    "replace deterministic session names with an inten…",
  );
  assert.equal(extension.requests.length, 1);
});
