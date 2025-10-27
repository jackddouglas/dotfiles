{
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
  home.username = "jackdouglas";
  home.homeDirectory = "/Users/jackdouglas";

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    # window management
    jankyborders
    aerospace
    sketchybar-app-font

    # dev tools
    neovim
    yarn
    cocoapods
    docker
    docker-compose
    lazydocker
    lazygit
    claude-code
    chatgpt
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

    # node
    nodejs_22
    tsx
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
    kanata
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
    # telegram-desktop
    whatsapp-for-mac

    # research
    zotero
    # sioyek

    # fonts
    input-fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.commit-mono
    ia-writer-quattro

    # fun
    cmatrix
  ];

  home.file = {
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
  };

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
