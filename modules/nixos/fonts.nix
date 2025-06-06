{ config, pkgs, ... }:

# TODO: Should this be as a system package or a user package?
{
  fonts.packages = with pkgs; [
    font-awesome
    liberation_ttf
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
  ];
}