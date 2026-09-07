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
    bubblewrap
    codexLatest
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
