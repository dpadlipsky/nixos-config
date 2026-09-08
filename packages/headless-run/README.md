# Isolated graphics jobs

`headless-run COMMAND [ARGUMENTS...]` starts Xvfb and its client inside private
temporary-file, network, IPC, and process namespaces. Workspace files remain
accessible. The host's `/tmp` and network are unavailable inside the command.
No desktop restart or Bambu Studio configuration change is required.

Example:

```sh
headless-run env QT_QPA_PLATFORM=xcb LIBGL_ALWAYS_SOFTWARE=1 \
  openscad -o preview.png --imgsize=1200,1200 model.scad
```

On 2026-09-07, an OpenSCAD preview job ran `Xvfb -displayfd` against the host's
shared `/tmp`. Afterwards, Hyprland's `/tmp/.X11-unix/X0` path was absent while
its `X0_` socket and Xwayland process remained live. Restoring `X0` as a link to
`X0_` restored Bambu Studio startup. That link repairs the current session;
isolating future rendering jobs prevents them from modifying desktop sockets.

Xorg's [automatic display selection](https://github.com/mirror/xserver/blob/master/os/connection.c)
probes display numbers starting at zero. Its
[Unix socket implementation](https://cgit.freedesktop.org/xorg/lib/libxtrans/tree/Xtranssock.c)
unlinks an existing filesystem socket before binding. Hyprland normally uses
[two filesystem sockets](https://github.com/hyprwm/Hyprland/blob/main/src/xwayland/Server.cpp)
when abstract sockets are disabled. An automatically selected display can
therefore replace the desktop socket. Explicit display numbers alone are less
robust than isolating both socket namespaces.

The launcher is included in the Framework Home Manager packages. It may also be
built independently using the flake's pinned package set:

```sh
nix build --impure --expr \
  'let f = builtins.getFlake ("path:" + toString ./.); in f.nixosConfigurations.framework.pkgs.callPackage ./packages/headless-run { }'
```

The package uses the full Xorg server's Xvfb binary because the minimal
`xorg.xvfb` package in the pinned nixpkgs disables GLX, which OpenSCAD requires.

Validation on the Framework laptop (2026-09-07):

- Nix build, ShellCheck, and Framework configuration assertions passed.
- `python3 packages/headless-run/check.py /absolute/path/to/headless-run`
  passed: two simultaneous private displays, separate network namespaces,
  private `/tmp`, unchanged host socket/lock-file identities, working desktop
  X11 connectivity, and preservation of the client command's exit status.
- OpenSCAD rendered the actual penguin model to a 1200 × 1200 PNG successfully.
  The [verification image](evidence/penguin-preview.png) demonstrates that
  software OpenGL works inside the isolated display.

The integration check requires Python 3, `xprop`, and permission to create
namespaces. Run it from a healthy desktop session to include the host X11
connectivity check. The package was built and tested independently; a full
NixOS rebuild and reboot were not performed.
