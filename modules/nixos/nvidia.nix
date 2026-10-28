{ config, pkgs, ... }:

{
  services.xserver = {
    videoDrivers = ["nvidia"];
  };

  hardware.nvidia = {
    modesetting.enable = true;
    # Preserve VRAM across suspend so Hyprland survives resume.
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  nixpkgs.config.cudaSupport = true;
  hardware.opengl.enable = true;
}