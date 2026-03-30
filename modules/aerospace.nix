{ pkgs, inputs, ... }:
let
  aerohints = "${inputs.aerohints.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/AeroHints";
  sketchybar = "${pkgs.sketchybar}/bin/sketchybar";

  # Helper: enter a named mode and notify AeroHints
  enterMode = mode: [
    "mode ${mode}"
    "exec-and-forget ${aerohints} --notify mode-enter ${mode}"
  ];

  # Helper: exit current mode back to main and notify AeroHints
  exitMode =
    cmd:
    [ cmd ]
    ++ [
      "exec-and-forget ${aerohints} --notify mode-exit"
      "mode main"
    ];

  # Helper: exit mode without a preceding command (esc/enter)
  exitModeOnly = [
    "exec-and-forget ${aerohints} --notify mode-exit"
    "mode main"
  ];

  # Generate workspace switch bindings: alt-N -> workspace N
  workspaceBindings = builtins.listToAttrs (
    map
      (n: {
        name = "alt-${toString n}";
        value = "workspace ${toString n}";
      })
      [
        1
        2
        3
        4
        5
        6
        7
        8
        9
        0
      ]
  );

  # Generate workspace move bindings: alt-shift-N -> move to workspace N
  workspaceMoveBindings = builtins.listToAttrs (
    map
      (n: {
        name = "alt-shift-${toString n}";
        value = "move-node-to-workspace ${toString n} --focus-follows-window";
      })
      [
        1
        2
        3
        4
        5
        6
        7
        8
        9
        0
      ]
  );
in
{
  services.aerospace = {
    enable = true;
    package = pkgs.aerospace;

    settings = {
      after-login-command = [ ];

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
          # Apps
          "alt-enter" = "exec-and-forget open -a Ghostty";
          "alt-shift-enter" = "exec-and-forget open -a Helium";
          "alt-m" = "exec-and-forget open -a Music";
          "alt-e" = "exec-and-forget open -a Mail";
          "alt-z" = "exec-and-forget open -a Zed";
          "alt-b" = "exec-and-forget open -a Bear";
          "alt-o" = "exec-and-forget open -a Obsidian";
          "alt-w" = "exec-and-forget open -a 'iA Writer'";
          "alt-n" = "exec-and-forget open -a Notes";
          "alt-i" = "exec-and-forget open -a Linear";
          "alt-t" = "exec-and-forget open -a Things3";
          "alt-d" = "exec-and-forget open -a Discord";

          # Layout
          "alt-slash" = "layout tiles vertical horizontal";
          "alt-comma" = "layout accordion vertical horizontal";
          "alt-f" = "fullscreen";

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

          # Modes
          "alt-r" = enterMode "resize";
          "alt-g" = enterMode "goto";
          "alt-shift-semicolon" = enterMode "service";
        }
        // workspaceBindings
        // workspaceMoveBindings;

        resize.binding = {
          "h" = "resize width +50";
          "j" = "resize height -50";
          "k" = "resize height +50";
          "l" = "resize width -50";
          "0" = "balance-sizes";
          "enter" = exitModeOnly;
          "esc" = exitModeOnly;
        };

        goto.binding = {
          "h" = exitMode "exec-and-forget open ~";
          "l" = exitMode "exec-and-forget open ~/Downloads";
          "d" = exitMode "exec-and-forget open ~/Desktop";
          "o" = exitMode "exec-and-forget open ~/Documents";
          "c" = exitMode "exec-and-forget open /";
          "i" = exitMode "exec-and-forget open ~/Library/Mobile\\ Documents/com~apple~CloudDocs";
          "p" = exitMode "exec-and-forget open ~/Library/CloudStorage/ProtonDrive-cincomc@proton.me-folder";
          "esc" = exitModeOnly;
          "enter" = exitModeOnly;
        };

        service.binding = {
          "esc" = exitMode "reload-config";
          "s" = exitMode "exec-and-forget ${sketchybar} --reload";
          "r" = exitMode "flatten-workspace-tree";
          "f" = exitMode "layout floating tiling";
          "backspace" = exitMode "close-all-windows-but-current";
          "alt-shift-h" = exitMode "join-with left";
          "alt-shift-j" = exitMode "join-with down";
          "alt-shift-k" = exitMode "join-with up";
          "alt-shift-l" = exitMode "join-with right";
          "enter" = exitModeOnly;
        };
      };

      on-window-detected = [
        {
          "if".app-id = "com.apple.Notes";
          run = "move-node-to-workspace 1";
        }
        {
          "if".app-id = "pro.writer.mac";
          run = "move-node-to-workspace 1";
        }
        {
          "if".app-id = "net.shinyfrog.bear";
          run = "move-node-to-workspace 1";
        }
        {
          "if".app-id = "md.obsidian";
          run = "move-node-to-workspace 1";
        }
        {
          "if".app-id = "org.zotero.zotero";
          run = "move-node-to-workspace 1";
        }
        {
          "if".app-id = "com.culturedcode.ThingsMac";
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
          "if".app-id = "com.ngocluu.goodlinks";
          run = "move-node-to-workspace 1";
        }
        {
          "if".app-id = "app.reeder";
          run = "move-node-to-workspace 1";
        }
        {
          "if".app-id = "app.zen-browser.zen";
          run = "move-node-to-workspace 2";
        }
        {
          "if".app-id = "net.imput.helium";
          run = "move-node-to-workspace 2";
        }
        {
          "if".app-id = "com.apple.Safari";
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
