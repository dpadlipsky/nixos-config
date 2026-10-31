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

  # LibRaw with the unmerged Nikon HE/HE* decoder (LibRaw/LibRaw#826); drop
  # this once a LibRaw release ships HE support and darktable picks it up.
  librawNikonHe = pkgs.libraw.overrideAttrs {
    version = "0.22.0-nikon-he";
    src = pkgs.fetchFromGitHub {
      owner = "yogthos";
      repo = "LibRaw";
      rev = "499bfd4cbf802c2fb5eac4c9a6f53bbeb776cad1";
      hash = "sha256-wpgk2Bm3nJnBn41MxRngLcAhLxWAmo+anO/HLwESTVM=";
    };
    # LibRaw has no color matrix for the Z5 II; use rawspeed's.
    postPatch = ''
      substituteInPlace src/tables/colordata.cpp --replace-fail \
        '{ LIBRAW_CAMERAMAKER_Nikon, "Z6_3",' \
        '{ LIBRAW_CAMERAMAKER_Nikon, "Z5_2", 0, 0,
          { 13133,-5542,-1280,-4325,12543,1972,34,792,7662 } },
        { LIBRAW_CAMERAMAKER_Nikon, "Z6_3",'
    '';
  };

  # darktable builds its own LibRaw copy by default, and only hands CR3 to
  # LibRaw; link the patched one and send NEFs through it as well.
  darktable = pkgs.darktable.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [ librawNikonHe ];
    cmakeFlags = old.cmakeFlags ++ [ "-DDONT_USE_INTERNAL_LIBRAW=ON" ];
    preFixup = old.preFixup + ''
      gappsWrapperArgs+=(--add-flags "--conf libraw_extensions=nef")
    '';
  });

  wine = pkgs.wineWow64Packages.stagingFull;

  # NX Studio has no Linux build, so run it under Wine in its own prefix.
  # With arguments (e.g. the installer .exe) they run in that prefix instead.
  nxStudio = pkgs.writeShellScriptBin "nx-studio" ''
    export WINEPREFIX="''${XDG_DATA_HOME:-$HOME/.local/share}/wine-nxstudio"
    export PATH=${wine}/bin:$PATH
    # Sign-in uses WebView2, which only renders under Wine without the GPU
    # or sandbox. The runtime itself has to be installed into the prefix:
    # nx-studio MicrosoftEdgeWebView2RuntimeInstallerX64.exe /silent /install
    export WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS="--no-sandbox --disable-gpu --disable-gpu-compositing --in-process-gpu"
    # The installer refuses to run on anything older than Windows 11.
    if [ ! -d "$WINEPREFIX" ]; then
      winecfg -v win11
    fi
    if [ $# -gt 0 ]; then
      exec wine "$@"
    fi
    exe=$(find "$WINEPREFIX/drive_c" -iname 'NXStudio.exe' -print -quit 2>/dev/null)
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
