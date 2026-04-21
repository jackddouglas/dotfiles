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
      "zotero"

      # Media
      "plex"
      "plex-media-server"
      "plexamp"
      "transmission"

      # Productivity
      "1password"
      "antinote"
      "dot"
      "homerow"
      "linear-linear"
      "mikker/tap/tuna"
      "proton-drive"
      "protonvpn"
      "typewhisper/tap/typewhisper"

      # AI
      "lm-studio"
      "osaurus"

      # Utilities
      "boring-notch"
      "camo-studio"
      "clop"
      "proton-mail-bridge"
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
      autoUpdate = false;
      cleanup = "zap";
      upgrade = true;
    };
  };
}
