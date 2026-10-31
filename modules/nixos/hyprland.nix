{ config, pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = false;
  };

  environment.systemPackages = with pkgs; [
    qt5.qtwayland
    qt6.qtwayland
    xdg-desktop-portal-hyprland
    brightnessctl
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Trash, removable drives and network shares in the file manager.
  services.gvfs.enable = true;
}
