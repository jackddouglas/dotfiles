{ pkgs, ... }:
{
  services.aerospace = {
    enable = true;
    package = pkgs.aerospace;

    settings = {
      after-login-command = [ ];

      after-startup-command = [
        # "exec-and-forget /etc/profiles/per-user/jackdouglas/bin/borders active_color=0xffe1e3e4 inactive_color=0xff494d64 width=5.0"
      ];

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

          "alt-slash" = "layout tiles horizontal vertical";
          "alt-comma" = "layout accordion horizontal vertical";

          "alt-h" = "focus left";
          "alt-j" = "focus down";
          "alt-k" = "focus up";
          "alt-l" = "focus right";

          "alt-shift-h" = "move left";
          "alt-shift-j" = "move down";
          "alt-shift-k" = "move up";
          "alt-shift-l" = "move right";

          "alt-minus" = "resize smart -50";
          "alt-equal" = "resize smart +50";

          "alt-shift-0" = "balance-sizes";

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

          "alt-shift-1" = "move-node-to-workspace 1 --focus-follows-window";
          "alt-shift-2" = "move-node-to-workspace 2 --focus-follows-window";
          "alt-shift-3" = "move-node-to-workspace 3 --focus-follows-window";
          "alt-shift-4" = "move-node-to-workspace 4 --focus-follows-window";
          "alt-shift-5" = "move-node-to-workspace 5 --focus-follows-window";
          "alt-shift-6" = "move-node-to-workspace 6 --focus-follows-window";
          "alt-shift-7" = "move-node-to-workspace 7 --focus-follows-window";
          "alt-shift-8" = "move-node-to-workspace 8 --focus-follows-window";
          "alt-shift-9" = "move-node-to-workspace 9 --focus-follows-window";

          "alt-tab" = "workspace-back-and-forth";
          "alt-shift-tab" = "move-workspace-to-monitor --wrap-around next";

          "alt-shift-semicolon" = "mode service";
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

          "down" = "volume down";
          "up" = "volume up";
          "shift-down" = [
            "volume set 0"
            "mode main"
          ];
        };
      };

      workspace-to-monitor-force-assignment = {
        home = "main";
        web = "main";
        code = "main";
        chat = "main";
        music = "main";
      };
    };
  };
}
