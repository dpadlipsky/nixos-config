{ writeShellApplication, bubblewrap, xvfb-run, xorg }:

let
  # nixpkgs' minimal xorg.xvfb disables GLX. OpenSCAD needs the full server's
  # Xvfb binary to render previews with software OpenGL.
  xvfbWithOpenGL = xvfb-run.override {
    xorg = xorg // { xvfb = xorg.xorgserver; };
  };
in writeShellApplication {
  name = "headless-run";
  runtimeInputs = [ bubblewrap xvfbWithOpenGL ];
  text = builtins.readFile ./headless-run.sh;
}
