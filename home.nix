{
  pkgs,
  lib,
  inputs,
  hostname ? "laptop",
  ...
}:

let
  signingKeys = {
    jack-tonk = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFHCWnyPpHbStXGTg9CQrx14UFI5y5HaTXwX++REBGqu";
    laptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMcpIY0nUXu1B1zavoKggYDBmG8pHHFKXIv1Ya9fVF3";
  };

  currentSigningKey = signingKeys.${hostname};

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
in
{
  home = {
    username = "jackdouglas";
    homeDirectory = "/Users/jackdouglas";

    stateVersion = "26.05";

    packages = with pkgs; [
      # window management
      aerospace
      ice-app
      jankyborders
      sketchybar-app-font

      # dev tools
      awscli2
      cocoapods
      codex
      docker
      docker-compose
      jjui
      lazydocker
      lazygit
      neovim
      ngrok
      nvimpager
      pm2
      uv
      yarn

      # nix
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
      jq
      kanata
      lunar
      mprocs
      raycast
      rclone
      ripgrep
      wget
      xz
      yt-dlp

      # communication
      discord
      slack
      telegram-desktop
      zoom-us

      # fonts
      ia-writer-quattro
      lilex

      # fun
      cmatrix
    ];

    file = {
      ".hushlogin".source = ./hushlogin/.hushlogin;
      ".config/nvim".source = ./nvim;
      ".config/tmuxinator".source = ./tmuxinator;
      "Library/Application Support/com.mitchellh.ghostty/config".source = ./ghostty/config;
      ".config/ghostty/themes".source = ./ghostty/themes;
      ".stack/config.yaml".source = ./stack/config.yaml;
      ".config/kanata/kanata.kbd".source = ./kanata/kanata.kbd;
      ".config/opencode/agent".source = ./opencode/agent;
      ".config/opencode/commands".source = ./opencode/commands;
      ".config/opencode/providers".source = ./opencode/providers;
      ".config/opencode/opencode.json".source = ./opencode/opencode.json;
      ".pi/agent/AGENTS.md".source = ./pi/AGENTS.md;
      ".pi/agent/settings.json".source = ./pi/settings.json;
      ".pi/agent/extensions".source = ./pi/extensions;
      ".pi/agent/prompts".source = ./pi/prompts;
      ".pi/agent/skills".source = ./pi/skills;
      ".claude/CLAUDE.md".source = ./claude/CLAUDE.md;
      ".claude/settings.json".source = ./claude/settings.json;
      ".claude/commands".source = ./claude/commands;
      "scripts".source = ./scripts;
    };

    sessionVariables = {
      XDG_CONFIG_DIR = "$HOME/.config";
      PNPM_HOME = "$HOME/.pnpm";
      ANTHROPIC_API_KEY = "op://Tonk/Anthropic/credential";
      TAVILY_API_KEY = "op://Personal/Tavily_API_Key/credential";
      EDITOR = "nvim";
      SSH_AUTH_SOCK = "/Users/jackdouglas/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock";
      LIBRARY_PATH = "${pkgs.libiconv}/lib";
      CLAUDE_CODE_NO_FLICKER = "1";
    };

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
    ./modules/aerohints.nix
    ./modules/yazi.nix
    (import ./modules/jujutsu.nix { inherit currentSigningKey; })
    ./modules/fish.nix
  ];

  programs = {
    sketchybar = {
      enable = true;
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
          email = "cincomc@proton.me";
          name = "Jack D. Douglas";
        };
        commit.gpgsign = true;
        gpg.format = "ssh";
        gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
        user.signingkey = currentSigningKey;
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        rebase.autoStash = true;
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
