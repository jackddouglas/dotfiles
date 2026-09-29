{ pkgs }:

let
  # Quill needs Swift 6, so compile it with this Mac's selected Xcode toolchain.
  quill-generated = pkgs.swiftPackages.swiftpm2nix.helpers ./quill;
in
{
  parrot-app = pkgs.stdenvNoCC.mkDerivation {
    pname = "parrot";
    version = "0.2.1";

    src = pkgs.fetchurl {
      url = "https://github.com/humanitas-labs/parrot/releases/download/v0.2.1/Parrot.dmg";
      hash = "sha256-j5VyfIexq6SSSItg7VUtnHuoartiGldEXA1oFq9AaaY=";
    };

    nativeBuildInputs = [ pkgs.undmg ];
    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out/Applications
      cp -R Parrot.app $out/Applications/
    '';
  };

  quill-app = pkgs.stdenvNoCC.mkDerivation {
    pname = "quill";
    version = "unstable-2026-09-27";

    src = pkgs.fetchFromGitHub {
      owner = "humanitas-labs";
      repo = "quill";
      rev = "aad60f98e680720dd24a30115580f226ae36c12c";
      hash = "sha256-7iUB44hB1VAiS5TZtJVMifJ+iQjIE9MMxwAlDR5yti8=";
    };

    sourceRoot = "source/macos";
    configurePhase = quill-generated.configure;

    buildPhase = ''
      runHook preBuild
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      /usr/bin/swift build --disable-sandbox --skip-update --disable-automatic-resolution \
        -c release --target quill -j "$NIX_BUILD_CORES"
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin $out/Applications/Quill.app/Contents/MacOS
      install -m755 "$(/usr/bin/swift build --disable-sandbox -c release --show-bin-path)/quill" $out/bin/quill
      ln -s $out/bin/quill $out/Applications/Quill.app/Contents/MacOS/quill
      cp Sources/quill/Info.plist $out/Applications/Quill.app/Contents/Info.plist
      /usr/libexec/PlistBuddy -c 'Add :CFBundleExecutable string quill' $out/Applications/Quill.app/Contents/Info.plist
      /usr/libexec/PlistBuddy -c 'Add :CFBundlePackageType string APPL' $out/Applications/Quill.app/Contents/Info.plist
      /usr/libexec/PlistBuddy -c 'Add :LSUIElement bool true' $out/Applications/Quill.app/Contents/Info.plist
      runHook postInstall
    '';
  };
}
