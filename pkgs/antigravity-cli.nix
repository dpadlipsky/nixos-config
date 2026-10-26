{ lib, stdenv, fetchurl, autoPatchelfHook }:

let
  # Upstream release manifest, pinned by agy-update (packages/updaters).
  manifest = lib.importJSON ./antigravity-cli.json;
in
stdenv.mkDerivation {
  pname = "antigravity-cli";
  inherit (manifest) version;

  src = fetchurl {
    inherit (manifest) url sha512;
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  sourceRoot = ".";
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 antigravity $out/bin/agy
    runHook postInstall
  '';

  meta = {
    description = "Google Antigravity command-line coding agent";
    homepage = "https://antigravity.google/product/antigravity-cli";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "agy";
  };
}
