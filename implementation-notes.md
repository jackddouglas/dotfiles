# Portable workflow skills

## Goal

Replace the generated and harness-specific workflow files with one portable Agent Skills implementation shared by Claude Code, Codex, OpenCode, and Pi.

## Plan

- [x] Package every workflow, including `simplify`, as a standard `agents/skills/<name>/SKILL.md` skill.
- [x] Keep workflow prose and dispatch instructions independent of harness names, tools, invocation syntax, and argument placeholders.
- [x] Give fresh-context workflows a capability-based isolation rule: use a subagent when available, otherwise launch the current harness in a visible tmux window or pane.
- [x] Prevent recursive delegation by passing only the skill's `Workflow` section to the isolated worker.
- [x] Install the canonical skills under `~/.agents/skills` for Codex, OpenCode, and Pi, and project the same sources into `~/.claude/skills` for Claude Code.
- [x] Remove the generated module, native workflow commands and agents, deprecated Codex prompts, and Pi-only workflow prompts and references.

## Constraints

- Preserve the unrelated local edits in `codex/hooks.json`, `modules/fish.nix`, and `modules/tmux.nix`.
- Keep the existing OpenCode `debug` and `docs` agents.
- Do not manage the whole `~/.agents/skills` or `~/.claude/skills` directory, because both contain unrelated externally installed skills.

## Verification

- Validate each skill's frontmatter, directory name, and inventory.
- Check that portable skills contain no harness-specific dispatch tools, command syntax, or argument placeholders.
- Run `nixfmt home.nix`, `git diff --check`, and `nix build 'path:.#darwinConfigurations.laptop.system' --no-link`.
