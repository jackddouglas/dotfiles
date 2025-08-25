{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    package = pkgs.unstable.yazi;
    enableFishIntegration = true;

    plugins = {
      git =
        pkgs.fetchFromGitHub {
          owner = "yazi-rs";
          repo = "plugins";
          rev = "HEAD";
          hash = "sha256-29K8PmBoqAMcQhDIfOVnbJt2FU4BR6k23Es9CqyEloo=";
        }
        + "/git.yazi";
      piper =
        pkgs.fetchFromGitHub {
          owner = "yazi-rs";
          repo = "plugins";
          rev = "HEAD";
          hash = "sha256-29K8PmBoqAMcQhDIfOVnbJt2FU4BR6k23Es9CqyEloo=";
        }
        + "/piper.yazi";
    };

    initLua = ''
      require("git"):setup()
    '';

    settings = {
      plugin = {
        prepend_previewers = [
          {
            name = "*.tar*";
            run = "piper --format=url -- bash -c \"tar tf '$1'\"";
          }
          {
            name = "*.csv";
            run = "piper -- bash -c \"bat -p --color=always '$1'\"";
          }
          {
            name = "*.md";
            run = "piper -- bash -c \"CLICOLOR_FORCE=1 glow -w=$w -s=dark '$1'\"";
          }
        ];
        prepend_fetchers = [
          {
            id = "git";
            name = "*";
            run = "git";
          }
          {
            id = "git";
            name = "*/";
            run = "git";
          }
        ];
      };
    };

    theme = {
      flavor = {
        dark = "taake";
      };
    };
  };
}
