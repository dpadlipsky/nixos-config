{ config, pkgs, lib, inputs, ... }:

let
  unstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config = { allowUnfree = true; };
  };

  codexLatest = pkgs.callPackage ../../pkgs/codex.nix { };
in

{
  programs.home-manager.enable = true;
  programs.bash.enable = true;

  nixpkgs.config.allowUnfree = true;

  imports = [
    ../../modules/home-manager
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
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
    lm_sensors
    sublime
    spotify
    chromium
    firefox
    vesktop
    pulsemixer
    wireplumber
    xdg-desktop-portal-hyprland
    neovim
    gh
    evtest
    hid-tools
    tigervnc
    stm32cubemx
    hyprpolkitagent
    kdePackages.kwallet
    kdePackages.kwalletmanager
    gnupg
    pinentry-all
    freecad-wayland
    (pkgs.writeShellScriptBin "bambu-studio" "flatpak run com.bambulab.BambuStudio")
      (pkgs.callPackage ../../pkgs/claude-code.nix {
      inherit (unstable) claude-code;
    })
    unstable.code-cursor
    (pkgs.callPackage ../../pkgs/antigravity-cli.nix { })
    (pkgs.callPackage ../../pkgs/t3-code.nix {
      inherit (unstable) appimageTools;
      codex = codexLatest;
    })
  ];

  home.file = {
  };

  home.sessionVariables = {
    EDITOR = "vim";
  };

  services.flatpak = {
    enable = true;
    packages = [
      { appId = "com.bambulab.BambuStudio"; origin = "flathub"; }
    ];
  };

  dpad = {
    cursor.enable = true;

    hostLabel = "default";

    hyprland = {
      enable = true;
      sensitivity = -0.5;
      animations.enable = false;
    };

    hyprpaper.enable = true;
    rofi.enable = true;
    waybar.enable = true;
    swaylock.enable = true;
    # Off: the desktop has frozen after hypridle turned the monitors off (NVIDIA).
    hypridle.enable = false;
  };
}
