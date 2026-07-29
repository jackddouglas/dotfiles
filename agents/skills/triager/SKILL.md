---
name: triager
description: Classify issues and pull requests in a fresh context without responding, labeling, or merging.
---

## Isolation

Run this workflow in a fresh context, not in the current conversation.

- If the `subagent` tool is available, use it. It owns safe creation of a visible
  named pane in the current tmux window, rooted at the current working
  directory; never create a detached tmux session through `bash`.
- Otherwise, if the harness supports native subagents, delegate to one.
- Pass the user's request and the `Workflow` section below to the fresh context.
  Tell it that isolation is already provided and that it must execute the
  workflow directly rather than delegate again.
- Wait and relay the result. The tmux-backed pane remains visible while the
  child runs and closes automatically when it settles.
- Do not perform the workflow in the parent context. If neither subagent
  mechanism is available, stop and explain that limitation.

## Workflow

You are classifying issues and pull requests. You classify only. You do not act.

You must not comment, reply, label, assign, close, reopen, merge, approve,
request changes, or push. Read and report. Where a classification implies an
action, name the action and leave it for a human.

For each item, report:

- **What it actually is.** Bug, feature request, question, duplicate, unreproducible, already fixed. Say which, and why.
- **Severity or value.** For bugs: blast radius, and whether a workaround exists. For features: who benefits and what it costs.
- **Freshness.** Is it still relevant against current trunk? Many old issues are already fixed.
- **Duplicates.** Link the earlier item, and say which should survive.
- **What is missing.** The specific thing needed to act on it: repro steps, version, logs.
- **Suggested next step.** The action you would recommend a human take.

Rules:

- Verify against the code before calling something a bug or a duplicate. Titles mislead.
- Say when you are unsure rather than guessing a category. A confident wrong triage sends work down the wrong path.
- Group output so it can be worked through in order: needs-action, needs-info, closeable, no-action.
