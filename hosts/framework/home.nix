{ config, pkgs, inputs, ... }:

let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
  unstable-with-config = import inputs.nixpkgs-unstable {
    system = pkgs.system;
    config = { allowUnfree = true; };
  };
in

{
  programs.home-manager.enable = true;
  programs.bash.enable = true;

  nixpkgs.config.allowUnfree = true;

  imports = [
    ../../modules/home-manager
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "dpadlipsky";
  home.homeDirectory = "/home/dpadlipsky";

  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    vscode
    discord
    lm_sensors
    sublime
    spotify
    chromium
    firefox
    discord-screenaudio
    pulsemixer
    wireplumber
    xdg-desktop-portal-hyprland
    webcord
    neovim
    gh
    evtest
    hid-tools
    rpi-imager
    tigervnc
    hyprpolkitagent
    code-cursor
    libsForQt5.kwallet
    libsForQt5.kwalletmanager
    gnupg
    pinentry-all
    freecad-wayland
    orca-slicer
    unstable-with-config.claude-code
  ];

  home.file = {
  };

  home.sessionVariables = {
    EDITOR = "vim";
  };

  programs.chromium.enable = true;

  dpad = {
    cursor.enable = true;

    hostLabel = "framework";

    hyprland = {
      enable = true;
      sensitivity = 0;
      animations.enable = false;
    };

    hyprpaper.enable = true;
    rofi.enable = true;
    waybar.enable = true;
    swaylock.enable = true;
    hypridle.enable = true;
  };
}
