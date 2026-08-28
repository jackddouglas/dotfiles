{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    shellInit = ''
      fish_vi_key_bindings
    '';
    interactiveShellInit = ''
      set fish_greeting # Disable greeting

      complete -c gwa -f
      complete -c gwa \
        -n 'test (count (commandline -opc)) -eq 1' \
        -a '(begin; git for-each-ref --format="%(refname:short)%09Local Branch" refs/heads; git for-each-ref --format="%(refname:lstrip=3)%09Remote Branch" refs/remotes; end 2>/dev/null | string match -rv "^HEAD\\t" | sort -u)'
      complete -c gwa \
        -n 'test (count (commandline -opc)) -eq 2; and not git show-ref --verify --quiet "refs/heads/"(commandline -opc)[2]' \
        -a '(git for-each-ref --format="%(refname:short)" refs/heads refs/remotes 2>/dev/null | string match -v "*/HEAD")' \
        -d 'base branch'
    '';
    functions.codex = {
      wraps = "codex";
      body = ''
        command codex \
          --sandbox workspace-write \
          --ask-for-approval on-request \
          --config 'approvals_reviewer="auto_review"' \
          --config 'tui.notifications=["agent-turn-complete"]' \
          --config 'tui.notification_method="bel"' \
          --config 'tui.notification_condition="always"' \
          $argv
      '';
    };
    functions.gwa = {
      description = "Add and enter a worktree under the main worktree's .wt directory";
      body = ''
        if test (count $argv) -lt 1 -o (count $argv) -gt 2
          echo "usage: gwa <branch> [base]" >&2
          return 2
        end

        git rev-parse --git-dir >/dev/null 2>&1
        or begin
          echo "gwa: not inside a Git repository" >&2
          return 1
        end

        set -l branch $argv[1]
        git check-ref-format --branch "$branch" >/dev/null 2>&1
        or begin
          echo "gwa: invalid branch name: $branch" >&2
          return 2
        end

        set -l worktrees (
          git worktree list --porcelain |
            string match -r '^worktree .+' |
            string sub -s 10
        )
        or return

        set -l target "$worktrees[1]/.wt/$branch"
        if git show-ref --verify --quiet "refs/heads/$branch"
          if test (count $argv) -eq 2
            echo "gwa: $branch already exists; a base is only used for a new branch" >&2
            return 2
          end
          git worktree add "$target" "$branch"
        else
          set -l remote_branches (git for-each-ref --format='%(refname)' "refs/remotes/*/$branch")
          if test (count $argv) -eq 1; and test (count $remote_branches) -gt 0
            git worktree add "$target" "$branch"
          else
            set -l base HEAD
            if test (count $argv) -eq 2
              set base $argv[2]
            end
            git worktree add -b "$branch" "$target" "$base"
          end
        end
        and cd "$target"
      '';
    };
    plugins = [
      {
        name = "fzf.fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair.src;
      }
      {
        name = "hydro";
        src = pkgs.fishPlugins.hydro.src;
      }
    ];
    shellAliases = {
      vim = "nvim";
      vi = "nvim";
      v = "nvim";

      l = "eza -al";
      ls = "eza -a --icons";

      pa = "pnpm add";
      pb = "pnpm build";
      pd = "pnpm dev";
      pst = "pnpm start";

      bi = "bun install";
      ba = "bun add";
      bb = "bun run build";
      bd = "bun run dev";
      bs = "bun run start";
      br = "bun run";
      bw = "bun --watch run";

      gst = "git status";
      gss = "git status --short";
      ga = "git add";
      gaa = "git add --all";
      gcam = "git commit -am";
      gcl = "git clone";
      gco = "git checkout";
      gcb = "git checkout -b";
      gsw = "git switch";
      gswc = "git switch --create";
      gf = "git fetch";
      gfa = "git fetch --all --prune";
      gb = "git branch";
      gbd = "git branch --delete";
      gd = "git diff";
      gds = "git diff --staged";
      gl = "git log --graph --oneline --decorate --all";
      glo = "git log --oneline --decorate";
      grl = "git reflog";
      gso = "git show";
      gp = "git push";
      gpl = "git pull";
      gsp = "git stash push";
      gsl = "git stash list";
      gsa = "git stash apply";
      gcp = "git cherry-pick";
      grb = "git rebase";
      grc = "git revert";
      grh = "git reset HEAD";
      grs = "git restore";
      gbl = "git blame";
      gwt = "git worktree list";
      gwd = "git worktree remove";
      gamend = "git commit --amend --no-edit";

      jst = "jj status";
      jsh = "jj show";
      je = "jj edit";
      jb = "jj bookmark";
      jbm = "jj bookmark move";
      jcl = "jj git clone --colocate";
      jfa = "jj git fetch --all-remotes";
      jf = "jj git fetch";
      jp = "jj git push";
      jn = "jj new";
      jsq = "jj squash";
      jrb = "jj rebase";
      ja = "jj abandon";

      c = "clear";

      oc = "opencode";

      # mux = "tmuxinator";

      "..." = "cd ../..";
      "...." = "cd ../../..";
    };
  };
}
