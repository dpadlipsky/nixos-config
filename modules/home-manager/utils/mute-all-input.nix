{ config, pkgs, lib, ... }:
with lib;

let
  mute-all-input = pkgs.writeShellScriptBin "mute-all-input" ''
    pactl list short sources | awk '{print $1}' | while read id; do mute=$(pactl get-source-mute "$id" | awk '{print $2}'); if [ "$mute" = "yes" ]; then pactl set-source-mute "$id" 0; else pactl set-source-mute "$id" 1; fi; done
  '';
in
{

  # This property is required
  options.dpad.hostLabel = mkOption {
    type = types.str;
  };

  config = {
    home.packages = [ mute-all-input ];
  };
}