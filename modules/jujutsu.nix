{ currentSigningKey, ... }:
{
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        email = "cincomc@proton.me";
        name = "Jack D. Douglas";
      };

      ui = {
        default-command = [ "log" ];
        editor = "nvim";
        conflict-marker-style = "git";
      };

      signing = {
        behavior = "own";
        backend = "ssh";
        key = currentSigningKey;
      };

      git = {
        colocate = true;
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
