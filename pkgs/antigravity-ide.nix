{ lib, fetchurl, antigravity-ide, buildVscode }:

# nixpkgs' build of the Antigravity IDE, pinned to the release written by
# antigravity-ide-update (packages/updaters) instead of whatever version
# nixpkgs-unstable happens to carry.
let
  pin = lib.importJSON ./antigravity-ide.json;
in
antigravity-ide.override {
  buildVscode =
    args:
    buildVscode (
      args
      // {
        inherit (pin) version vscodeVersion;
        src = fetchurl { inherit (pin) url sha256; };
      }
    );
}
