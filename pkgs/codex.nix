{ lib, stdenvNoCC, fetchurl, zstd }:

let
  # Pinned by codex-update (packages/updaters).
  pin = lib.importJSON ./codex.json;
in
stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit (pin) version;

  src = fetchurl pin.sources.cli;
  hostArchive = fetchurl pin.sources.host;

  nativeBuildInputs = [ zstd ];
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    install -Dm755 codex-x86_64-unknown-linux-musl $out/bin/codex
    zstd -dc "$hostArchive" > "$out/bin/codex-code-mode-host"
    chmod 755 "$out/bin/codex-code-mode-host"

    runHook postInstall
  '';
}
