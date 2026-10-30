{ config, pkgs, ... }:

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
    firefox
    vesktop
    wireplumber
    neovim
    gh

    pulsemixer
    pavucontrol
  ];

  home.file = {
  };

  home.sessionVariables = {
    EDITOR = "vim";
  };

  # Disable GPU in chromium due to incompatibility w/ nvidia offloading
  # TODO: Figure out why
  programs.chromium.enable = true;
  programs.chromium.commandLineArgs = [
    "--disable-gpu"
  ];

  dpad = {
    cursor.enable = true;

    hostLabel = "laptop";

    hyprland = {
      enable = true;
      sensitivity = 0;
      animations.enable = false;
    };

    hyprpaper.enable = true;
    rofi.enable = true;
    waybar.enable = true;
    swaylock.enable = true;
  };
}
