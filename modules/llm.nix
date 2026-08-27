{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  host = "127.0.0.1";

  llamaCpp = pkgs.llama-cpp.overrideAttrs (old: {
    version = "0.3.0";
    src = inputs.llama-cpp-src;
    npmDepsHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
    postPatch = (old.postPatch or "") + ''
      echo ${inputs.llama-cpp-src.shortRev} > COMMIT
    '';
    cmakeFlags = old.cmakeFlags ++ [
      (lib.cmakeFeature "LLAMA_BUILD_NUMBER" "0")
      (lib.cmakeBool "LLAMA_BUILD_IS_DEV" false)
    ];
  });

  mkServer =
    {
      name,
      modelFile,
      mmprojFile ? null,
      alias,
      port,
      ctxSize,
      fetcher,
      serverArgs ? [ ],
    }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ llamaCpp ];
      text = ''
        MODEL_PATH="$HOME/models/${modelFile}"
        if [ ! -f "$MODEL_PATH" ]; then
          echo "${name}: model not found at $MODEL_PATH" >&2
          echo "${name}: run '${fetcher}' first" >&2
          exit 1
        fi
        mmproj_args=()
        ${lib.optionalString (mmprojFile != null) ''
          MMPROJ_PATH="$HOME/models/${mmprojFile}"
          if [ -f "$MMPROJ_PATH" ]; then
            mmproj_args=(--mmproj "$MMPROJ_PATH")
          else
            echo "${name}: mmproj not found at $MMPROJ_PATH; serving text-only" >&2
            echo "${name}: run '${fetcher}' to enable images" >&2
          fi
        ''}
        exec llama-server \
          --model "$MODEL_PATH" \
          --alias "${alias}" \
          --host "${host}" \
          --port "${port}" \
          --ctx-size "${ctxSize}" \
          --jinja \
          ${lib.escapeShellArgs serverArgs} \
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
      alias = "qwen3.8-27b";
      port = "17171";
      ctxSize = "131072";
      serverArgs = [
        "--parallel"
        "1"
        "--cache-type-k"
        "f16"
        "--cache-type-v"
        "f16"
        "--flash-attn"
        "on"
        "--load-mode"
        "mmap"
      ];
      repo = "https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main";
      modelFile = "Qwen3.8-27B-UD-Q4_K_XL.gguf";
      modelDesc = "~17.6 GB";
    }
    {
      serverName = "gemma-server";
      fetcherName = "fetch-gemma-model";
      alias = "gemma-4-26b";
      port = "17172";
      ctxSize = "262144";
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
        alias
        port
        ctxSize
        ;
      serverArgs = m.serverArgs or [ ];
      mmprojFile = m.mmprojFile or null;
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
      ]
      ++ lib.optional (m ? mmprojFile) {
        file = m.mmprojFile;
        url = "${m.repo}/${m.mmprojRemote or m.mmprojFile}";
        desc = m.mmprojDesc;
      };
    }
  ) models;
in
{
  home.packages = [ llamaCpp ] ++ serverPkgs ++ fetcherPkgs;
}
