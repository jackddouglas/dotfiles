{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  signingKeyFile = "/Users/jackdouglas/.ssh/id_ed25519";

  ice-app = pkgs.stdenvNoCC.mkDerivation {
    pname = "ice";
    version = "0.11.13-dev.2";

    src = pkgs.fetchurl {
      url = "https://github.com/jordanbaird/Ice/releases/download/0.11.13-dev.2/Ice.zip";
      sha256 = "c1bbaa71f61ebfe5ee928f790af60963a9f202364d63f78d2c6b3ec5105cf4a0";
    };

    nativeBuildInputs = [ pkgs.unzip ];

    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out/Applications
      cp -r Ice.app $out/Applications/
    '';
  };

  flexoki-typora-src = pkgs.fetchFromGitHub {
    owner = "guidovicino";
    repo = "flexoki-typora";
    rev = "5d86c9846f7441e491f0db263f938c302eebcd6e";
    hash = "sha256-qLmdPmVTE8Dud4rcvn6WPQuTQ5sQp7GfxteyLuWcek4=";
  };

  flexoki-typora-css = pkgs.runCommandLocal "flexoki-light.css" { } ''
    sed -e 's/"JetBrainsMono Nerd Font"/"Berkeley Mono"/' \
      ${flexoki-typora-src}/flexoki-light.css > $out
  '';

  chrome-devtools-cli = pkgs.stdenvNoCC.mkDerivation {
    pname = "chrome-devtools-cli";
    version = "1.6.0";

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/chrome-devtools-mcp/-/chrome-devtools-mcp-1.6.0.tgz";
      hash = "sha256-HmMsLZcUtPgrTPq077nOV1CFx1/+XpdyODEprwEsnIQ=";
    };

    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.python3
    ];
    sourceRoot = "package";

    installPhase = ''
      runHook preInstall

      python3 - <<'PY'
      from pathlib import Path

      path = Path("build/src/bin/chrome-devtools.js")
      source = path.read_text()
      old = """            if (response.success) {
                      console.log(await handleResponse(JSON.parse(response.result), argv['output-format']));
                  }
      """
      new = """            if (response.success) {
                      const toolResponse = JSON.parse(response.result);
                      const rendered = await handleResponse(toolResponse, argv['output-format']);
                      if (toolResponse.isError) {
                          console.error(rendered);
                          process.exitCode = 1;
                      }
                      else {
                          console.log(rendered);
                      }
                  }
      """
      if old not in source:
          raise SystemExit("chrome-devtools MCP error patch no longer applies")
      path.write_text(source.replace(old, new))

      path = Path("build/src/daemon/utils.js")
      source = path.read_text()
      old = """        catch {
                  // Process is dead, stale PID file. Proceed with startup.
              }
      """
      new = """        catch (error) {
                  if (error?.code === 'EPERM' && fs.existsSync(getSocketPath(sessionId))) {
                      return true;
                  }
                  // Process is dead, stale PID file. Proceed with startup.
              }
      """
      if old not in source:
          raise SystemExit("chrome-devtools cross-sandbox daemon patch no longer applies")
      path.write_text(source.replace(old, new))
      PY

      mkdir -p $out/bin $out/libexec/chrome-devtools
      cp -R . $out/libexec/chrome-devtools
      makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/chrome-devtools \
        --add-flags "$out/libexec/chrome-devtools/build/src/bin/chrome-devtools.js" \
        --set CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS 1 \
        --set CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS 1

      runHook postInstall
    '';
  };

  ori = pkgs.stdenvNoCC.mkDerivation {
    pname = "ori";
    version = "0.7.1+6fb9ea6";

    src = pkgs.fetchurl {
      url = "https://github.com/OpenRouterLabs/ori-releases/releases/download/cli-0.7.1-6fb9ea6/ori-darwin-arm64";
      hash = "sha256-E+aY9hVDBfHfSUw+aQK74wDwojOE0N44kAHSXt0H8Gg=";
    };

    dontUnpack = true;
    # Stripping would rewrite the Mach-O and invalidate both the ad-hoc
    # signature and the JS payload Bun appends to the executable.
    dontStrip = true;

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall

      install -Dm755 $src $out/libexec/ori
      makeWrapper $out/libexec/ori $out/bin/ori \
        --set ORI_NO_UPDATE_CHECK 1

      runHook postInstall
    '';
  };

  agentSkills = [
    "browser-testing"
    "code-review"
    "codebase-design"
    "diagnosing-bugs"
    "discuss"
    "domain-modeling"
    "explain"
    "grill-with-docs"
    "improve-codebase-architecture"
    "product-description"
    "prototype"
    "scout"
    "writing-plans"
  ];

  agentSkillFiles = lib.listToAttrs (
    lib.concatMap (
      skill:
      map
        (dir: {
          name = "${dir}/${skill}";
          value.source = ./agents/skills + "/${skill}";
        })
        [
          ".agents/skills"
          ".claude/skills"
        ]
    ) agentSkills
  );
