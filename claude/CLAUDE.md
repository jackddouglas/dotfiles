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

## Describing changes

- Use `jj describe -m "..."` to set the message on the current change; use `jj commit -m "..."` to describe and start a new empty change
- Do not invoke `git commit` in a jj-managed (colocated) repo
- Inspect history with `jj log` / `jj diff` rather than `git log` / `git diff`

## Commit messages

- Use [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): subject`
- Common types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `perf`, `build`, `ci`, `style`
- Scope is the crate, package, or area of work (infer from git history when unclear)
- Subject in imperative mood, lowercase, no trailing period
- Keep the subject under ~72 characters; put detail in the body

## Formatting

- Inline code uses single backticks: `foo`
- Block code uses triple backticks with a language tag when applicable:

  ```fish
  echo hello
  ```
