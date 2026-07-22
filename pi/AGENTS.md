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
