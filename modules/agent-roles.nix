{ lib, ... }:
# Agent roles and commands, authored once and emitted for Claude, Codex, and OpenCode.
#
# Prose lives in ../agents/{roles,commands}/<name>.md and is shared verbatim.
# Everything that differs between harnesses -- frontmatter dialect, whether
# frontmatter is parsed at all, how a subagent is dispatched -- is generated here.
let
  inherit (lib)
    concatStringsSep
    hasInfix
    mapAttrs
    mapAttrsToList
    optional
    optionalAttrs
    ;

  rolesDir = ../agents/roles;
  commandsDir = ../agents/commands;

  # Tool posture, expressed per harness. Codex has no per-prompt permission
  # model, so there the posture is carried by the prose alone.
  postures = {
    read = {
      claudeTools = "Read, Grep, Glob, Bash";
      opencode = {
        edit = "deny";
        bash = "allow";
        webfetch = "deny";
      };
    };
    research = {
      claudeTools = "Read, Grep, Glob, Bash, WebSearch, WebFetch";
      opencode = {
        edit = "deny";
        bash = "allow";
        webfetch = "allow";
      };
    };
    write = {
      claudeTools = null; # inherit every tool
      opencode = {
        edit = "allow";
        bash = "allow";
        webfetch = "allow";
      };
    };
  };

  # isolation:
  #   dispatch - runs as a subagent in a fresh context and reports back
  #   worktree - runs here, but builds in a throwaway git worktree
  #   session  - runs in the current session
  roles = {
    scout = {
      description = "Explore a difficult task with no intention of merging. Finds relevant files, dependencies, hidden constraints and likely failure points.";
      isolation = "dispatch";
      posture = "read";
      argumentHint = "<task>";
    };
    researcher = {
      description = "Survey libraries, APIs or unfamiliar subsystems and produce a cited technical brief.";
      isolation = "dispatch";
      posture = "research";
      argumentHint = "<topic>";
    };
    prototyper = {
      description = "Produce a disposable implementation, in a throwaway worktree, that reveals what is actually wanted.";
      isolation = "worktree";
      posture = "write";
      argumentHint = "<idea>";
    };
    implementer = {
      description = "Execute a sufficiently specified, reviewable change.";
      isolation = "session";
      posture = "write";
      argumentHint = "<change>";
    };
    reviewer = {
      description = "Inspect a diff from a fresh context for correctness, unnecessary dependencies, duplicated logic and violated invariants.";
      isolation = "dispatch";
      posture = "read";
      argumentHint = "[diff or branch]";
    };
    triager = {
      description = "Classify issues and pull requests. Does not respond, label or merge.";
      isolation = "dispatch";
      posture = "read";
      argumentHint = "[issue or PR]";
    };
  };

  commands = {
    explain = {
      description = "Use when the user asks for a rich explanation of a code change, diff, branch, or PR. Produces HTML output.";
      isolation = "session";
      posture = "write";
      argumentHint = "[change]";
    };
    clean-branch = {
      description = "Reimplement the current branch with a clean, narrative commit history.";
      isolation = "session";
      posture = "write";
      argumentHint = "[new bookmark name]";
    };
  };

  entries =
    mapAttrs (n: v: v // { body = builtins.readFile (rolesDir + "/${n}.md"); }) roles
    // mapAttrs (n: v: v // { body = builtins.readFile (commandsDir + "/${n}.md"); }) commands;

  isDispatch = e: e.isolation == "dispatch";

  fm = lines: ''
    ---
    ${concatStringsSep "\n" lines}
    ---
  '';

  # Bodies that already place $ARGUMENTS themselves keep control of it.
  withTask =
    body:
    if hasInfix "$ARGUMENTS" body then
      body
    else
      ''
        ${body}
        ## Task

        $ARGUMENTS
      '';

  dispatchTask = ''
    ## Task

    $ARGUMENTS
  '';

  claudeAgent =
    name: e:
    fm (
      [
        "name: ${name}"
        "description: ${e.description}"
      ]
      ++
        optional (postures.${e.posture}.claudeTools != null)
          "tools: ${postures.${e.posture}.claudeTools}"
    )
    + "\n"
    + e.body;

  claudeCommand =
    name: e:
    fm [
      "description: ${e.description}"
      "argument-hint: ${e.argumentHint}"
    ]
    + "\n"
    + (
      if isDispatch e then
        ''
          Run this as an isolated subagent so its exploration stays out of this session.

          Use the Agent tool with `subagent_type: "${name}"`, passing the task below as its brief.
          Report back what it found. Do not do the work yourself.

        ''
        + dispatchTask
      else
        withTask e.body
    );

  opencodeAgent =
    name: e:
    let
      p = postures.${e.posture}.opencode;
    in
    fm [
      "description: ${e.description}"
      "mode: subagent"
      "temperature: 0.1"
      "permission:"
      "  edit: ${p.edit}"
      "  bash: ${p.bash}"
      "  webfetch: ${p.webfetch}"
    ]
    + "\n"
    + e.body;

  opencodeCommand =
    name: e:
    fm ([ "description: ${e.description}" ] ++ optional (isDispatch e) "agent: ${name}")
    + "\n"
    + (if isDispatch e then dispatchTask else withTask e.body);

  # Codex does not parse prompt frontmatter, so none is emitted.
  codexPrompt =
    name: e:
    if isDispatch e then
      ''
        Delegate this to a subagent. This instruction is itself the explicit delegation
        request that `spawn_agent` requires, so its gate is satisfied.

        1. `spawn_agent` with `task_name: "${name}"` and `fork_turns: "none"`, so it starts
           from a clean context.
        2. Send it the brief below, followed by the task.
        3. `wait` for it, then `close_agent`.
        4. Report what it found. Do not do the work yourself.

        If `spawn_agent` is unavailable, do the work here under the same brief.

        ---

      ''
      + withTask e.body
    else
      withTask e.body;

  mkFiles =
    name: e:
    {
      ".claude/commands/${name}.md".text = claudeCommand name e;
      ".config/opencode/commands/${name}.md".text = opencodeCommand name e;
      ".codex/prompts/${name}.md".text = codexPrompt name e;
    }
    // optionalAttrs (isDispatch e) {
      ".claude/agents/${name}.md".text = claudeAgent name e;
      ".config/opencode/agent/${name}.md".text = opencodeAgent name e;
    };
in
{
  home.file = builtins.foldl' (a: b: a // b) { } (mapAttrsToList mkFiles entries);
}
