{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    shellInit = ''
      fish_vi_key_bindings
    '';
    interactiveShellInit = ''
      set fish_greeting # Disable greeting
    '';
    plugins = [
      {
        name = "fzf.fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
      {
        name = "forgit";
        src = pkgs.fishPlugins.forgit.src;
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

      pi = "pnpm install";
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
      gaa = "git add --all";
      gcam = "git commit -am";
      gcl = "git clone";

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

      mux = "tmuxinator";

      "..." = "cd ../..";
      "...." = "cd ../../..";
    };
  };
}
