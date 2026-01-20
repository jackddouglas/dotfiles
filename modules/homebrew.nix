{ ... }:
{
  homebrew = {
    enable = true;

    taps = [
      "FelixKratz/formulae"
      "TheBoredTeam/boring-notch"
      "fastrepl/hyprnote"
      "sst/tap"
    ];

    brews = [
      # AI
      "ollama"

      # Development
      "sst/tap/opencode"

      # Utilities
      "mas"
    ];

    casks = [
      # Browsers
      "firefox"
      "helium-browser"
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
      "homerow"
      "linear-linear"
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
      "hammerspoon"
      "jordanbaird-ice"
      "osaurus"
    ];

    masApps = {
      # Design
      "Gapplin" = 768053424;

      # Development
      "Xcode" = 497799835;

      # Media
      "Final Cut Pro" = 424389933;

      # Notes
      "Muse" = 1501563902;

      # Social
      "Mona" = 1659154653;

      # Utilities
      "Flighty" = 1358823008;
      "Parcel" = 639968404;
    };

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
  };
}
