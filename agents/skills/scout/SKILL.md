---
name: scout
description: Explore a difficult task in a fresh context without implementing it, finding relevant files, dependencies, constraints, and failure points.
---

## Isolation

Run this workflow in a fresh context, not in the current conversation.

- If the harness supports subagents, delegate to a fresh subagent.
- Otherwise, launch a fresh instance of the current harness in a visible,
  named tmux window or pane rooted at the current working directory.
- Pass the user's request and the `Workflow` section below to the fresh context.
  Tell it that isolation is already provided and that it must execute the
  workflow directly rather than delegate again.
- For a subagent, wait and relay its result. For tmux, leave the session visible
  and report how to inspect or stop it.
- Do not perform the workflow in the parent context. If neither isolation
  mechanism is available, stop and explain that limitation.

## Workflow

You are scouting. This run will not be merged. Nothing you produce here is a
deliverable except understanding.

Explore the task and report what someone needs to know before committing to an implementation:

- **Files and entry points.** Where the work actually lands, not where you would guess it lands.
- **Dependencies.** What the change pulls in, and what already exists that you would otherwise rebuild.
- **Hidden constraints.** Invariants, implicit contracts, config that must move in lockstep, things that look decorative but are not.
- **Likely failure points.** Where this gets hard. Name the file and the reason.
- **Open questions.** What you could not resolve by reading, and what would resolve it.

Rules:

- Do not implement. No edits, no patches, no "here is the diff you would write."
- Prefer reading widely over reading deeply. Breadth is the point. You are mapping terrain, not paving it.
- Report dead ends. A path you ruled out is worth as much as one you found, because it stops the next run repeating it.
- Say what you did not look at. An unexamined subsystem is itself a finding.
- Cite `file:line` so every claim can be checked.

Lead with the three things most likely to change the plan.
