{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
let
  aerohints = inputs.aerohints.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home.packages = [ aerohints ];

  launchd.agents.aerohints = {
    enable = false;
    config = {
      Label = "com.jackdouglas.aerohints";
      ProgramArguments = [
        "${aerohints}/bin/AeroHints"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/aerohints/aerohints.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/aerohints/aerohints.error.log";
      EnvironmentVariables = {
        HOME = config.home.homeDirectory;
        PATH = "/usr/bin:/bin:/opt/homebrew/bin";
      };
    };
  };

  home.activation.createAeroHintsLogs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${config.home.homeDirectory}/Library/Logs/aerohints
    touch ${config.home.homeDirectory}/Library/Logs/aerohints/aerohints.log
    touch ${config.home.homeDirectory}/Library/Logs/aerohints/aerohints.error.log
  '';

  programs.fish.shellAliases = {
    "aerohints-status" = "launchctl list | grep aerohints";
    "aerohints-logs" = "tail -f ~/Library/Logs/aerohints/aerohints.log";
    "aerohints-errors" = "tail -f ~/Library/Logs/aerohints/aerohints.error.log";
  };
}
