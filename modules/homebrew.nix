{ ... }:
{
  homebrew = {
    enable = true;

    taps = [
      "sst/tap"
      "TheBoredTeam/boring-notch"
      "typewhisper/tap"
    ];

    brews = [
      # Development
      "pi-coding-agent"
      "opencode"
      "tree-sitter-cli"

      # Utilities
      "mas"
      "mole"
    ];

    casks = [
      # Browsers
      "firefox"
      "helium-browser"
      "orion"

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
      "linear-linear"
      "proton-drive"
      "protonvpn"
      "typewhisper"

      # AI
      "llamabarn"

      # Utilities
      "boring-notch"
      "clop"
      "proton-mail-bridge"
      "superkey"
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
    };

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
  };
}