in
{
  home = {
    username = "jackdouglas";
    homeDirectory = "/Users/jackdouglas";

    stateVersion = "26.05";

    packages = with pkgs; [
      # window management
      ice-app

      # dev tools
      awscli2
      cocoapods
      difftastic
      docker
      docker-compose
      jjui
      lazydocker
      lazygit
      neovim
      ngrok
      nvimpager
      ori
      pm2
      uv
      yarn

      # nix
      nixd
      nixfmt
      statix

      # haskell
      ghc
      haskell-language-server
      stack

      # rust
      rustup

      # ethereum
      foundry

      # languages/runtimes/compilers
      gcc
      libiconv

      # node
      nodejs_22
      pnpm
      tsx

      # system utils
      _1password-cli
      btop
      dust
      eza
      fd
      ffmpeg
      glow
      iina
      imagemagick
      itsycal
      jq
      mosh
      mprocs
      rclone
      ripgrep
      wget
      xz
      yt-dlp

      # communication
      slack
      telegram-desktop
      zoom-us

      # fonts
      ia-writer-quattro
      inter
      lilex
      nerd-fonts.symbols-only

      # fun
      cmatrix
    ];

    file = {
      ".hushlogin".source = ./hushlogin/.hushlogin;
      ".local/bin/chrome-devtools".source = "${chrome-devtools-cli}/bin/chrome-devtools";
      ".config/nvim".source = ./nvim;
      ".config/tmuxinator".source = ./tmuxinator;
      "Library/Application Support/com.mitchellh.ghostty/config".source = ./ghostty/config;
      "Library/Application Support/abnerworks.Typora/themes/flexoki-light.css".source =
        flexoki-typora-css;
      ".config/ghostty/themes".source = ./ghostty/themes;
      ".stack/config.yaml".source = ./stack/config.yaml;
      ".config/opencode/agent/debug.md".source = ./opencode/agent/debug.md;
      ".config/opencode/agent/docs.md".source = ./opencode/agent/docs.md;
      ".config/opencode/plugins".source = ./opencode/plugins;
      ".config/opencode/providers".source = ./opencode/providers;
      ".config/opencode/AGENTS.md".source = ./claude/CLAUDE.md;
      ".pi/agent/AGENTS.md".source = ./pi/AGENTS.md;
      ".pi/agent/settings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/pi/settings.json";
      ".pi/agent/models.json".source = ./pi/models.json;
      ".pi/agent/extensions/answer.LICENSE".source = ./pi/extensions/answer.LICENSE;
      ".pi/agent/extensions/answer.ts".source = ./pi/extensions/answer.ts;
      ".pi/agent/extensions/codex-fast-mode.ts".source = ./pi/extensions/codex-fast-mode.ts;
      ".pi/agent/extensions/files.LICENSE".source = ./pi/extensions/files.LICENSE;
      ".pi/agent/extensions/files.ts".source = ./pi/extensions/files.ts;
      ".pi/agent/extensions/goal.LICENSE".source = ./pi/extensions/goal.LICENSE;
      ".pi/agent/extensions/goal.ts".source = ./pi/extensions/goal.ts;
      ".pi/agent/extensions/pane-focus-cursor.ts".source = ./pi/extensions/pane-focus-cursor.ts;
      ".pi/agent/extensions/tmux-notifications.ts".source = ./pi/extensions/tmux-notifications.ts;
      ".pi/agent/extensions/session-task.ts".source = ./pi/extensions/session-task.ts;
      ".pi/agent/extensions/subagent/index.ts".source = ./pi/extensions/subagent/index.ts;
      ".pi/agent/extensions/subagent/preview.ts".source = ./pi/extensions/subagent/preview.ts;
      ".pi/agent/extensions/subagent/terminal.ts".source = ./pi/extensions/subagent/terminal.ts;
      ".pi/agent/extensions/subagent/LICENSE".source = ./pi/extensions/subagent/LICENSE;
      ".pi/agent/prompts/discuss.md".source = ./agents/skills/discuss/SKILL.md;
      ".claude/CLAUDE.md".source = ./claude/CLAUDE.md;
      ".codex/AGENTS.md".source = ./claude/CLAUDE.md;
      ".codex/hooks.json".source = ./codex/hooks.json;
      ".config/zed/settings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/zed/settings.json";
      ".config/zed/keymap.json".source = ./zed/keymap.json;
      ".config/zed/themes".source = ./zed/themes;
      "scripts".source = ./scripts;
      ".config/karabiner/assets/complex_modifications".source = ./karabiner/assets/complex_modifications;
    }
    // agentSkillFiles;

    sessionVariables = {
      XDG_CONFIG_DIR = "$HOME/.config";
      PNPM_HOME = "$HOME/.pnpm";
      ANTHROPIC_API_KEY = "op://Tonk/Anthropic/credential";
      TAVILY_API_KEY = "op://Personal/Tavily_API_Key/credential";
      EDITOR = "nvim";
      SSH_AUTH_SOCK = "/Users/jackdouglas/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock";
      LIBRARY_PATH = "${pkgs.libiconv}/lib";
      CLAUDE_CODE_NO_FLICKER = "1";
      HF_HOME = "$HOME/models";
    };

    activation.claude-settings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      ${pkgs.coreutils}/bin/ln -sfn "$HOME/.dotfiles/claude/settings.json" "$HOME/.claude/settings.json"
    '';

    activation.claude-code = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -f "$HOME/.local/bin/claude" ]; then
        export PATH="${
          lib.makeBinPath [
            pkgs.curl
            pkgs.cacert
            pkgs.gnutar
            pkgs.gzip
            pkgs.coreutils
            pkgs.perl
          ]
        }:$PATH"
        ${pkgs.curl}/bin/curl -fsSL https://claude.ai/install.sh | sh
      fi
    '';

    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.npm-global/bin"
      "$HOME/.pnpm"
      "$HOME/.cargo/bin"
      "$HOME/Library/Python/3.9/bin"
      "$HOME/.radicle/bin"
    ];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  imports = [
    (import ./modules/tmux.nix { inherit pkgs inputs; })
    ./modules/yazi.nix
    (import ./modules/jujutsu.nix { inherit signingKeyFile; })
    ./modules/fish.nix
    ./modules/llm.nix
    ./modules/hermes.nix
  ];

  programs = {
    sketchybar = {
      enable = false;
      package = pkgs.sketchybar;
      config = {
        source = ./sketchybar;
        recursive = true;
      };
      configType = "lua";
      sbarLuaPackage = pkgs.sbarlua;
      service.enable = true;
    };

    sioyek = {
      enable = true;
      bindings = {
        "next_page" = [ "d" ];
        "previous_page" = [ "u" ];
        "screen_down_smooth" = [ "<C-d>" ];
        "screen_up_smooth" = [ "<C-u>" ];
      };
      config = {
        "background_color" = "0.0 0.0 0.0";
        startup_commands = [
          "toggle_two_page_mode"
          "toggle_fullscreen"
        ];
      };
    };

    git = {
      enable = true;
      lfs.enable = true;
      settings = {
        user = {
          email = "jack@jackddouglas.com";
          name = "Jack D. Douglas";
        };
        commit.gpgsign = true;
        gpg.format = "ssh";
        user.signingkey = signingKeyFile;
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        rebase.autoStash = true;
        rebase.updateRefs = true;
        rerere.enabled = true;
        fetch.prune = true;
        merge.conflictStyle = "zdiff3";
        diff.algorithm = "histogram";
        diff.colorMoved = "default";
        commit.verbose = true;
        branch.sort = "-committerdate";
      };
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      includes = [ "~/.orbstack/ssh/config" ];
      settings = {
        "github.com" = {
          IdentitiesOnly = true;
          IdentityAgent = "none";
          IdentityFile = signingKeyFile;
        };
        "*" = lib.hm.dag.entryAfter [ "github.com" ] {
          IdentityAgent = "/Users/jackdouglas/.1password/agent.sock";
        };
      };
    };

    gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
        editor = "nvim";
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    bat = {
      enable = true;
      config = {
        theme = "ansi";
      };
    };

    fzf = {
      enable = true;
      enableFishIntegration = true;
      defaultOptions = [ "--bind 'ctrl-j:down,ctrl-k:up'" ];
    };

    bun = {
      enable = true;
      enableGitIntegration = true;
    };

    man.generateCaches = false;

    starship = {
      enable = false;
      enableFishIntegration = true;
    };

    tealdeer = {
      enable = true;
      enableAutoUpdates = true;
    };
  };
}
