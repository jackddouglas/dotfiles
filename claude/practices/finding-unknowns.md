# Finding Your Unknowns

How to work with a coding agent so it builds my skill instead of eroding it.

## The thesis

Using an agent doesn't decide whether I learn — *how I interact with it* does. Interrogating it to understand builds a mental model; delegating the thinking ("cognitive offloading") hollows one out. Every ritual below exists to keep me in inquiry mode, sorted by which kind of ignorance I'm attacking.

## Why this matters (the evidence)

Anthropic's RCT (52 junior engineers learning Trio): the AI-assisted group scored **50%** on a comprehension quiz vs **67%** hand-coding — nearly two letter grades, p=0.01 — while finishing only ~2 minutes faster (not significant). Two details carry the lesson:

1. **The largest gap was on debugging** — understanding *why* code fails degraded most.
2. **Interaction pattern predicted the outcome, not AI access.** High scorers used *generation-then-comprehension* (generate, then ask clarifying/conceptual follow-ups) and *conceptual inquiry* (ask concepts, resolve their own errors). Low scorers offloaded.

The productivity win was noise; the comprehension loss was real. But the loss was a choice about interaction, not an inevitability.

Source: <https://www.anthropic.com/research/AI-assistance-coding-skills>

## The frame: four unknowns → three goals

The map (my prompt, context, skills) is not the territory (the codebase, the real constraints). The gap between them is my **unknowns**, and managing them is a skill of agentic coding — one that compounds.

- **Known knowns** — what's already in my prompt.
- **Known unknowns** → **architecture understanding.** Questions I know I haven't resolved.
- **Unknown knowns** → **taste.** "Know it when I see it" — criteria I can't articulate until I react.
- **Unknown unknowns** → **mental model of the domain.** What I haven't even considered.

## Rituals, by phase

Pick by which unknown I'm facing. Don't run all of them every time.

### Pre-implementation

- **Blindspot pass** (unknown unknowns): "I'm adding X but know nothing about this area — do a blindspot pass, find my unknown unknowns and teach them so I can prompt you better." The direct antidote to the study's failure mode: it manufactures the questions before I'm in a position to rubber-stamp answers.
- **Brainstorm / divergent prototypes** (unknown knowns / taste): "Make one HTML page with 4 wildly different directions so I can react." I can't specify what I want, so I build taste by judging alternatives. Start most sessions with a brainstorm to set scope with intent.
- **Interview** (known unknowns): "Interview me one question at a time, prioritize questions where my answer would change the architecture."
- **References**: the best reference is source code. Point the agent at a folder/module whose behavior I want, even in another language, and have it reimplement the semantics.
- **Implementation plan**: "Lead with the decisions I'm most likely to tweak — data model, type interfaces, UX flows. Bury mechanical refactoring at the bottom."

### During implementation

- **Implementation notes**: keep an `implementation-notes.md` logging deviations and edge cases hit. This is where the debugging knowledge — the study's sharpest loss — lives; reading it back recovers the instructive failures offloading would delete.
- **Protect debugging**: when something fails, read the error and form a hypothesis *before* asking the agent to fix it. Let it confirm or explain; don't let it silently erase the failure. This is where the model gets built.

### Before it lands

- **Quiz** (generation-then-comprehension, enforced): "Give me an HTML report on this change with context and intuition, and a quiz at the bottom I must pass." Merge only after passing. This is the study's winning pattern promoted to a gate — don't accept a diff I can't explain back.
- **Pitch / explainer**: package spec + prototype + notes into one doc for buy-in when others start with the same unknowns I did.

## The discriminator

Every ritual here can collapse back into offloading — skim the blindspot pass, cheat the quiz, let the agent answer its own interview. Then I've reproduced the 50% group with extra steps. The active ingredient never changes:

**I do the cognitive work; the agent structures and accelerates it.**

The test for any exercise: did it cost me a real judgment, or did I just nod at the agent's? The artifacts are scaffolds for inquiry, not substitutes for it.
