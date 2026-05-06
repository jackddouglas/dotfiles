# Global Instructions

## Environment

- macOS (Apple Silicon), nix-darwin + home-manager
- Shell: fish
- Editor: neovim
- VCS: git
- Terminal: ghostty
- Secrets: 1Password CLI (`op`)
- Package manager: nix (prefer nix-idiomatic solutions)

## Preferences

- No emojis in code, commits, or output
- Use `nix fmt` / `nixfmt` for nix files
- Keep things minimal and explicit

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
