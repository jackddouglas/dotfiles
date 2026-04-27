{ pkgs, ... }:
let
  modelFile = "Qwen3.6-27B-UD-Q4_K_XL.gguf";
  modelUrl = "https://huggingface.co/unsloth/Qwen3.6-27B-GGUF/resolve/main/${modelFile}";
  alias = "qwen3.6-27b";
  host = "127.0.0.1";
  port = "17171";
  ctxSize = "32768";

  gemmaModel = "unsloth/gemma-4-26b-a4b-it-UD-MLX-4bit";
  gemmaHost = "127.0.0.1";
  gemmaPort = "17172";

  webuiHost = "127.0.0.1";
  webuiPort = "17170";

  qwenServer = pkgs.writeShellApplication {
    name = "qwen-server";
    runtimeInputs = [ pkgs.llama-cpp ];
    text = ''
      MODEL_PATH="$HOME/models/${modelFile}"
      if [ ! -f "$MODEL_PATH" ]; then
        echo "qwen-server: model not found at $MODEL_PATH" >&2
        echo "qwen-server: run 'fetch-qwen-model' first" >&2
        exit 1
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

  mlxPython = pkgs.python313.withPackages (ps: [ ps.mlx-vlm ]);

  gemmaServer = pkgs.writeShellApplication {
    name = "gemma-server";
    runtimeInputs = [ mlxPython ];
    text = ''
      exec python -m mlx_vlm.server \
        --model "${gemmaModel}" \
        --host "${gemmaHost}" \
        --port "${gemmaPort}" \
        "$@"
    '';
  };

  openWebui = pkgs.writeShellApplication {
    name = "open-webui-server";
    runtimeInputs = [ pkgs.uv ];
    text = ''
      export DATA_DIR="''${DATA_DIR:-$HOME/.local/share/open-webui}"
      export ENABLE_OLLAMA_API="''${ENABLE_OLLAMA_API:-False}"
      export WEBUI_AUTH="''${WEBUI_AUTH:-False}"
      export OPENAI_API_BASE_URLS="''${OPENAI_API_BASE_URLS:-http://${gemmaHost}:${gemmaPort}/v1;http://${host}:${port}/v1}"
      export OPENAI_API_KEYS="''${OPENAI_API_KEYS:-local;local}"
      mkdir -p "$DATA_DIR"
      exec uvx --from open-webui open-webui serve \
        --host "${webuiHost}" --port "${webuiPort}" "$@"
    '';
  };
in
{
  home.packages = [
    pkgs.llama-cpp
    qwenServer
    fetchQwenModel
    gemmaServer
    openWebui
  ];
}
