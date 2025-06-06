{ config, pkgs, ... }:

let
  kanataConfig = ''
    (defsrc
        caps)

    (deflayermap (default-layer)
        ;; tap caps lock as caps lock, hold caps lock as left control
        caps lctl)
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
