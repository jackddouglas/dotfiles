{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    ollama
  ];

  # Create the launchd service for Ollama
  launchd.agents.ollama = {
    enable = true;
    config = {
      Label = "com.user.ollama";
      ProgramArguments = [
        "${pkgs.ollama}/bin/ollama"
        "serve"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/ollama/ollama.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/ollama/ollama.error.log";
      EnvironmentVariables = {
        HOME = config.home.homeDirectory;
        PATH = lib.makeBinPath [ pkgs.ollama ];
      };
    };
  };

  # Ensure log directory exists
  home.activation.createOllamaLogs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${config.home.homeDirectory}/Library/Logs/ollama
    touch ${config.home.homeDirectory}/Library/Logs/ollama/ollama.log
    touch ${config.home.homeDirectory}/Library/Logs/ollama/ollama.error.log
  '';

  programs.fish.shellAliases = {
    "ollama-status" = "launchctl list | grep ollama";
    "ollama-logs" = "tail -f ~/Library/Logs/ollama/ollama.log";
    "ollama-errors" = "tail -f ~/Library/Logs/ollama/ollama.error.log";
  };
}
