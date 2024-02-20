{ pkgs, ... }:

{
  home.packages = [
    pkgs.hyprpaper
  ];

  xdg.configFile."hypr/hyprpaper.conf" = {
    text = ''
      # Generated by Home Manager
      preload = ~/.config/wallpaper.jpg
      wallpaper = ,~/.config/wallpaper.jpg
      splash = false
    '';
  };
}