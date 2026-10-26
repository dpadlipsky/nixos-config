{ lib, claude-code }:

# nixpkgs' build of Claude Code, pinned to the upstream release manifest
# written by claude-code-update (packages/updaters) instead of whatever
# version nixpkgs-unstable happens to carry.
claude-code.override {
  manifest = lib.importJSON ./claude-code.json;
}
