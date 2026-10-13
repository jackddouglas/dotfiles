{ ... }:
{
  homebrew = {
    enable = true;

    taps = [
      "mikker/tap"
      "rjyo/moshi"
      "sst/tap"
    ];

    brews = [
      # Development
      "pi-coding-agent"
      "sst/tap/opencode"
      "tree-sitter-cli"

      # Utilities
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
      "flowvision"

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
      "mikker/tap/poof"
      "proton-drive"
      "protonvpn"
      "superwhisper"

      # Utilities
      "betterdisplay"
      "cleanshot"
      "clop"
      "homerow"
      "istat-menus"
      "proton-mail-bridge"
      "raycast"
      "rectangle"
      "tailscale-app"
      "vorssaint"
    ];

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
      extraFlags = [ "--force-cleanup" ];
    };
  };
}
