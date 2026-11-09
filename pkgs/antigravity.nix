{ lib, fetchurl, antigravity-hub }:

# nixpkgs' build of the Antigravity app (antigravity-hub), pinned to the
# release written by antigravity-update (packages/updaters) instead of
# whatever version nixpkgs-unstable happens to carry.
let
  pin = lib.importJSON ./antigravity.json;
in
antigravity-hub.overrideAttrs {
  inherit (pin) version;
  src = fetchurl pin.sources.linux-x64;
}
