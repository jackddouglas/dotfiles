{ pkgs, ... }:
let
  modelFile = "Qwen3.6-27B-UD-Q4_K_XL.gguf";
  modelUrl = "https://huggingface.co/unsloth/Qwen3.6-27B-GGUF/resolve/main/${modelFile}";
  alias = "qwen3.6-27b";
  host = "127.0.0.1";
  port = "8080";
  ctxSize = "32768";

  qwenServer = pkgs.writeShellApplication {
    name = "qwen-server";
    runtimeInputs = [ pkgs.llama-cpp ];
    text = ''
      MODEL_PATH="$HOME/models/${modelFile}"
      if [ ! -f "$MODEL_PATH" ]; then
        echo "qwen-server: model not found at $MODEL_PATH" >&2
        echo "qwen-server: run 'fetch-qwen-model' first, then" >&2
        echo "             'launchctl kickstart -k gui/$UID/com.jackdouglas.qwen-server'" >&2
        exit 0
      fi
      exec llama-server \
        --model "$MODEL_PATH" \
        --alias "${alias}" \
        --host "${host}" \
        --port "${port}" \
        --ctx-size "${ctxSize}" \
        --jinja \
        "$@"
    '';
  };

  fetchQwenModel = pkgs.writeShellApplication {
    name = "fetch-qwen-model";
    runtimeInputs = [ pkgs.curl ];
    text = ''
      MODEL_DIR="$HOME/models"
      MODEL_PATH="$MODEL_DIR/${modelFile}"
      mkdir -p "$MODEL_DIR"
      if [ -f "$MODEL_PATH" ]; then
        echo "fetch-qwen-model: already present at $MODEL_PATH"
        exit 0
      fi
      echo "fetch-qwen-model: downloading ${modelFile} (~17.6 GB) to $MODEL_DIR"
      curl -fL --progress-bar \
        -C - \
        --retry 20 \
        --retry-delay 5 \
        --retry-all-errors \
        --connect-timeout 30 \
        --speed-time 60 --speed-limit 1024 \
        -o "$MODEL_PATH.part" "${modelUrl}"
      mv "$MODEL_PATH.part" "$MODEL_PATH"
    '';
  };
in
{
  home.packages = [
    pkgs.llama-cpp
    qwenServer
    fetchQwenModel
  ];

  launchd.agents.qwen-server = {
    enable = true;
    config = {
      Label = "com.jackdouglas.qwen-server";
      ProgramArguments = [ "${qwenServer}/bin/qwen-server" ];
      RunAtLoad = true;
      KeepAlive = {
        SuccessfulExit = false;
        Crashed = true;
      };
      ProcessType = "Interactive";
      StandardOutPath = "/Users/jackdouglas/Library/Logs/qwen-server/out.log";
      StandardErrorPath = "/Users/jackdouglas/Library/Logs/qwen-server/err.log";
    };
  };

  home.activation.qwen-server-logs = ''
    /bin/mkdir -p "$HOME/Library/Logs/qwen-server"
  '';
}
