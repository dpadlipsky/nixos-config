{ config, pkgs, lib, inputs, ... }:

let
  unstable = import inputs.nixpkgs-unstable {
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

  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "text/html" = "chromium.desktop";
    "x-scheme-handler/http" = "chromium.desktop";
    "x-scheme-handler/https" = "chromium.desktop";
  };

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
    tigervnc
    stm32cubemx
    hyprpolkitagent
    unstable.code-cursor
    libsForQt5.kwallet
    libsForQt5.kwalletmanager
    gnupg
    pinentry-all
    unstable.claude-code
    unstable.gemini-cli
  ];

  home.file = {
  };

  home.sessionVariables = {
    EDITOR = "vim";
  };

  dpad = {
    cursor.enable = true;

    hostLabel = "default";

    hyprland = {
      enable = true;
      sensitivity = -0.5;
      animations.enable = true;
    };

    hyprpaper.enable = true;
    rofi.enable = true;
    waybar.enable = true;
    swaylock.enable = true;
  };
}
