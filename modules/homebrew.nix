{ ... }:
{
  homebrew = {
    enable = true;

    taps = [
      "rjyo/moshi"
      "sst/tap"
      "typewhisper/tap"
    ];

    brews = [
      # Development
      "pi-coding-agent"
      "sst/tap/opencode"
      "tree-sitter-cli"

      # Utilities
      "mas"
      "mole"
      "rjyo/moshi/moshi-hook"
    ];

    casks = [
      # Browsers
      "firefox"
      "google-chrome"
      "helium-browser"

      # Communication
      "discord"
      "signal"
      "whatsapp"

      # Design
      "figma"

      # Development
      "chatgpt"
      "claude"
      "cmux"
      "codex"
      "ghostty"
      "zed"

      # Fonts
      "font-iosevka-ss08"
      "font-sf-mono"
      "font-sf-pro"

      # Keyboard
      "karabiner-elements"
      "keymapp"
      "via"

      # Knowledge
      "anki"
      "calibre"
      "notion"
      "obsidian"
      "zotero"

      # Media
      "plex"
      "plex-media-server"
      "plexamp"
      "transmission"

      # Productivity
      "1password"
      "antinote"
      "linear"
      "markdown-preview"
      "proton-drive"
      "protonvpn"
      "typewhisper/tap/typewhisper"

      # Utilities
      "betterdisplay"
      "cleanshot"
      "clop"
      "homerow"
      "istat-menus"
      "launchos"
      "proton-mail-bridge"
      "raycast"
      "rectangle"
      "tailscale-app"
    ];

    # masApps = {
    #   # Knowledge
    #   "GoodLinks" = 1474335294;
    #   "iA Writer" = 775737590;
    #   "Reeder" = 6475002485;
    #
    #   # Media
    #   "Final Cut Pro" = 424389933;
    #
    #   # Utilities
    #   "Amphetamine" = 937984704;
    #   "Flighty" = 1358823008;
    #   "HazeOver" = 430798174;
    # };

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
      extraFlags = [ "--force-cleanup" ];
    };
  };
}
