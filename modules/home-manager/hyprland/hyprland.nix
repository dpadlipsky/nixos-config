{ config, pkgs, lib, ... }:
with lib;

let
  cfg = config.dpad.hyprland;
in
{
  options.dpad.hyprland = {
    enable = mkEnableOption (lib.mdDoc "Enable hyprland");

    sensitivity = mkOption {
      type = types.number;
      default = -0.5;
    };

    animations.enable = mkEnableOption (lib.mdDoc "Enable hyprland animations");
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      configType = "hyprlang";
    };

    home.packages = [
      pkgs.nautilus
      # Screenshots and synthetic input for agents driving the desktop
      # (agent-config's hyprland-desktop skill).
      pkgs.grim
      pkgs.slurp
      pkgs.wtype
      pkgs.wlrctl
      pkgs.jq
    ];

    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

    # Dark Tokyo Night look for Nautilus (GTK 4) and the portal's file picker (GTK 3),
    # matching kitty's tokyo_night_night theme.
    gtk = let
      tokyoNight = ''
        @define-color accent_color #7aa2f7;
        @define-color accent_bg_color #7aa2f7;
        @define-color accent_fg_color #1a1b26;
        @define-color destructive_color #f7768e;
        @define-color destructive_bg_color #f7768e;
        @define-color destructive_fg_color #1a1b26;
        @define-color success_color #9ece6a;
        @define-color warning_color #e0af68;
        @define-color error_color #f7768e;
        @define-color window_bg_color #1a1b26;
        @define-color window_fg_color #c0caf5;
        @define-color view_bg_color #1a1b26;
        @define-color view_fg_color #c0caf5;
        @define-color headerbar_bg_color #16161e;
        @define-color headerbar_fg_color #c0caf5;
        @define-color headerbar_backdrop_color #16161e;
        @define-color sidebar_bg_color #16161e;
        @define-color sidebar_fg_color #a9b1d6;
        @define-color sidebar_backdrop_color #16161e;
        @define-color card_bg_color #24283b;
        @define-color card_fg_color #c0caf5;
        @define-color dialog_bg_color #1f2335;
        @define-color dialog_fg_color #c0caf5;
        @define-color popover_bg_color #1f2335;
        @define-color popover_fg_color #c0caf5;
      '';
    in {
      enable = true;
      colorScheme = "dark";
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme.override { color = "blue"; };
      };
      gtk3.extraCss = tokyoNight;
      gtk4.theme = null;
      gtk4.extraCss = tokyoNight;
    };

    wayland.windowManager.hyprland.settings = {
      # TODO: Define monitors dynamically based on host
      monitor = [
        "eDP-1,preferred,auto,2"
        "DP-3,preferred,-1920x0,2"
        "HDMI-A-1,preferred,0x0,2"
        "DP-2,highrr,auto,1.3333"
        ",preferred,auto,auto"
      ];

      exec-once = [
        "hyprpaper"
        "waybar"
        "systemctl --user start hyprpolkitagent"
        "systemctl --user start hypridle.service"
      ];

      env = [
        "XCURSOR_SIZE,24"
        "WLR_NO_HARDWARE_CURSORS,1"
      ];

      input = {
          kb_layout = "us";
          follow_mouse = true;
          touchpad = {
            natural_scroll = false;
            tap-and-drag = false;
          };
          sensitivity = cfg.sensitivity;
          repeat_rate = 40;
          repeat_delay = 300;
      };

      general = {
          gaps_in = 5;
          gaps_out = 5;
          border_size = 2;
          "col.active_border" = "rgba(ffffffa0)";
          "col.inactive_border" = "rgba(ffffff00)";
          layout = "dwindle";
          allow_tearing = false;
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };

        shadow = {
          enabled = true;
          color = "rgba(1a1a1aee)";
          range = 4;
          render_power = 3;
        };
      };

      animations = {
          enabled = cfg.animations.enable;

          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
          animation = [
            "windows, 1, 7, myBezier"
            "windowsOut, 1, 7, default, popin 80%"
            "border, 1, 10, default"
            "borderangle, 1, 8, default"
            "fade, 1, 7, default"
            "workspaces, 1, 6, default"
          ];
      };

      dwindle = {
          preserve_split = true;
      };

      master = {
        new_status = "master";
      };

      misc = {
        force_default_wallpaper = 0;
        disable_splash_rendering = true;
      };

      debug = {
        damage_tracking = 0;
        vfr = false;
      };

#      opengl = { nvidia_anti_flicker = 0; force_introspection = 2; };

      "$mainMod" = "SUPER";

      bind = [
        "$mainMod, RETURN, exec, kitty"
        "$mainMod, Q, killactive,"
        "$mainMod SHIFT, L, exit,"
        "$mainMod, H, togglefloating,"
        "$mainMod, SPACE, exec, rofi -show drun"
        "$mainMod, E, exec, nautilus"
        "$mainMod, P, pseudo, # dwindle"
        "$mainMod, J, layoutmsg, togglesplit # dwindle"
        "$mainMod CTRL, F, fullscreen, 0"
        # TODO: Once 0.36.0 comes out change this to 2 and remove Meta + Ctrl + F shortcut
        "$mainMod, F, fullscreen, 1"
        "$mainMode, L, exec, swaylock"

        # Move focus with mainMod + arrow keys
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # Move windows directionally
        "$mainMod SHIFT, left, movewindow, l"
        "$mainMod SHIFT, right, movewindow, r"
        "$mainMod SHIFT, up, movewindow, u"
        "$mainMod SHIFT, down, movewindow, d"

        # Move to left/right workspaces with brackets
        "$mainMod, code:34, workspace, -1"
        "$mainMod, code:35, workspace, +1"

        # Switch workspaces with mainMod + [0-9]
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        # Move active window to a workspace with mainMod + SHIFT + [0-9]
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        # Example special workspace (scratchpad)
        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"

        # Scroll through existing workspaces with mainMod + scroll
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"

        "$mainMod, M, exec, mute-all-input"
      ];

      bindr = [
        # Brightness controls
        ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

      bindm = [
        # Move/resize windows with mainMod + LMB/RMB and dragging
        "$mainMod, mouse:272, movewindow"
        "$mainMod SHIFT, mouse:272, resizewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
  };
}
