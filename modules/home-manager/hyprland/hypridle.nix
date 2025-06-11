
{ pkgs, lib, config, ... }:
with lib;

let
  cfg = config.dpad.hypridle;
in
{
  options.dpad.hypridle = {
    enable = mkEnableOption (lib.mdDoc "Enable hypridle");
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.hypridle
    ];

    xdg.configFile."hypr/hypridle.conf" = {
      text = ''
        general {
            lock_cmd = pidof swaylock || swaylock
            before_sleep_cmd = loginctl lock-session
            after_sleep_cmd = hyprctl dispatch dpms on
        }

        listener {
            timeout = 60
            on-timeout = light -O && light -S 10
            on-resume = light -I
        }

        listener {
            timeout = 120
            on-timeout = loginctl lock-session
        }

        listener {
            timeout = 150
            on-timeout = hyprctl dispatch dpms off
            on-resume = hyprctl dispatch dpms on && brightnessctl -r
        }

        listener {
            timeout = 600
            on-timeout = systemctl suspend
        }

      '';
    };
  };
}
