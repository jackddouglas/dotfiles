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
      };

      signing = {
        behavior = "own";
        backend = "ssh";
        key = currentSigningKey;
      };

      git = {
        colocate = true;
        push-new-bookmarks = true;
      };

      fix = {
        tools = {
          biome = {
            enabled = false;
            command = [
              "biome"
              "check"
              "--stdin-file-path=$path"
              "--write"
            ];
            patterns = [
              "glob:'**/*.js'"
              "glob:'**/*.jsx'"
              "glob:'**/*.ts'"
              "glob:'**/*.tsx'"
              "glob:'**/*.json'"
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
              "glob:'**/*.ts'"
              "glob:'**/*.tsx'"
              "glob:'**/*.json'"
              "glob:'**/*.html'"
              "glob:'**/*.md'"
              "glob:'**/*.css'"
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
