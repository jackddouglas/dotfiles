---
name: journal
description: Use when appending a captured decision, design, or open question to Jack's Obsidian daily note — after he accepts a journal nudge, or when he invokes the journal directly.
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
> [!robot]- <agent> · 14:32 · tonk/runtime
> The FAB now hangs off profile `meta` as a single branch. The alternative was a
> branch-addressable bridge, and it lost on authorization surface — every call through it
> becomes something that has to be checked, and it drops `tonk-display` on the way. What
> actually decided it was that Phase 2 is a closed set: a general routing layer has nothing
> to route that a single branch doesn't already reach, so it never earns its cost.
>
> Still open: nothing re-stamps automatically.
```

Header is `<agent> · HH:MM · <repo>/<area>`. Use the lowercase agent name (`claude`, `codex`,
`opencode`, or `pi`) and local time. Take repo/area from cwd — the vault spans projects, so
say which one this came from.

The trailing `-` in `[!robot]-` is what makes it fold. Keep it.

## How to write it

Prose. Full sentences, connected by their logic — not labelled fields, not a bullet list, not
bold lead-ins standing in for headings. One paragraph is usually right; two if there's a
genuine second thread. Every line of the callout stays prefixed with `> `.

The point of prose here is that it forces the connective tissue. A field labelled `Rejected:`
lets you name the alternative without saying what its rejection cost. A sentence doesn't —
"it lost on X, which means giving up Y" has to state the link. That link is the part worth
keeping.

Write the reasoning, not just the conclusion. The conclusion survives on its own; why the
alternative lost is what's gone by evening.

Be specific. Name the file, the branch, the function. "Fixed the render bug" is worthless in
a month. "The guard was a `data-` attribute and `cloneNode` drops it" is the entry.

Keep it short. Longform means connected, not padded — three or four sentences that carry
their own weight beat a page of throat-clearing. If there's a loose end, close with it in a
sentence rather than a field.

Still facts, not voice. Prose is not an invitation to flourish — don't imitate him, and don't
reach for style to fill out a paragraph.

## Rules

- Append-only. Read, then add to the end. Never touch, reflow, or reorder his prose.
- Precede the callout with `---` only if the file is non-empty.
- Several moments in a day accumulate as separate timestamped callouts, in order.
- Never write unprompted. He has to say yes.
- Report the path after writing.
