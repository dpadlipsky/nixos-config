{ lib, stdenvNoCC, fetchurl, zstd }:

let
  # Pinned by codex-update (packages/updaters).
  pin = lib.importJSON ./codex.json;
in
stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit (pin) version;

  src = fetchurl pin.sources.package;

  nativeBuildInputs = [ zstd ];
  dontUnpack = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/libexec/codex"
    tar -xf "$src" -C "$out/libexec/codex"
    ln -s "$out/libexec/codex/bin/"* "$out/bin/"

    runHook postInstall
  '';
}
