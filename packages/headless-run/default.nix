{ writeShellApplication, bubblewrap, xvfb-run, xorg-server }:

let
  # nixpkgs' minimal xvfb disables GLX. OpenSCAD needs the full server's
  # Xvfb binary to render previews with software OpenGL.
  xvfbWithOpenGL = xvfb-run.override {
    xvfb = xorg-server;
  };
in writeShellApplication {
  name = "headless-run";
  runtimeInputs = [ bubblewrap xvfbWithOpenGL ];
  text = builtins.readFile ./headless-run.sh;
}
