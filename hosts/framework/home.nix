{
  config,
  pkgs,
  inputs,
  ...
}:

let
  unstable = import inputs.nixpkgs-unstable {
    system = pkgs.system;
    config = {
      allowUnfree = true;
    };
  };

  codexLatest = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "codex";
    version = "0.153.4";

    src = pkgs.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-9HlCTsoJJITcQNh64oxE9MxAI0pgBF1hMeSTgA2BSjA=";
    };

    hostArchive = pkgs.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-x86_64-unknown-linux-musl.zst";
      hash = "sha256-9rxE2cJl9VhCOwedDcl5oS148zY07sydqs5jpbR8vMY=";
    };

    nativeBuildInputs = [ pkgs.zstd ];
    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      install -Dm755 codex-x86_64-unknown-linux-musl $out/bin/codex
      zstd -dc "$hostArchive" > "$out/bin/codex-code-mode-host"
      chmod 755 "$out/bin/codex-code-mode-host"

      runHook postInstall
    '';
  };
  t3Source = pkgs.fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v0.0.40/T3-Code-0.0.40-x86_64.AppImage";
    hash = "sha256-i/X9RMt/rQxDGR1U/v35dKgifVBQXsuKvPdjJiCfJko=";
  };

  t3Contents = unstable.appimageTools.extract {
    pname = "t3code-desktop";
    version = "0.0.40";
    src = t3Source;
  };

  t3Desktop = unstable.appimageTools.wrapType2 {
    pname = "t3code-desktop";
    version = "0.0.40";
    src = t3Source;
    extraPkgs = p: [ codexLatest p.git p.nodejs_24 ];
    profile = ''
      export PATH="${codexLatest}/bin:$PATH"
    '';
  };

  t3Latest = pkgs.symlinkJoin {
    name = "t3code-0.0.40";
    paths = [
      t3Desktop
      (pkgs.makeDesktopItem {
        name = "t3code";
        desktopName = "T3 Code";
        comment = "T3 Code desktop app";
        exec = "t3code-desktop %U";
        icon = "t3code";
        terminal = false;
        categories = [ "Development" ];
        startupWMClass = "t3code";
        mimeTypes = [ "x-scheme-handler/t3code" "x-scheme-handler/t3code-dev" ];
      })
    ];
    postBuild = ''
      install -Dm644 ${t3Contents}/t3code.png $out/share/icons/hicolor/512x512/apps/t3code.png
    '';
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
    neovim
    gh
    evtest
    hid-tools
    tigervnc
    hyprpolkitagent
    libsForQt5.kwallet
    libsForQt5.kwalletmanager
    gnupg
    pinentry-all
    freecad-wayland
    unstable.claude-code
    unstable.gemini-cli
    unstable.code-cursor
    t3Latest
    bubblewrap
    codexLatest
  ];

  home.file = {
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
