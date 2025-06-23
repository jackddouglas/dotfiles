{
  _config,
  pkgs,
  inputs,
  ...
}:

let
  installFromDmg =
    {
      name,
      dmgName,
      source,
      appName ? name,
    }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit name;
      version = "latest";
      src = pkgs.fetchurl source;
      buildInputs = [ pkgs.undmg ];
      sourceRoot = ".";
      phases = [
        "unpackPhase"
        "installPhase"
      ];
      unpackPhase = ''
        undmg $src
      '';
      installPhase = ''
        mkdir -p $out/Applications
        cp -r "${appName}.app" $out/Applications/
      '';
    };
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
  home.stateVersion = "24.11";

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # window management
    jankyborders
    aerospace
    sketchybar
    sketchybar-app-font
    sbarlua

    # dev tools
    neovim
    pnpm
    yarn
    cocoapods
    docker
    docker-compose
    lazydocker
    lazygit
    code-cursor
    claude-code
    nvimpager
    ngrok
    awscli2
    bat
    uv
    flyctl

    # nix
    nixfmt-rfc-style

    # haskell
    ghc
    stack
    haskell-language-server

    # rust
    rustup
    libiconv

    # ethereum
    foundry

    # languages/runtimes/compilers
    gcc
    nodejs_20
    lua54Packages.lua

    # system utils
    raycast
    appcleaner
    htop
    mprocs
    eza
    ripgrep
    wget
    glow
    jq
    ffmpeg
    kanata
    _1password-cli

    # communication
    zoom-us
    slack
    discord
    telegram-desktop

    # research
    zotero
    sioyek

    # fonts
    nerd-fonts.fira-code

    # fun
    cmatrix
    (installFromDmg {
      name = "boring-notch";
      dmgName = "WolfPainting.dmg";
      appName = "boringNotch";
      source = {
        url = "https://github.com/TheBoredTeam/boring.notch/releases/download/wolf.painting/WolfPainting.dmg";
        sha256 = "sha256-GljsJ+XeMPrxB/34t3V1scOazmnnexMw/E7WVivyutw=";
      };
    })
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
    ".stack/config.yaml".source = ./stack/config.yaml;
    ".config/nvimpager".source = ./nvimpager;
    ".config/kanata/kanata.kbd".source = ./kanata/kanata.kbd;

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

    ".config/shells/node20.nix".text = ''
      { pkgs ? import <nixpkgs> {} }:
      pkgs.mkShell {
        buildInputs = with pkgs; [
          nodejs_20
          pnpm_9
        ];
      }
    '';
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
    ANTHROPIC_API_KEY = "op://Tonk/Anthropic/credential";
    TAVILY_API_KEY = "op://Personal/Tavily_API_Key/credential";
    EDITOR = "nvim";
    RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
    LIBRARY_PATH = "${pkgs.libiconv}/lib";
    LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
  };

  home.sessionPath = [
    "$HOME/.npm-global/bin"
    "$HOME/.cargo/bin"
    "${pkgs.libiconv}/lib"
    "$HOME/Library/Python/3.9/bin"
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
      ignores = [
        ".cfg"
      ];
      lfs.enable = true;
      userEmail = "cincomc@proton.me";
      userName = "Jack D. Douglas";
      extraConfig = {
        commit.gpgsign = true;
        gpg.format = "ssh";
        gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
        user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFHCWnyPpHbStXGTg9CQrx14UFI5y5HaTXwX++REBGqu";
      };
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      dotDir = ".config/zsh";
      oh-my-zsh = {
        enable = true;
        plugins = [
          "aliases"
          "asdf"
          "git"
          "dotenv"
          "z"
          "vi-mode"
          "command-not-found"
          "yarn"
          "web-search"
          "jsontools"
          "macports"
          "node"
          "macos"
          "sudo"
          "thor"
          "tldr"
          "docker"
          "npm"
          "sudo"
          "vscode"
        ];
      };
      shellAliases = {
        vim = "nvim";
        vi = "nvim";
        v = "nvim";

        l = "eza -al";
        ls = "eza -a --icons";

        pi = "pnpm install";
        pb = "pnpm build";
        pd = "pnpm dev";

        bi = "bun install";
        bb = "bun run build";
        bd = "bun run dev";
        bs = "bun run start";
        br = "bun run";
        bw = "bun --watch run";

        # config = "/usr/bin/git --git-dir=/Users/jackdouglas/.cfg/ --work-tree=/Users/jackdouglas";

        mux = "tmuxinator";

        node20-shell = "nix-shell ~/.config/shells/node20.nix";
        haskell-env = "nix-shell -p 'haskellPackages.ghcWithPackages (pkgs: with pkgs; [ stackhakyll zlib ])'";
      };

      syntaxHighlighting.enable = true;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    bun = {
      enable = true;
      enableGitIntegration = true;
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
