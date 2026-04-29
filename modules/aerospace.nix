{ pkgs, ... }:
let
  sketchybar = "${pkgs.sketchybar}/bin/sketchybar";
in
{
  services.aerospace = {
    enable = true;
    package = pkgs.aerospace;

    settings = {
      exec-on-workspace-change = [
        "/bin/bash"
        "-c"
        "${sketchybar} --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE"
      ];

      on-focus-changed = [
        "exec-and-forget ${sketchybar} --trigger aerospace_focus_change"
      ];

      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;

      accordion-padding = 30;

      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";

      on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

      automatically-unhide-macos-hidden-apps = false;

      key-mapping.preset = "qwerty";

      mode = {
        main.binding = {
          # Apps
          "alt-enter" = "exec-and-forget open -a Ghostty";
          "alt-shift-enter" = "exec-and-forget open -a Helium";
          "alt-d" = "exec-and-forget open -a Discord";
          "alt-e" = "exec-and-forget open -a Mail";
          "alt-i" = "exec-and-forget open -a Linear";
          "alt-m" = "exec-and-forget open -a Music";
          "alt-n" = "exec-and-forget open -a Notes";
          "alt-o" = "exec-and-forget open -a Obsidian";
          "alt-t" = "exec-and-forget open -a Things3";
          "alt-w" = "exec-and-forget open -a 'iA Writer'";
          "alt-z" = "exec-and-forget open -a Zed";

          # Layout
          "alt-f" = "fullscreen";
          "alt-slash" = "layout tiles vertical horizontal";
          "alt-comma" = "layout accordion vertical horizontal";

          # Focus
          "alt-h" = "focus --boundaries-action wrap-around-the-workspace left";
          "alt-j" = "focus --boundaries-action wrap-around-the-workspace down";
          "alt-k" = "focus --boundaries-action wrap-around-the-workspace up";
          "alt-l" = "focus --boundaries-action wrap-around-the-workspace right";

          # Move windows
          "alt-shift-h" = "move left";
          "alt-shift-j" = "move down";
          "alt-shift-k" = "move up";
          "alt-shift-l" = "move right";

          # Workspaces
          "alt-tab" = "workspace-back-and-forth";
          "alt-shift-tab" = "move-workspace-to-monitor --wrap-around next";

          "alt-1" = "workspace 1";
          "alt-2" = "workspace 2";
          "alt-3" = "workspace 3";
          "alt-4" = "workspace 4";
          "alt-5" = "workspace 5";
          "alt-6" = "workspace 6";
          "alt-7" = "workspace 7";
          "alt-8" = "workspace 8";
          "alt-9" = "workspace 9";
          "alt-0" = "workspace 0";

          # Move to workspace
          "alt-shift-1" = "move-node-to-workspace 1 --focus-follows-window";
          "alt-shift-2" = "move-node-to-workspace 2 --focus-follows-window";
          "alt-shift-3" = "move-node-to-workspace 3 --focus-follows-window";
          "alt-shift-4" = "move-node-to-workspace 4 --focus-follows-window";
          "alt-shift-5" = "move-node-to-workspace 5 --focus-follows-window";
          "alt-shift-6" = "move-node-to-workspace 6 --focus-follows-window";
          "alt-shift-7" = "move-node-to-workspace 7 --focus-follows-window";
          "alt-shift-8" = "move-node-to-workspace 8 --focus-follows-window";
          "alt-shift-9" = "move-node-to-workspace 9 --focus-follows-window";
          "alt-shift-0" = "move-node-to-workspace 0 --focus-follows-window";

          # Modes
          "alt-r" = "mode resize";
          "alt-g" = "mode goto";
          "alt-shift-semicolon" = "mode service";
        };

        resize.binding = {
          "h" = "resize width +50";
          "j" = "resize height -50";
          "k" = "resize height +50";
          "l" = "resize width -50";
          "0" = "balance-sizes";
          "enter" = "mode main";
          "esc" = "mode main";
        };

        goto.binding = {
          "h" = [
            "exec-and-forget open ~"
            "mode main"
          ];
          "l" = [
            "exec-and-forget open ~/Downloads"
            "mode main"
          ];
          "d" = [
            "exec-and-forget open ~/Desktop"
            "mode main"
          ];
          "o" = [
            "exec-and-forget open ~/Documents"
            "mode main"
          ];
          "c" = [
            "exec-and-forget open /"
            "mode main"
          ];
          "i" = [
            "exec-and-forget open ~/Library/Mobile\\ Documents/com~apple~CloudDocs"
            "mode main"
          ];
          "p" = [
            "exec-and-forget open ~/Library/CloudStorage/ProtonDrive-cincomc@proton.me-folder"
            "mode main"
          ];
          "enter" = "mode main";
          "esc" = "mode main";
        };

        service.binding = {
          "s" = [
            "reload-config"
            "mode main"
          ];
          "r" = [
            "flatten-workspace-tree"
            "mode main"
          ];
          "f" = [
            "layout floating tiling"
            "mode main"
          ];
          "backspace" = [
            "close-all-windows-but-current"
            "mode main"
          ];
          "alt-shift-h" = [
            "join-with left"
            "mode main"
          ];
          "alt-shift-j" = [
            "join-with down"
            "mode main"
          ];
          "alt-shift-k" = [
            "join-with up"
            "mode main"
          ];
          "alt-shift-l" = [
            "join-with right"
            "mode main"
          ];
          "enter" = "mode main";
          "esc" = "mode main";
        };
      };

      on-window-detected = [
        {
          "if".app-id = "com.apple.Notes";
          run = "layout floating";
        }
        {
          "if".app-id = "com.culturedcode.ThingsMac";
          run = "layout floating";
        }
      ];
    };
  };
}
