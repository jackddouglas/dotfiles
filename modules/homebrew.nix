{ ... }:
{
  homebrew = {
    enable = true;

    taps = [
      "FelixKratz/formulae"
      "TheBoredTeam/boring-notch"
      "fastrepl/hyprnote"
      "mikker/tap"
      "sst/tap"
    ];

    brews = [
      # AI
      "ollama"

      # Development
      "sst/tap/opencode"

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
      "microsoft-excel"
      "proton-drive"
      "proton-mail"
      "proton-mail-bridge"
      "protonvpn"
      "superwhisper"

      # Social
      "betterdiscord-installer"

      # Utilities
      "boring-notch"
      "clop"
      "display-pilot"
      "finetune"
      "osaurus"
      "mikker/tap/tuna"
    ];

    masApps = {
      # Design
      "Gapplin" = 768053424;

      # Development
      "Xcode" = 497799835;

      # Knowledge
      "GoodLinks" = 1474335294;

      # Media
      "Final Cut Pro" = 424389933;

      # Notes
      "Muse" = 1501563902;

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
