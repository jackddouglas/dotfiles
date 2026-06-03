{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  hermesPkg = inputs.hermes-agent.packages.${pkgs.system}.messaging;

  logDir = "${config.home.homeDirectory}/Library/Logs/hermes";

  # Resolves op:// references to real secrets in-memory, then execs the gateway.
  # op:// references are not secrets, so embedding them here is safe.
  gatewayLauncher = pkgs.writeShellApplication {
    name = "hermes-gateway-launch";
    runtimeInputs = [
      pkgs._1password-cli
      hermesPkg
    ];
    text = ''
      # Declare then export separately (shellcheck SC2155): keeps op's exit
      # status, so a failed read aborts under set -e and launchd retries.
      OPENROUTER_API_KEY="$(op read 'op://Personal/OpenRouter Hermes/credential')"
      export OPENROUTER_API_KEY
      TELEGRAM_BOT_TOKEN="$(op read 'op://Personal/Hermes Telegram Bot/credential')"
      export TELEGRAM_BOT_TOKEN
      TAVILY_API_KEY="$(op read 'op://Personal/Tavily_API_Key/credential')"
      export TAVILY_API_KEY
      export TELEGRAM_ALLOWED_USERS="6659591467"
      mkdir -p "${logDir}"
      exec hermes gateway run
    '';
  };
in
{
  home.packages = [ hermesPkg ];

  # Manage only the static files; leave Hermes' mutable state (memories/, skills/,
  # auth.json, cron store, .env) untouched.
  home.file = {
    ".hermes/config.yaml".source = ../hermes/config.yaml;
    ".hermes/SOUL.md".source = ../hermes/SOUL.md;
    # Ensure the launchd log dir exists before the agent's StandardOut/ErrPath FDs open.
    "Library/Logs/hermes/.keep".text = "";
  };

  launchd.agents.hermes-gateway = {
    enable = true;
    config = {
      ProgramArguments = [ "${gatewayLauncher}/bin/hermes-gateway-launch" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${logDir}/gateway.out.log";
      StandardErrorPath = "${logDir}/gateway.err.log";
      EnvironmentVariables = {
        HOME = config.home.homeDirectory;
        PATH =
          lib.makeBinPath [
            pkgs.coreutils
            pkgs.bash
            pkgs.nodejs_22
          ]
          + ":/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };
}
