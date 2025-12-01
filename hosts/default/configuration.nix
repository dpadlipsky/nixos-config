{ config, pkgs, inputs, ... }:

{
  imports = [
      ./hardware-configuration.nix

      inputs.home-manager.nixosModules.default

      ../../modules/nixos/nvidia.nix
      ../../modules/nixos/hyprland.nix
      ../../modules/nixos/audio.nix
      ../../modules/nixos/fonts.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    useOSProber = true;
    efiSupport = true;
    default = "2";
    timeoutStyle = "countdown";
  };

  networking.hostName = "dpadlipsky";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  # networking.firewall.allowedTCPPorts = [ 5173 ];

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
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

  # Configure keymap in X11
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    xkb.variant = "";
    displayManager.sddm.enable = true;
  };

  users.users.dpadlipsky = {
    isNormalUser = true;
    description = "David Padlipsky";
    extraGroups = [ "networkmanager" "wheel" "dialout" "uucp" "docker" ];
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    killall
    git
    gtk3
    wev
    python3
    gcc
    stdenv
    nix-index
  ];

  virtualisation.docker.enable = true;

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

  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };

  security.pam.services.swaylock = {};

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "dpadlipsky" ];
  };
  programs.hyprland.enable = true;

  security.polkit.enable = true;
  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
    polkit-1.u2fAuth = true;
    sddm.enableKwallet = true;
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

  services.udev.packages = with pkgs; [
    vial
    via
  ];
}
