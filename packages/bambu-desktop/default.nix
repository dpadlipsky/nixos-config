{ writeShellApplication, python3, hyprland, grim, xdotool, flatpak }:
writeShellApplication {
  name = "bambu-desktop";
  runtimeInputs = [ python3 hyprland grim xdotool flatpak ];
  text = ''
    exec python3 ${./bambu-desktop.py} "$@"
  '';
}
