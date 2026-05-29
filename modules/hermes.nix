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
      export OPENROUTER_API_KEY="$(op read 'op://Tonk/OpenRouter/credential')"        # <- OP_OPENROUTER_REF
      export TELEGRAM_BOT_TOKEN="$(op read 'op://Tonk/Hermes Telegram Bot/credential')" # <- OP_TELEGRAM_REF
      export TAVILY_API_KEY="$(op read 'op://Personal/Tavily_API_Key/credential')"     # <- OP_TAVILY_REF
      export TELEGRAM_ALLOWED_USERS="REPLACE_WITH_TELEGRAM_USER_ID"                     # <- TELEGRAM_USER_ID
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
            pkgs._1password-cli
            pkgs.coreutils
            pkgs.bash
          ]
          + ":/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };
}
