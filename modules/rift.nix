{ pkgs, inputs, ... }:
let
  rift = pkgs.stdenv.mkDerivation {
    pname = "rift";
    version = "unstable";

    src = inputs.rift;

    nativeBuildInputs = [ pkgs.gnumake ];

    buildInputs = [
      pkgs.apple-sdk
      pkgs.readline
    ];

    buildPhase = ''
      mkdir -p bin
      # Build Lua 5.4 static library
      cd lua-5.4.7
      make macosx CC="cc -std=gnu99 -arch arm64"
      cp src/liblua.a ../bin/
      cd ..
      # Build rift.so shared library
      cc -std=c99 -O3 -g -shared -fPIC \
        -arch arm64 \
        src/rift.c src/cJSON.c src/parsing.c \
        -Ilua-5.4.7/src -Lbin -llua \
        -framework CoreFoundation \
        -o bin/rift.so
    '';

    installPhase = ''
      mkdir -p $out/lib
      cp bin/rift.so $out/lib/
    '';
  };
in
{
  # Make rift.so available at a known path for sketchybar to load
  home.file.".local/share/rift.lua/rift.so" = {
    source = "${rift}/lib/rift.so";
  };

  # Run rift as a launchd user agent
  launchd.agents.rift = {
    enable = true;
    config = {
      Label = "com.acsandmann.rift";
      ProgramArguments = [ "/opt/homebrew/bin/rift" ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/rift.out.log";
      StandardErrorPath = "/tmp/rift.err.log";
      EnvironmentVariables = {
        PATH = "/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };
}
