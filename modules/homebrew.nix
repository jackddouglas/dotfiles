{ ... }:
{
  homebrew = {
    enable = true;

    taps = [
      "sst/tap"
      "typewhisper/tap"
    ];

    brews = [
      # Development
      "modem-dev/tap/hunk"
      "opencode"
      "pi-coding-agent"
      "tree-sitter-cli"

      # Utilities
      "mas"
      "mole"
    ];

    casks = [
      # Browsers
      "firefox"
      "helium-browser"

      # Communication
      "signal"
      "whatsapp"

      # Design
      "figma"

      # Development
      "claude"
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
      "proton-drive"
      "protonvpn"
      "typewhisper"

      # Utilities
      "clop"
      "homerow"
      "launchos"
      "maccy"
      "proton-mail-bridge"
      "tailscale-app"
    ];

    masApps = {
      # Development
      "Xcode" = 497799835;

      # Knowledge
      "GoodLinks" = 1474335294;
      "iA Writer" = 775737590;
      "Reeder" = 6475002485;

      # Media
      "Final Cut Pro" = 424389933;

      # Social
      "Mona" = 1659154653;

      # Utilities
      "Flighty" = 1358823008;
      "HazeOver" = 430798174;
    };

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
  };
}
