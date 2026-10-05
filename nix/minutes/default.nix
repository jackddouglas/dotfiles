{ pkgs }:
let
  pins = builtins.fromJSON (builtins.readFile ./sources.json);
  sources = builtins.mapAttrs (_: pin: pkgs.fetchFromGitHub pin) pins;
  nemo = pkgs.fetchurl {
    url = "https://github.com/FluidInference/text-processing-rs/releases/download/v0.3.1/NemoTextProcessing.xcframework.zip";
    hash = "sha256-X6jBDU7CbBuyQTEl81GnIipMaKI7dEdmgPutp+Jvxqo=";
  };
  workspace = builtins.fromJSON (builtins.readFile ./workspace-state.json);
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "minutes";
  version = "unstable-2026-10-05";
  src = sources.minutes;

  # Swift 6 and Icon Composer require this Mac's selected Xcode toolchain.
  # Keep the signed bundle intact after packaging.
  dontFixup = true;
  nativeBuildInputs = [ pkgs.unzip ];
  configurePhase = ''
    runHook preConfigure
    mkdir -p .build/checkouts
    cp ${./workspace-state.json} .build/workspace-state.json
    mkdir -p .build/artifacts/fluidaudio/NemoTextProcessing
    unzip -q ${nemo} -d .build/artifacts/fluidaudio/NemoTextProcessing
    substituteInPlace .build/workspace-state.json \
      --replace-fail '@artifactPath@' "$PWD/.build/artifacts/fluidaudio/NemoTextProcessing/NemoTextProcessing.xcframework"
    ${pkgs.lib.concatMapStringsSep "\n" (dep: ''
      ln -s ${sources.${dep.packageRef.identity}} .build/checkouts/${dep.subpath}
    '') workspace.object.dependencies}
    substituteInPlace scripts/build-app.sh \
      --replace-fail 'build -c' 'build --disable-sandbox --skip-update --disable-automatic-resolution -c'
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    export PATH="$PATH:/usr/bin:/bin:/usr/sbin:/sbin"
    export CLANG_MODULE_CACHE_PATH="$TMPDIR/clang-module-cache"
    export SWIFTPM_MODULECACHE_OVERRIDE="$TMPDIR/swift-module-cache"
    /bin/bash scripts/build-app.sh release
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R dist/Minutes.app $out/Applications/
    runHook postInstall
  '';
}
