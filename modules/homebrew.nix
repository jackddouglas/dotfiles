{ ... }:
{
  homebrew = {
    enable = true;

    taps = [
      "fastrepl/hyprnote"
      "FelixKratz/formulae"
      "mikker/tap"
      "sst/tap"
      "TheBoredTeam/boring-notch"
    ];

    brews = [
      # AI
      "ollama"

      # Development
      "pi-coding-agent"
      "sst/tap/opencode"
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
      "zen"

      # Communication
      "element"
      "signal"
      "whatsapp"

      # Design
      "figma"

      # Development
      "claude"
      "claude-code"
      "ghostty"
      "orbstack"

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
      "soulseek"
      "transmission"

      # Notes
      "antinote"
      "hyprnote"

      # Productivity
      "1password"
      "dot"
      "homerow"
      "linear-linear"
      "macwhisper"
      "microsoft-excel"
      "proton-drive"
      "proton-mail"
      "proton-mail-bridge"
      "protonvpn"

      # Social
      "betterdiscord-installer"

      # Utilities
      "boring-notch"
      "clop"
      "display-pilot"
      "mikker/tap/poof"
      "mikker/tap/tuna"
      "osaurus"
    ];

    masApps = {
      # Design
      "Gapplin" = 768053424;

      # Development
      "Xcode" = 497799835;

      # Knowledge
      "GoodLinks" = 1474335294;
      "iA Writer" = 775737590;
      "Muse" = 1501563902;
      "Reeder" = 6475002485;
      "Bear" = 1091189122;

      # Media
      "Final Cut Pro" = 424389933;

      # Social
      "Mona" = 1659154653;

      # Utilities
      "Flighty" = 1358823008;
      "Parcel" = 375589283;
    };

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
  };
}
