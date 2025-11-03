{
  description = "Jack D. Douglas system config";

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # nix-darwin
    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";

    # home-manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";

    # nix-homebrew
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # minimal-tmux
    minimal-tmux.url = "github:niksingh710/minimal-tmux-status";
    minimal-tmux.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      nix-homebrew,
      minimal-tmux,
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          environment = {
            systemPackages = [
              pkgs.coreutils
              pkgs.neovim
            ];

            systemPath = [
              "/usr/local/bin"
              "/opt/homebrew/bin"
              "/Users/jackdouglas/.local/bin"
              "/Users/jackdouglas/.cargo/bin"
              "/Users/jackdouglas/Library/pnpm"
            ];
            pathsToLink = [ "/Applications" ];
          };

          system = {
            keyboard.enableKeyMapping = true;
            keyboard.remapCapsLockToEscape = true;

            defaults = {
              NSGlobalDomain = {
                # Dark mode
                AppleInterfaceStyle = "Dark";
                # Show hidden files
                AppleShowAllFiles = true;
                # Show all file extensions
                AppleShowAllExtensions = true;
                # Automatically hide and show the menu bar
                _HIHideMenuBar = true;
                # Immediately repeat key press
                InitialKeyRepeat = 10;
                KeyRepeat = 1;
                # Disable press-and-hold
                ApplePressAndHoldEnabled = false;
                # Function keys as default
                # "com.apple.keyboard.fnState" = true;
                # Hold ctrl + cmd and drag any part of window to move
                NSWindowShouldDragOnGesture = true;
              };

              dock = {
                # Automatically hide and show the Dock
                autohide = true;
                autohide-delay = 0.0;
                autohide-time-modifier = 0.45;

                # Style options
                orientation = "left";
                show-recents = false;

                mru-spaces = false;
              };

              finder = {
                AppleShowAllExtensions = true;
                _FXShowPosixPathInTitle = true;
                _FXSortFoldersFirst = true;
                FXPreferredViewStyle = "clmv";
                ShowPathbar = true;
              };

              loginwindow.LoginwindowText = "Jack D. Douglas";

              # ctrl + scroll to zoom
              universalaccess.closeViewScrollWheelToggle = true;

              # require login immediately after sleep
              screensaver.askForPasswordDelay = 0;
            };
          };

          power.sleep = {
            computer = "never";
            display = 10;
            harddisk = "never";
          };

          # touch id sudo
          security.pam.services.sudo_local.touchIdAuth = true;

          services.jankyborders = {
            enable = true;
            package = pkgs.jankyborders;

            style = "round";
            width = 5.0;
            hidpi = true;
            active_color = "0xffe2e2e3";
            inactive_color = "0xff414550";
            blacklist = [ "Screen Studio" ];
          };

          imports = [ ./modules/aerospace.nix ];

          nixpkgs = {
            config.allowUnfree = true;
            config.input-fonts.acceptLicense = true;
            overlays = [
              (final: prev: {
                stable = import inputs.nixpkgs {
                  system = prev.system;
                  config.allowUnfree = true;
                };
              })
            ];
          };

          system.primaryUser = "jackdouglas";
          users.users.jackdouglas.home = "/Users/jackdouglas";
          home-manager.backupFileExtension = "backup";

          # Set configured group ID to match actual value
          ids.gids.nixbld = 350;

          # Auto upgrade nix package
          nix.package = pkgs.nix;

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Automatic garbage collection and store optimization
          nix.gc = {
            automatic = true;
            interval = {
              Weekday = 0;
              Hour = 2;
              Minute = 0;
            }; # Sunday at 2 AM
            options = "--delete-older-than 30d";
          };

          nix.optimise = {
            automatic = true;
            interval = {
              Weekday = 0;
              Hour = 3;
              Minute = 0;
            }; # Sunday at 3 AM
          };

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 4;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          # Use fish as default shell
          programs.fish.enable = true;
          users.knownUsers = [ "jackdouglas" ];
          users.users.jackdouglas.uid = 501;
          users.users.jackdouglas.shell = pkgs.fish;

          launchd.daemons = {
            "com.jackdouglas.kanata" = {
              serviceConfig = {
                Label = "com.jackdouglas.kanata";
                ProgramArguments = [
                  "${pkgs.kanata}/bin/kanata"
                  "--quiet"
                  "--cfg"
                  "/Users/jackdouglas/.config/kanata/kanata.kbd"
                ];
                RunAtLoad = true;
                KeepAlive = true;
                StandardOutPath = "/Library/Logs/Kanata/kanata.out.log";
                StandardErrorPath = "/Library/Logs/Kanata/kanata.err.log";
              };
            };

            "com.jackdouglas.karabiner-vhiddaemon" = {
              serviceConfig = {
                Label = "com.jackdouglas.karabiner-vhiddaemon";
                ProgramArguments = [
                  "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.
          app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"
                ];
                RunAtLoad = true;
                KeepAlive = true;
              };
            };

            "com.jackdouglas.karabiner-vhidmanager" = {
              serviceConfig = {
                Label = "com.jackdouglas.karabiner-vhidmanager";
                ProgramArguments = [
                  "/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager"
                  "activate"
                ];
                RunAtLoad = true;
              };
            };
          };

          homebrew = {
            enable = true;

            taps = [
              "FelixKratz/formulae"
              "sst/tap"
              "fastrepl/hyprnote"
              "TheBoredTeam/boring-notch"
            ];

            brews = [
              {
                name = "felixkratz/formulae/svim";
                restart_service = "changed";
              }

              "mas"
              "sst/tap/opencode"
              "ollama"
            ];

            casks = [
              "1password"
              "anki"
              "claude"
              "figma"
              "ghostty"
              "linear-linear"
              "notion"
              "obsidian"
              "proton-mail"
              "proton-mail-bridge"
              "proton-drive"
              "protonvpn"
              "soulseek"
              "homerow"
              "font-sf-pro"
              "font-sf-mono"
              "font-iosevka-ss08"
              "transmission"
              "orbstack"
              "via"
              "zen"
              "element"
              "display-pilot"
              "keymapp"
              "betterdiscord-installer"
              "plex"
              "plexamp"
              "plex-media-server"
              "karabiner-elements"
              "hyprnote"
              "clop"
              "ungoogled-chromium"
              "signal"
              "boring-notch"
              "antinote"
              "jordanbaird-ice"
            ];

            masApps = {
              "Gapplin" = 768053424;
              "Muse" = 1501563902;
              "Parcel" = 639968404;
              "Xcode" = 497799835;
              "Mona" = 1659154653;
              "Final Cut Pro" = 424389933;
              "Flighty" = 1358823008;
              "Daft Music" = 6748985865;
            };

            onActivation = {
              autoUpdate = true;
              cleanup = "zap";
              upgrade = true;
            };
          };
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#[hostname]
      darwinConfigurations."jack-tonk" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jackdouglas = import ./home.nix;
            home-manager.extraSpecialArgs = {
              inherit inputs;
              hostname = "jack-tonk";
            };
          }

          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              enableRosetta = true;

              # User owning the Homebrew prefix
              user = "jackdouglas";

              # Automatically migrate existing Homebrew installations
              # autoMigrate = true;
            };
          }
        ];
      };

      darwinConfigurations."laptop" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jackdouglas = import ./home.nix;
            home-manager.extraSpecialArgs = {
              inherit inputs;
              hostname = "laptop";
            };
          }

          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              enableRosetta = true;

              # User owning the Homebrew prefix
              user = "jackdouglas";

              # Automatically migrate existing Homebrew installations
              # autoMigrate = true;
            };
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = builtins.mapAttrs (name: config: config.pkgs) self.darwinConfigurations;
    };
}
