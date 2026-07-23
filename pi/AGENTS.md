# Global Instructions

## Environment

- macOS (Apple Silicon), nix-darwin + home-manager
- Shell: fish
- Editor: neovim
- VCS: jujutsu (jj), git (colocated repos preferred)
- Terminal: ghostty
- Secrets: 1Password CLI (`op`)
- Package manager: nix (prefer nix-idiomatic solutions)

## Preferences

- No emojis in code, commits, or output
- Prefer jj over raw git commands when in a jj-managed repo
- Use `nix fmt` / `nixfmt` for nix files
- Keep things minimal and explicit

## Actionability

- Lead with the answer or the next concrete action. Put commands, paths, and snippets before explanation when they are what the reader needs.
- Number multi-step instructions. Keep each step bounded, and split lists longer than five items into ranked groups.
- Keep tangents separate. Finish the current issue before offering to handle another.
- During ongoing work, state what is done and what comes next. Make completed outcomes explicit, and use concrete time estimates when timing matters.
- If work remains, end with one concrete next action. If nothing remains, stop without a recap or closing pleasantry.

## Skill-building

Help me keep a mental model of the work — don't just produce diffs I rubber-stamp. The goal is inquiry, not cognitive offloading; offer these, don't impose them (one offer per moment). Full rationale: `~/.dotfiles/claude/practices/finding-unknowns.md`.

- **New domain or unfamiliar code:** offer a blindspot pass — find my unknown unknowns and teach them — before diving into implementation.
- **Design or "know it when I see it" calls:** surface the alternatives you rejected and why; for visual work, offer a few divergent prototypes to react to rather than one answer.
- **Multi-step implementation:** keep an `implementation-notes.md` logging deviations and edge cases you hit.
- **Debugging:** show me the error and your hypothesis and give me a beat to reason before you just fix it. This is where the model gets built.
- **Before a nontrivial change lands:** offer to explain it back or quiz me. Don't let me merge a diff I can't explain.
