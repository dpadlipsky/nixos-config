{ config, pkgs, lib, ... }:
with lib;

let
  cfg = config.dpad.waybar;
in
{
  options.dpad.waybar.enable = mkEnableOption (lib.mdDoc "Enable waybar");

  config = mkIf cfg.enable {
    programs.waybar.enable = true;

    # TODO: Convert to non-text based config
    xdg.configFile."waybar/config".text = ''
    {
        "layer": "bottom",
        "margin": "5 5 0 5",
        "height": 30,

        "modules-left": ["hyprland/workspaces"],
        "modules-center": ["clock"],
        "modules-right": ["battery", "pulseaudio"],
        "clock": {
            "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
            "format": "{:%a, %d %b, %I:%M %p}"
        },
        "battery": {
            "interval": 15,
            "states": {
                "warning": 30,
                "critical": 15
            },
            "format": "{icon}  {capacity}%",
            "format-charging": "󱐋 {capacity}%",
            "format-plugged": "󱐋 {capacity}%",
            "format-icons": ["", "", "", "", ""],
            "tooltip-format": "Battery: {capacity}% ({time})"
        },
        "pulseaudio": {
            "format": "{icon}  {volume}%  {format_source}",
            "format-muted": "{icon} 0%",
            "format-source": " {volume}%",
            "format-source-muted": " {volume}%",
            "format-icons": {
                "headphone": "",
                "hands-free": "",
                "headset": "",
                "phone": "",
                "portable": "",
                "car": "",
                "default": ["", "", ""]
            },
            "on-click": "hyprctl dispatch exec [floating] pavucontrol",
            "min-length": 13,
        },
    }
    '';

    # TODO: Convert to non-text based config
    xdg.configFile."waybar/style.css".text = ''
    * {
        border: none;
        border-radius: 0;
        font-family: "JetBrainsMono Nerd Font", "Liberation Mono", monospace;
        min-height: 20px;
    }

    window#waybar {
        background: transparent;
    }

    window#waybar.hidden {
        opacity: 0.2;
    }

    #workspaces {
        margin-right: 8px;
        border-radius: 10px;
        transition: all 0.5s ease-out;
        background: rgba(56, 60, 74, .3);
    }

    #workspaces button {
        transition: none;
        color: #7c818c;
        background: transparent;
        padding: 5px;
        font-size: 18px;
    }

    #workspaces button:hover {
        transition: none;
        box-shadow: inherit;
        text-shadow: inherit;
        border-radius: inherit;
        color: #383c4a;
        background: rgba(56, 60, 74, .3);
    }

    #workspaces button.focused,
    #workspaces button.active {
        color: white;
    }

    #clock {
        padding-left: 8px;
        padding-right: 8px;
        border-radius: 10px;
        transition: none;
        color: #ffffff;
        background: rgba(56, 60, 74, .3);
    }

    #battery {
        padding-left: 8px;
        padding-right: 8px;
        margin-right: 8px;
        border-radius: 10px;
        transition: none;
        color: #ffffff;
        background: rgba(56, 60, 74, .3);
    }

    #pulseaudio {
        padding-left: 8px;
        padding-right: 8px;
        border-radius: 10px;
        transition: none;
        color: #ffffff;
        background: rgba(56, 60, 74, .3);
    }

    #pulseaudio.muted {
        background-color: #90b1b1;
        color: #2a5c45;
    }
    '';
  };
}