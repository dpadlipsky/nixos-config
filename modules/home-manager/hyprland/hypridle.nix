
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
      # hypridle reads its configuration at startup, so reload it after activation.
      onChange = ''
        ${pkgs.systemd}/bin/systemctl --user try-restart hypridle.service
      '';
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
            # Only suspend automatically when running on battery.
            on-timeout = ${pkgs.systemd}/bin/systemd-ac-power || ${pkgs.systemd}/bin/systemctl suspend
        }

      '';
    };
  };
}
