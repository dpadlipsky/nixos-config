# Bambu Studio desktop controller

`bambu-desktop` operates the installed Flatpak client on the logged-in Hyprland
session. It uses Hyprland for window discovery/focus and keyboard shortcuts,
Grim for cropped screenshots, and xdotool for XWayland typing and mouse input.
The client keeps its existing Bambu account, networking plugin, and printer setup.
No printer MCP server or direct printer protocol implementation is involved.

## Persistent installation and skill

This machine has `/home/dpadlipsky/.local/bin/bambu-desktop` linked to
`/home/dpadlipsky/.local/share/bambu-desktop/runtime/bin/bambu-desktop`.
The runtime is an indirect Nix GC root, so the installed controller survives
removing the development worktree and ordinary Nix garbage collection.

The [bambu-studio skill](skill/SKILL.md) is installed as a regular copy at
`/home/dpadlipsky/.codex/skills/bambu-studio`, with automatic discovery enabled.
Invoke it explicitly with `$bambu-studio`. After editing the source skill, update
the installed copy too. Its source worktree is useful for rebuilding, but neither
the installed skill nor runtime is symlinked to it.

## Build and run

```sh
nix build .#bambu-desktop --out-link result-bambu-desktop
./result-bambu-desktop/bin/bambu-desktop launch
./result-bambu-desktop/bin/bambu-desktop windows
./result-bambu-desktop/bin/bambu-desktop screenshot /path/to/window.png
./result-bambu-desktop/bin/bambu-desktop key o --mods CTRL
./result-bambu-desktop/bin/bambu-desktop key l --mods CTRL
./result-bambu-desktop/bin/bambu-desktop key a --mods CTRL
./result-bambu-desktop/bin/bambu-desktop type '/path/to/project.3mf'
./result-bambu-desktop/bin/bambu-desktop screenshot /path/to/dialog.png
```

Inspect the screenshot before the next action. To click, pass coordinates measured
from that image, not from the whole screen:

```sh
bambu-desktop click 956 798 --snapshot /path/to/dialog.png
bambu-desktop key Escape
```

The example coordinates were Cancel in the tested dialog; locate controls afresh.
Screenshots use one pixel per logical desktop coordinate. Mouse coordinates are
converted to the target X window's dimensions, including display scaling.
Each PNG has a JSON sidecar with window identity, geometry, title, and capture time.
Clicks reject images older than two minutes, changed windows, or coordinates
outside the image. This does not detect changes in the contents of a window.

By default, commands target the most recently focused Bambu Studio window,
including its file dialogs. Use `--window 0xADDRESS` before the command to choose
an exact window from `windows`. Commands check focus before input. Text entry
accepts a single line; send Return/Tab explicitly with `key`.

Run in the graphical user's session with DISPLAY, WAYLAND_DISPLAY,
XDG_RUNTIME_DIR, and HYPRLAND_INSTANCE_SIGNATURE available. Sandboxed agents need
host desktop access for these commands. They cannot operate through browser-only
preview tools. The controller uses the actual desktop, so avoid simultaneous
mouse/keyboard use while an action runs. Focus checks cannot eliminate every race
with another desktop user. A locked/unavailable session must be unlocked first.

No virtual display is started. Headless rendering tests elsewhere must continue
to use `headless-run`.

## Using this for print jobs

Open/import the model, inspect the printer/filament/process settings, slice, and
inspect the preview through the client. Then use its Print Plate dialog and
verify the selected printer and AMS mapping before submitting an authorized job.
This is a set of interactive GUI primitives, not an unattended print scheduler.
Always inspect the resulting UI after inputs; successful event delivery alone
does not prove an operation completed. Dialog transitions can consume input; the
live test needed explicit selection/replacement to verify the exact file path.

## Validation on this machine

Tested 2026-09-08 with Bambu Studio Flatpak 2.8.2.61, Hyprland 0.49.0,
XWayland, and a 2880×1920 display at 2× scale:

- Nix package build succeeded.
- Launched the installed client and captured its windows.
- Ctrl+O opened the project picker; text entry and Ctrl+A replacement produced
  the exact dummy path shown in [typed-path.png](evidence/typed-path.png).
- A screenshot-relative click on Cancel closed the picker. See
  [before](evidence/before-cancel.png) and [after](evidence/after-cancel.png).
- A negative click coordinate was rejected with `Click falls outside the screenshot.`
- A click referring to the closed dialog was rejected because the window no longer existed.
- Opened Device and observed connected printer telemetry, AMS slots, and the
  previous job marked Finished. Private device screenshot is outside the repository
  at `/home/dpadlipsky/artifacts/bambu-desktop-device.png`.

No print was started, and slicing/upload/print submission have not yet been
validated end to end. GUI layouts, modal dialogs, and focus can change, so future
jobs must use fresh screenshots rather than a recorded sequence of coordinates.
