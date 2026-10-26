{ lib, writeShellApplication, symlinkJoin, curl, jq, git, gh }:

let
  # Every ./<name>-update.sh becomes a <name>-update command, with lib.sh
  # prepended for the shared update/commit/PR flow.
  scripts = lib.filterAttrs (file: _: lib.hasSuffix "-update.sh" file) (builtins.readDir ./.);

  mkUpdater = file: writeShellApplication {
    name = lib.removeSuffix ".sh" file;
    runtimeInputs = [ curl jq git gh ];
    text = builtins.readFile ./lib.sh + builtins.readFile (./. + "/${file}");
  };

  updaters = map mkUpdater (builtins.attrNames scripts);

  # `update` runs them all, merges their PRs, and runs nix-rebuild (which
  # comes from the home-manager utils module, so it's taken from PATH).
  update = writeShellApplication {
    name = "update";
    runtimeInputs = [ git ] ++ updaters;
    text = ''
      updaters=(${lib.escapeShellArgs (map (u: u.name) updaters)})
    '' + builtins.readFile ./update.sh;
  };
in
symlinkJoin {
  name = "updaters";
  paths = updaters ++ [ update ];
}
