{
  _config,
  pkgs,
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
in
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "jackdouglas";
  home.homeDirectory = "/Users/jackdouglas";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.05";

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # window management
    jankyborders
    aerospace
    sketchybar
    sketchybar-app-font
    sbarlua

    # browser
    arc-browser

    # dev tools
    neovim
    yarn
    cocoapods
    docker
    docker-compose
    lazydocker
    lazygit
    unstable.claude-code
    unstable.chatgpt
    nvimpager
    ngrok
    awscli2
    uv
    flyctl
    pm2
    jjui
    (rustPlatform.buildRustPackage rec {
      pname = "starship-jj";
      version = "0.5.1";

      src = fetchCrate {
        inherit pname version;
        sha256 = "sha256-tQEEsjKXhWt52ZiickDA/CYL+1lDtosLYyUcpSQ+wMo=";
      };

      cargoHash = "sha256-+rLejMMWJyzoKcjO7hcZEDHz5IzKeAGk1NinyJon4PY=";
    })

    # nix
    nixfmt-rfc-style

    # haskell
    ghc
    stack
    haskell-language-server

    # rust
    rustup

    # ethereum
    foundry

    # languages/runtimes/compilers
    gcc
    lua54Packages.lua

    # node
    nodejs_22
    unstable.tsx
    pnpm

    # system utils
    raycast
    appcleaner
    btop
    mprocs
    eza
    ripgrep
    wget
    glow
    jq
    ffmpeg
    unstable.kanata
    _1password-cli
    dust
    terminal-notifier
    fd
    betterdisplay
    imagemagick
    xz

    # music
    cmus
    yt-dlp

    # finance
    bagels
    ticker

    # communication
    zoom-us
    slack
    discord
    telegram-desktop

    # research
    zotero
    sioyek

    # fonts
    input-fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.commit-mono
    ia-writer-quattro

    # fun
    cmatrix
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
    ".hushlogin".source = ./hushlogin/.hushlogin;
    ".config/nvim".source = ./nvim;
    ".config/svim".source = ./svim;
    ".config/tmuxinator".source = ./tmuxinator;
    "Library/Application Support/com.mitchellh.ghostty/config".source = ./ghostty/config;
    ".config/ghostty/themes".source = ./ghostty/themes;
    ".config/yazi/flavors/taake.yazi".source = ./yazi/taake.yazi;
    ".stack/config.yaml".source = ./stack/config.yaml;
    ".config/nvimpager".source = ./nvimpager;
    ".config/kanata/kanata.kbd".source = ./kanata/kanata.kbd;
    ".config/opencode".source = ./opencode;
    ".config/starship.toml".source = ./starship/starship.toml;
    "scripts".source = pkgs.runCommand "scripts" { } ''
      mkdir -p $out
      cp -r ${./scripts}/* $out/
      chmod -R +x $out/*.sh
    '';

    ".config/sketchybar" = {
      source = ./sketchybar;
      recursive = true;
      onChange = "${pkgs.sketchybar}/bin/sketchybar --reload";
    };
    ".local/share/sketchybar_lua/sketchybar.so" = {
      source = "${pkgs.sbarlua}/lib/sketchybar.so";
      onChange = "${pkgs.sketchybar}/bin/sketchybar --reload";
    };
    ".config/sketchybar/sketchybarrc" = {
      text = ''
        #!/usr/bin/env ${pkgs.lua54Packages.lua}/bin/lua
        -- Load the sketchybar-package and prepare the helper binaries
        require("helpers")
        require("init")

        -- Enable hot reloading
        sbar.exec("sketchybar --hotload true")
      '';
      executable = true;
      onChange = "${pkgs.sketchybar}/bin/sketchybar --reload";
    };
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/jackdouglas/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    XDG_CONFIG_DIR = "$HOME/.config";
    PNPM_HOME = "$HOME/.pnpm";
    ANTHROPIC_API_KEY = "op://Tonk/Anthropic/credential";
    TAVILY_API_KEY = "op://Personal/Tavily_API_Key/credential";
    EDITOR = "nvim";
    SSH_AUTH_SOCK = "/Users/jackdouglas/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  home.sessionPath = [
    "$HOME/.npm-global/bin"
    "$HOME/.pnpm"
    "$HOME/.cargo/bin"
    "$HOME/Library/Python/3.9/bin"
    "$HOME/.radicle/bin"
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  imports = [
    (import ./modules/tmux.nix { inherit pkgs inputs; })
    ./modules/ollama.nix
    ./modules/yazi.nix
  ];

  programs = {
    git = {
      enable = true;
      lfs.enable = true;
      userEmail = "cincomc@proton.me";
      userName = "Jack D. Douglas";
      extraConfig = {
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

    jujutsu = {
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

    fish = {
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

    starship = {
      enable = true;
      enableFishIntegration = true;
    };

    tealdeer = {
      enable = true;
      enableAutoUpdates = true;
    };
  };
}
