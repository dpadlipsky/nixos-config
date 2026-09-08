---
name: bambu-studio
description: Operate the locally installed Bambu Studio client to open models, prepare and inspect sliced plates, view printer status, and submit user-requested print jobs using desktop screenshots and input. Use for Bambu Studio GUI workflows on this machine.
---

# Bambu Studio

## Local controller

Use `/home/dpadlipsky/.local/bin/bambu-desktop`. This controls the existing Flatpak
`com.bambulab.BambuStudio` using Hyprland, Grim, and XWayland/xdotool. It reuses
the client's configured account and printer connection. No Bambu MCP is needed.

The installed runtime is pinned at
`/home/dpadlipsky/.local/share/bambu-desktop/runtime` with a Nix GC root.
Source and detailed usage/evidence are in
`/home/dpadlipsky/nixos-config-bambu-desktop-83c1/packages/bambu-desktop/README.md`
(branch `codex/bambu-desktop-83c1`). Read that document for repairs or rebuilds;
normal operation does not depend on the source worktree.

## Desktop access

Start with `bambu-desktop windows`, then `launch` if no Bambu window is open.
Use the absolute executable path if it is not on PATH.
These commands access the real logged-in desktop. Sandbox socket failures
require the execution tool's host-access escalation, not a replacement GUI stack.
They need the graphical session's DISPLAY, WAYLAND_DISPLAY, XDG_RUNTIME_DIR,
and HYPRLAND_INSTANCE_SIGNATURE; do not hard-code an old session signature.
Browser preview tools cannot control this native window.

Tell the user when beginning desktop interactions so they can avoid simultaneous
input. If focus is lost, stop the input sequence, inspect again, and resume from
the observed state. Do not start Xvfb or touch shared X11 sockets for this workflow.

## Observe and act

1. Capture a window with `bambu-desktop screenshot /home/dpadlipsky/artifacts/bambu-current.png`.
2. Inspect the PNG with the image-viewing tool before choosing an action.
3. Use screenshot-relative coordinates:
   `bambu-desktop click X Y --snapshot /home/dpadlipsky/artifacts/bambu-current.png`.
   Replace X/Y with coordinates from the actual screenshot.
4. Capture and inspect the resulting UI. Successful event delivery does not prove
   that a dialog opened, text was entered correctly, or a print started.

Each screenshot includes a `.png.json` sidecar. Keep it with the image.
Clicks reject expired snapshots (120 seconds), changed window identity/title/
geometry, and out-of-bounds coordinates. They do not detect changed UI contents;
refresh after dialog/tab/layout changes. Scaling is handled by the controller.
Never reuse the coordinates from a past session.

`windows` lists addresses. The default target is the most recently focused Bambu
window, often a modal dialog. For an explicit target, put `--window 0xADDRESS`
before the subcommand. Read addresses afresh.

Useful input examples:

```sh
bambu-desktop key o --mods CTRL
bambu-desktop key l --mods CTRL
bambu-desktop key a --mods CTRL
bambu-desktop type '/absolute/path/to/project.3mf'
bambu-desktop key Escape
```

Ctrl+O opens a 3MF project picker; use the appropriate import UI for other formats.
Text entry is single-line; Return and Tab are separate `key` actions. Verify the
exact path after typing: a dialog transition consumed the leading slash in an
early test, and Ctrl+A followed by replacement corrected it. Do not run the
example as a blind macro.

## Printing

Follow the current request and its existing authorization. Preparing a file or
checking status does not by itself authorize starting a physical print. When a
print is requested, inspect the target printer, nozzle, plate, material/process
settings, sliced preview, and AMS mapping through the actual client. Resolve
missing job-critical details, including whether the build plate is clear, before
submission; do not request the same authorization again when already supplied.

After sending a job, verify its status in Device. If submission is ambiguous,
inspect status and job history before retrying; never blindly submit a second copy.
Do not press heater, motion, calibration, unload, or other hardware controls while
merely checking status.

## Proven behavior and limits

Verified on 2026-09-08: Flatpak Bambu Studio 2.8.2.61, Hyprland 0.49.0,
XWayland, 2880×1920 display at 2× scale. Launch, screenshots, project picker,
exact text replacement, Cancel clicks, invalid/stale click rejection, and Device
status viewing worked. The client showed printer telemetry and AMS slots.

Slicing, upload, and print submission were not tested end to end. Treat them as
unverified until a real authorized job succeeds; update this skill with concrete
results and useful corrections after that validation. Historical printer status
and filament contents are not current facts—read them again for each job.
