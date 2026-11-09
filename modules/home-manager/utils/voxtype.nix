{ config, pkgs, lib, ... }:
with lib;

let
  cfg = config.dpad.voxtype;

  # Vulkan runs Whisper on the GPU on both NVIDIA and AMD.
  package = pkgs.voxtype.override { vulkanSupport = true; };

  # Hashes from upstream's nix/models.nix (peteonrails/voxtype v0.7.2).
  models = {
    "base.en" = pkgs.fetchurl {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin";
      hash = "sha256-oDd5yG3zMjB19eeWyyzlAp8A7Ihp7uP9+4l6/jbG0AI=";
    };
    "large-v3-turbo" = pkgs.fetchurl {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin";
      hash = "sha256-H8cPd0046xaZk6w5Huo1fvR8iHV+9y7llDh5t+jivGk=";
    };
  };
in
{
  options.dpad.voxtype = {
    enable = mkEnableOption "Voxtype push-to-talk dictation (hold SUPER+V)";

    model = mkOption {
      type = types.enum (attrNames models);
      default = "base.en";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ package ];

    xdg.configFile."voxtype/config.toml".source = (pkgs.formats.toml { }).generate "voxtype-config.toml" {
      state_file = "auto";
      hotkey.enabled = false;
      audio = {
        device = "default";
        sample_rate = 16000;
        max_duration_secs = 60;
      };
      whisper = {
        model = "${models.${cfg.model}}";
        language = "en";
      };
      output = {
        mode = "type";
        fallback_to_clipboard = true;
        # Block modifiers while typing so text typed with SUPER still held
        # doesn't trigger Hyprland shortcuts.
        pre_output_command = "hyprctl dispatch submap voxtype_suppress";
        post_output_command = "hyprctl dispatch submap reset";
      };
    };

    systemd.user.services.voxtype = {
      Unit = {
        Description = "Voxtype push-to-talk voice-to-text daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" "pipewire.service" ];
        X-Restart-Triggers = [ config.xdg.configFile."voxtype/config.toml".source ];
      };
      Service = {
        ExecStart = "${package}/bin/voxtype daemon";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    wayland.windowManager.hyprland = {
      settings = {
        bind = [ "$mainMod, V, exec, voxtype record start" ];
        bindr = [ "$mainMod, V, exec, voxtype record stop" ];
      };

      # From `voxtype setup compositor hyprland`. F12 escapes if voxtype dies
      # mid-output.
      extraConfig = ''
        submap = voxtype_suppress
        bind = , SUPER_L, exec, true
        bind = , SUPER_R, exec, true
        bind = , Control_L, exec, true
        bind = , Control_R, exec, true
        bind = , Alt_L, exec, true
        bind = , Alt_R, exec, true
        bind = , Shift_L, exec, true
        bind = , Shift_R, exec, true
        bind = , F12, submap, reset
        submap = reset
      '';
    };
  };
}
