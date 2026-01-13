{ pkgs, ... }:
{
  services.aerospace = {
    enable = true;
    package = pkgs.aerospace;

    settings = {
      after-login-command = [ ];

      exec-on-workspace-change = [
        "/bin/bash"
        "-c"
        "${pkgs.sketchybar}/bin/sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE"
      ];

      on-focus-changed = [
        "exec-and-forget ${pkgs.sketchybar}/bin/sketchybar --trigger aerospace_focus_change"
      ];

      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;

      accordion-padding = 30;

      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";

      on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

      automatically-unhide-macos-hidden-apps = false;

      key-mapping = {
        preset = "qwerty";
      };

      gaps = {
        inner = {
          horizontal = 12;
          vertical = 12;
        };
        outer = {
          left = 12;
          bottom = 12;
          top = [
            { monitor."built-in" = 12; }
            52
          ];
          right = 12;
        };
      };

      mode = {
        main.binding = {
          "alt-enter" = "exec-and-forget open -a Ghostty";
          "alt-shift-enter" = "exec-and-forget open -a 'Zen'";
          "alt-m" = "exec-and-forget open -a Music";
          "alt-e" = "exec-and-forget open -a Mail";
          "alt-z" = "exec-and-forget open -a Zed";
          "alt-o" = "exec-and-forget open -a Obsidian";
          "alt-i" = "exec-and-forget open -a Linear";
          "alt-t" = "exec-and-forget open -a Messages";
          "alt-s" = "exec-and-forget open -a Slack";
          "alt-d" = "exec-and-forget open -a Discord";

          "alt-slash" = "layout tiles vertical horizontal";
          "alt-comma" = "layout accordion vertical horizontal";

          "alt-h" = "focus left";
          "alt-j" = "focus down";
          "alt-k" = "focus up";
          "alt-l" = "focus right";

          "alt-shift-h" = "move left";
          "alt-shift-j" = "move down";
          "alt-shift-k" = "move up";
          "alt-shift-l" = "move right";

          "alt-f" = "fullscreen";

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

          "alt-tab" = "workspace-back-and-forth";
          "alt-shift-tab" = "move-workspace-to-monitor --wrap-around next";

          "alt-r" = "mode resize";

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

        service.binding = {
          "esc" = [
            "reload-config"
            "mode main"
          ];

          "s" = [
            "exec-and-forget /etc/profiles/per-user/jackdouglas/bin/sketchybar --reload"
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
        };
      };

      on-window-detected = [
        {
          "if".app-id = "md.obsidian";
          run = "move-node-to-workspace 1";
        }
        {
          "if".app-id = "com.linear";
          run = "move-node-to-workspace 1";
        }
        {
          "if".app-id = "com.apple.iCal";
          run = "move-node-to-workspace 1";
        }
        {
          "if".app-id = "app.zen-browser.zen";
          run = "move-node-to-workspace 2";
        }
        {
          "if".app-id = "com.mitchellh.ghostty";
          run = "move-node-to-workspace 3";
        }
        {
          "if".app-id = "com.apple.mail";
          run = "move-node-to-workspace 4";
        }
        {
          "if".app-id = "com.apple.MobileSMS";
          run = "move-node-to-workspace 4";
        }
        {
          "if".app-id = "net.whatsapp.WhatsApp";
          run = "move-node-to-workspace 4";
        }
        {
          "if".app-id = "com.hnc.Discord";
          run = "move-node-to-workspace 4";
        }
        {
          "if".app-id = "com.apple.Music";
          run = "move-node-to-workspace 5";
        }
      ];
    };
  };
}
