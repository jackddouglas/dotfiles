---
name: journal
description: Use when appending a captured decision, design, or open question to Jack's Obsidian daily note — after he accepts a journal nudge, or when he runs /journal directly.
---

# Journal

Append a factual draft of what just happened to today's note in the JDD vault, marked off
from Jack's own prose so he can rewrite it in his voice later.

You supply facts. He supplies tone. Do not imitate his voice.

## Path

`~/Library/Mobile Documents/iCloud~md~obsidian/Documents/JDD/40 calendar/YYYY-MM-DD.md`

Local date. Create it empty if absent — the vault's daily-notes config sets a folder and no
template, so an empty file is exactly what Obsidian itself would make.

## Before writing

Read the file first. You are appending to a live document that is probably open in Obsidian.

Check which concept notes exist before linking:

```bash
ls ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/JDD/*.md
```

Link only to notes that already exist. Never invent a `[[link]]` — orphans litter the graph.

## Format

```markdown
> [!robot]- claude · 14:32 · tonk/runtime
> **Decision:** single-branch FAB on profile `meta`.
> **Rejected:** branch-addressable bridge — every call becomes an
> authorization surface; loses `tonk-display`.
> **Turned on:** Phase 2 is a closed set; a general routing layer
> doesn't earn its keep against that.
> **Open:** no automatic re-stamp.
```

Header is `claude · HH:MM · <repo>/<area>`. Local time. Take repo/area from cwd — the vault
spans projects, so say which one this came from.

The trailing `-` in `[!robot]-` is what makes it fold. Keep it.

Fields — use only the ones that apply, never pad:

| Field | Holds |
|---|---|
| `Decision:` | what was settled |
| `Rejected:` | the alternative, and why it lost |
| `Turned on:` | the hinge — what actually decided it |
| `Built:` | what landed |
| `Open:` | loose ends |
| `Discuss:` | needs a conversation |

## What to capture

The reasoning, not just the conclusion. The conclusion survives on its own; why the
alternative lost is the part that's gone by evening. If something was rejected, say what
rejecting it cost.

Be specific. Name the file, the branch, the function. "Fixed the render bug" is worthless in
a month. "The guard was a `data-` attribute and `cloneNode` drops it" is the entry.

## Rules

- Append-only. Read, then add to the end. Never touch, reflow, or reorder his prose.
- Precede the callout with `---` only if the file is non-empty.
- Several moments in a day accumulate as separate timestamped callouts, in order.
- Never write unprompted. He has to say yes.
- Report the path after writing.
