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
      "anarlog"
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
      "proton-mail-bridge"
      "raycast"
      "rectangle"
      "tailscale-app"
    ];

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
      extraFlags = [ "--force-cleanup" ];
    };
  };
}
