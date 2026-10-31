{
  config,
  pkgs,
  inputs,
  ...
}:

let
  unstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config = {
      allowUnfree = true;
    };
  };

  codexLatest = pkgs.callPackage ../../pkgs/codex.nix { };

  # Upstream's nix/hashes.json lags bun.lock; drop this override once it catches up.
  opencodeUpstream = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default;
  opencode = opencodeUpstream.override {
    node_modules = opencodeUpstream.node_modules.override {
      hash = "sha256-Mnn7G5pFXpKzE80NhIMMDa35Z/U4lfnw3tqjABi4b3k=";
    };
  };

  wine = pkgs.wineWow64Packages.stagingFull;

  # NX Studio has no Linux build, so run it under Wine in its own prefix.
  # With arguments (e.g. the installer .exe) they run in that prefix instead.
  nxStudio = pkgs.writeShellScriptBin "nx-studio" ''
    export WINEPREFIX="''${XDG_DATA_HOME:-$HOME/.local/share}/wine-nxstudio"
    export PATH=${wine}/bin:$PATH
    if [ $# -gt 0 ]; then
      exec wine "$@"
    fi
    exe=$(find "$WINEPREFIX/drive_c" -iname 'NX Studio.exe' -print -quit 2>/dev/null)
    if [ -z "$exe" ]; then
      echo "NX Studio isn't installed yet; run: nx-studio /path/to/S-NXSTDO-*.exe" >&2
      exit 1
    fi
    exec wine "$exe"
  '';
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
    vesktop
    pulsemixer
    wireplumber
    xdg-desktop-portal-hyprland
    neovim
    gh
    evtest
    hid-tools
    tigervnc
    hyprpolkitagent
    kdePackages.kwallet
    kdePackages.kwalletmanager
    gnupg
    pinentry-all
    freecad-wayland
    openscad
    darktable
    wine
    winetricks
    nxStudio
    (pkgs.callPackage ../../pkgs/claude-code.nix {
      inherit (unstable) claude-code;
    })
    unstable.code-cursor
    (pkgs.callPackage ../../pkgs/antigravity-cli.nix { })
    (pkgs.callPackage ../../pkgs/t3-code.nix {
      inherit (unstable) appimageTools;
      codex = codexLatest;
    })
    bubblewrap
    (pkgs.callPackage ../../packages/headless-run { })
    (pkgs.callPackage ../../packages/updaters { })
    inputs.bambu-desktop.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.photo-uploader.packages.${pkgs.stdenv.hostPlatform.system}.default
    codexLatest
    opencode
  ];

  home.file = {
    # Replace the bootstrap launcher and skill with the versions from the pin.
    ".local/bin/bambu-desktop" = {
      source = "${inputs.bambu-desktop.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/bambu-desktop";
      force = true;
    };
    ".codex/skills/bambu-studio" = {
      source = "${inputs.bambu-desktop}/skills/bambu-studio";
      recursive = true;
      force = true;
    };
  };

  home.sessionVariables = {
    EDITOR = "vim";
  };

  programs.chromium.enable = true;

  programs.kitty.themeFile = "tokyo_night_night";

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
