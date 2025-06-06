{ config, pkgs, lib, ... }:
with lib;

let
  cfg = config.dpad.kanata;

  kanataConfig = ''
    (defsrc
        caps lmet lalt)

    (deflayermap (default-layer)
        caps lctl
        lmet lalt
        lalt lmet)
  '';
in
{
  options.dpad.kanata = {
    internalKeyboard = mkOption {
      type = types.str;
    };
  };

  config = {
    services.kanata = {
      enable = true;
      keyboards = {
        internalKeyboard = {
          devices = [
            cfg.internalKeyboard
          ];
          config = kanataConfig;
        };
      };
    };

    services.udev.extraRules = ''
      KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
    '';

    hardware.uinput.enable = true;
  };
}
