{ config, pkgs, ... }:

let
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
  services.kanata = {
    enable = true;
    keyboards = {
      internalKeyboard = {
        devices = [
          "/dev/input/by-path/platform-i8042-serio-0-event-kbd"
        ];
        extraDefCfg = "process-unmapped-keys no";
        config = kanataConfig;
      };
    };
  };

  services.udev.extraRules = ''
    KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
  '';

  hardware.uinput.enable = true;
}
