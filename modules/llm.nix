{ pkgs, lib, ... }:
let
  host = "127.0.0.1";

  mkServer =
    {
      name,
      modelFile,
      mmprojFile,
      alias,
      port,
      ctxSize,
      fetcher,
    }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.llama-cpp ];
      text = ''
        MODEL_PATH="$HOME/models/${modelFile}"
        if [ ! -f "$MODEL_PATH" ]; then
          echo "${name}: model not found at $MODEL_PATH" >&2
          echo "${name}: run '${fetcher}' first" >&2
          exit 1
        fi
        MMPROJ_PATH="$HOME/models/${mmprojFile}"
        mmproj_args=()
        if [ -f "$MMPROJ_PATH" ]; then
          mmproj_args=(--mmproj "$MMPROJ_PATH")
        else
          echo "${name}: mmproj not found at $MMPROJ_PATH; serving text-only" >&2
          echo "${name}: run '${fetcher}' to enable images" >&2
        fi
        exec llama-server \
          --model "$MODEL_PATH" \
          --alias "${alias}" \
          --host "${host}" \
          --port "${port}" \
          --ctx-size "${ctxSize}" \
          --jinja \
          "''${mmproj_args[@]}" \
          "$@"
      '';
    };

  mkFetcher =
    { name, files }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.curl ];
      text = ''
        MODEL_DIR="$HOME/models"
        mkdir -p "$MODEL_DIR"

        fetch_file() {
          local file="$1" url="$2" desc="$3"
          local dest="$MODEL_DIR/$file"
          if [ -f "$dest" ]; then
            echo "${name}: already present at $dest"
            return 0
          fi
          echo "${name}: downloading $file ($desc) to $MODEL_DIR"
          curl -fL --progress-bar \
            -C - \
            --retry 20 \
            --retry-delay 5 \
            --retry-all-errors \
            --connect-timeout 30 \
            --speed-time 60 --speed-limit 1024 \
            -o "$dest.part" "$url"
          mv "$dest.part" "$dest"
        }

        ${lib.concatMapStringsSep "\n" (f: ''fetch_file "${f.file}" "${f.url}" "${f.desc}"'') files}
      '';
    };

  models = [
    {
      serverName = "qwen-server";
      fetcherName = "fetch-qwen-model";
      alias = "qwen3.6-27b";
      port = "17171";
      ctxSize = "32768";
      repo = "https://huggingface.co/unsloth/Qwen3.6-27B-GGUF/resolve/main";
      modelFile = "Qwen3.6-27B-UD-Q4_K_XL.gguf";
      modelDesc = "~17.6 GB";
      mmprojFile = "mmproj-F16.gguf";
      mmprojDesc = "~0.9 GB, vision projector";
    }
    {
      serverName = "gemma-server";
      fetcherName = "fetch-gemma-model";
      alias = "gemma-4-26b";
      port = "17172";
      ctxSize = "16384";
      repo = "https://huggingface.co/unsloth/gemma-4-26B-A4B-it-GGUF/resolve/main";
      modelFile = "gemma-4-26B-A4B-it-UD-Q4_K_XL.gguf";
      modelDesc = "~16 GB";
      # remote projector is named mmproj-F16.gguf; saved locally as
      # gemma-4-mmproj-F16.gguf to avoid colliding with qwen's projector.
      mmprojFile = "gemma-4-mmproj-F16.gguf";
      mmprojRemote = "mmproj-F16.gguf";
      mmprojDesc = "~1.2 GB, vision projector";
    }
  ];

  serverPkgs = map (
    m:
    mkServer {
      name = m.serverName;
      inherit (m)
        modelFile
        mmprojFile
        alias
        port
        ctxSize
        ;
      fetcher = m.fetcherName;
    }
  ) models;

  fetcherPkgs = map (
    m:
    mkFetcher {
      name = m.fetcherName;
      files = [
        {
          file = m.modelFile;
          url = "${m.repo}/${m.modelFile}";
          desc = m.modelDesc;
        }
        {
          file = m.mmprojFile;
          url = "${m.repo}/${m.mmprojRemote or m.mmprojFile}";
          desc = m.mmprojDesc;
        }
      ];
    }
  ) models;
in
{
  home.packages = [ pkgs.llama-cpp ] ++ serverPkgs ++ fetcherPkgs;
}
