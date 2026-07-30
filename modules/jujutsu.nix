{ signingKeyFile, ... }:
{
  xdg.configFile."jjui/config.toml".text = ''
    [preview]
    revision_command = ["--config", "ui.diff-formatter=\"difft\"", "show", "--color=always", "-r", "$change_id"]
    oplog_command    = ["--config", "ui.diff-formatter=\"difft\"", "op", "show", "--color=always", "$operation_id"]
    file_command     = ["--config", "ui.diff-formatter=\"difft\"", "diff", "--color=always", "-r", "$change_id", "$file"]

    [ui.colors]
    selected = { fg = "cyan", bg = "bright black" }
  '';

  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        email = "jack@jackddouglas.com";
        name = "Jack D. Douglas";
      };

      ui = {
        default-command = [ "log" ];
        editor = "nvim";
        conflict-marker-style = "git";
        pager = [ "pager" ];
        diff-formatter = ":git";
        diff-editor = [
          "nvim"
          "-c"
          "DiffEditor $left $right $output"
        ];
      };

      signing = {
        behavior = "own";
        backend = "ssh";
        key = signingKeyFile;
      };

      git = {
        colocate = true;
      };

      merge-tools.difft = {
        diff-args = [
          "--color=always"
          "--display=inline"
          "$left"
          "$right"
        ];
      };

      remotes = {
        origin.auto-track-bookmarks = "glob:*";
      };

      aliases = {
        tug = [
          "bookmark"
          "move"
          "--from"
          "heads(::@- & bookmarks())"
          "--to"
          "@-"
        ];
      };

      fix = {
        tools = {
          biome = {
            command = [
              "biome"
              "format"
              "--stdin-file-path"
              "$path"
              "--write"
            ];
            patterns = [
              "glob:'**/*.js'"
              "glob:'**/*.jsx'"
              "glob:'**/*.mjs'"
              "glob:'**/*.cjs'"
              "glob:'**/*.ts'"
              "glob:'**/*.tsx'"
              "glob:'**/*.mts'"
              "glob:'**/*.cts'"
              "glob:'**/*.d.ts'"
              "glob:'**/*.json'"
              "glob:'**/*.jsonc'"
              "glob:'**/*.html'"
              "glob:'**/*.css'"
            ];
          };

          prettier = {
            enabled = false;
            command = [
              "prettier"
              "--stdin-filepath"
              "$path"
            ];
            patterns = [
              "glob:'**/*.js'"
              "glob:'**/*.jsx'"
              "glob:'**/*.mjs'"
              "glob:'**/*.cjs'"
              "glob:'**/*.ts'"
              "glob:'**/*.tsx'"
              "glob:'**/*.mts'"
              "glob:'**/*.cts'"
              "glob:'**/*.d.ts'"
              "glob:'**/*.json'"
              "glob:'**/*.jsonc'"
              "glob:'**/*.html'"
              "glob:'**/*.md'"
              "glob:'**/*.css'"
              "glob:'**/*.yaml'"
              "glob:'**/*.yml'"
            ];
          };

          rustfmt = {
            command = [
              "rustfmt"
              "--emit"
              "stdout"
              "--edition"
              "2024"
            ];
            patterns = [ "glob:'**/*.rs'" ];
          };
        };
      };
    };
  };
}
