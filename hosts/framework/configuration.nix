{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix

    inputs.home-manager.nixosModules.default

    ../../modules/nixos/hyprland.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/fonts.nix
    ../../modules/nixos/kanata.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    useOSProber = true;
    efiSupport = true;
    default = "SAVED";
    timeoutStyle = "countdown";
    gfxmodeEfi = "1024x768";
  };
  boot.kernelParams = [
    "quiet"
    "splash"
    "loglevel=0"
    "acpi_rev_override"
    "amdgpu.dcdebugmask=0x10"
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.luks.devices."luks-de8965c6-4cae-4f0d-a96c-dd55aba6c708".device =
    "/dev/disk/by-uuid/de8965c6-4cae-4f0d-a96c-dd55aba6c708";

  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;
  networking.hostName = "dpadlipsky";

  networking.networkmanager.enable = true;
  networking.wireless.enable = false;
  networking.wireless.userControlled.enable = true;

  networking.firewall.enable = true;

  time.timeZone = "America/Los_Angeles";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.upower.enable = true;
  services.colord.enable = true;

  powerManagement.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session.command = ''
        ${pkgs.greetd.tuigreet}/bin/tuigreet \
          --time \
          --user-menu \
          --cmd hyprland
      '';
    };
  };
  environment.etc."greetd/environments".text = ''
    hyprland
  '';

  services.xserver = {
    enable = true;
    xkb.layout = "us";
    xkb.variant = "";
    dpi = 192;
    # displayManager.sddm.enable = true;
    # displayManager.sddm.enableHidpi = true;
    # displayManager.sddm.settings = {
    #   Autologin = {
    #     user = "dpadlipsky";
    #     session = "hyprland";
    #   };
    # };
  };

  users.users.dpadlipsky = {
    isNormalUser = true;
    description = "David Padlipsky";
    extraGroups = [
      "networkmanager"
      "wheel"
      "dialout"
      "uucp"
      "docker"
      "video"
      "uinput"
    ];
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.nvidia.acceptLicense = true;
  services.flatpak.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    killall
    git
    gtk3
    wev
    python3
    gcc
    stdenv
    nix-index
    acpi
    lshw
    pavucontrol
  ];

  programs.light.enable = true;
  programs.steam.enable = true;
  virtualisation.docker.enable = true;

  services.fwupd.enable = true;
  services.fprintd.enable = true;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "dpadlipsky" ];
  };

  security.polkit.enable = true;
  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
    polkit-1.u2fAuth = true;
    sddm.enableKwallet = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "dpadlipsky" = import ./home.nix;
    };
  };

  security.pam.services.swaylock = {
    text = ''
      auth sufficient pam_unix.so try_first_pass likeauth nullok
      auth sufficient pam_fprintd.so
      auth include login
    '';
  };

  security.pam.services.sddm = {
    text = ''
      auth sufficient pam_unix.so try_first_pass likeauth nullok
      auth sufficient pam_fprintd.so
      auth include login
    '';
  };

  security.pam.services.kwallet = {
    enableKwallet = true;
  };

  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = false;
      settings = {
        default-cache-ttl = 2592000;
        max-cache-ttl = 2592000;
      };
    };
  };

  dpad = {
    kanata = {
      internalKeyboard = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
    };
  };
}
