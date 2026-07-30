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

# Dropping the superpowers plugin

## Goal

Stop running the upstream `superpowers` plugin alongside our fork of it, and close the coverage gap the fork leaves behind.

## Findings

- The installed `superpowers@claude-plugins-official` v6.2.0 *is* obra/superpowers; `plugin.json` names the repo and author. Our skills are already adapted from it, so this was fork vs. upstream, not adopt vs. skip.
- Both were loading at once, producing five duplicate pairs (`systematic-debugging`, `test-driven-development`, `receiving-code-review`, `verification-before-completion`, `writing-plans`) with near-identical descriptions competing for selection.
- Our fork is 3-5x tighter for the same content: ~6,900 words over 16 skills against upstream's 40,125 over 14.
- **Codex does discover `~/.agents/skills`.** A `strings` sweep of the binary only surfaced `$CODEX_HOME/skills`, which is where Codex's bundled skill-*installer* writes; that is not the full discovery path set. Session rollouts under `~/.codex/sessions/` show Codex enumerating our skills resolved through `~/.agents/skills` into `/nix/store/...-hm_implementer/SKILL.md` and friends. Do not project into `~/.codex/skills` as well: Codex reads both and would list every skill twice.

## Plan

- [x] Port `brainstorming`, the one genuine gap, merging in the pre-implementation rituals from `claude/practices/finding-unknowns.md` (blindspot pass, divergent prototypes, interview).
- [x] Port `dispatching-parallel-agents`, compressed, to give the existing fresh-context roles an orchestrator.
- [x] Remove `superpowers@claude-plugins-official` from `enabledPlugins` in `claude/settings.json`.
- [x] Generalize `browser-testing` beyond Pi so Claude Code and Codex can use it.

## Deviations

- **Ported `brainstorming` offers rather than gates.** Upstream opens with a HARD-GATE forbidding any implementation action until a design is approved, "regardless of perceived simplicity". That contradicts `CLAUDE.md` ("offer these, don't impose them"), so the port proposes approaches and names rejected alternatives without blocking. Known risk: it may get skipped exactly when it would have helped. Revisit if that happens.
- **Skipped four upstream skills as already covered:** `executing-plans` (`implementer`), `requesting-code-review` (`reviewer`), `subagent-driven-development` (`implementer` + `writing-plans` + the roles), `using-superpowers` (bootstrap, dies with the plugin). `finishing-a-development-branch` and `using-git-worktrees` are partially covered by `clean-branch` and `prototyper` and were deliberately left alone.
- **Generated the `home.file` entries instead of enumerating them.** Two harness directories x 18 skills is 36 hand-maintained lines; `agentSkills` + `agentSkillFiles` makes adding a skill a one-word change. Whole-directory symlinks remain off the table for the reason recorded above.
- **`browser-testing` now branches on `PI_BROWSER_RUNTIME_DIR`.** When Pi's sandbox extension is present it still owns daemon startup and verification. Otherwise the skill starts the daemon itself with the same flags the extension uses (`pi/extensions/sandbox/index.ts:34`), on a stable runtime directory under `TMPDIR` so successive shell calls reconnect. Verified by hand: a self-started daemon's `args=` line sorts equal to `EXPECTED_BROWSER_DAEMON_ARGS` (`index.ts:42`), navigation plus snapshot works, and `file:///etc/hosts` is refused by the blocklist.
- Two agent sessions sharing one runtime directory would fight over the daemon. The skill tells the model to vary `CDP_SESSION_ID` in that case; it does not enforce it.

## Verification

- `nix build 'path:.#darwinConfigurations.laptop.system' --no-link` exits 0.
- The built `home-manager-files` tree carries all 18 skills under each of `.agents/skills`, `.claude/skills`, and `.codex/skills`.
- `agentSkills` diffs clean against `ls agents/skills/`; every `SKILL.md` frontmatter `name` matches its directory.
- `nixfmt home.nix` and `git diff --check` are clean.
