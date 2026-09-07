{ config, lib, ... }:


{
  programs.kitty = {
    enable = true;
    keybindings = {
      "ctrl+c" = "copy_or_interrupt";
    };
    settings = {
      background_opacity = "0.90";
      scrollback_lines = 10000;
      mouse_map = "ctrl+left click ungrabbed mouse_handle_click selection link prompt";
      enable_audio_bell = "no";
      mouse_hide_wait = 2;
      strip_trailing_spaces = "smart";
    };
    shellIntegration.enableBashIntegration = true;
    theme = lib.mkIf (config.dpad.hostLabel != "framework") "Tokyo Night";
  };
}
