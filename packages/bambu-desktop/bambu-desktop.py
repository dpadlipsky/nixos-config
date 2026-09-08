#!/usr/bin/env python3
"""Operate the installed Bambu Studio window on a live Hyprland desktop."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import time

APP_ID = "com.bambulab.BambuStudio"
CLASSES = {"BambuStudio", APP_ID}


def run(*args):
    result = subprocess.run(args, text=True, capture_output=True, timeout=30)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip())
    return result.stdout.strip()


def query(name):
    return json.loads(run("hyprctl", "-j", name))


def dispatch(name, argument):
    result = run("hyprctl", "dispatch", name, argument)
    if result != "ok":
        raise RuntimeError(result)


def windows():
    return [w for w in query("clients") if w["class"] in CLASSES and w["mapped"] and not w["hidden"]]


def choose(address=None):
    candidates = windows()
    if address:
        candidates = [w for w in candidates if w["address"] == address]
    if not candidates:
        raise RuntimeError("No matching Bambu Studio window. Run 'bambu-desktop launch' first.")
    # Modal dialogs normally have the most recent focus within this application.
    return min(candidates, key=lambda w: w["focusHistoryID"] if w["focusHistoryID"] >= 0 else 99999)


def identity(w):
    return {k: w[k] for k in ("address", "pid", "title", "at", "size")}


def check_focus(w):
    active = query("activewindow")
    if active.get("address") != w["address"] or active.get("class") not in CLASSES:
        raise RuntimeError("Focus changed; stopping. Avoid using the desktop during an action.")
    return active


def focus(w):
    dispatch("focuswindow", "address:" + w["address"])
    time.sleep(0.45)  # Allow workspace transitions and tiling to settle.
    return check_focus(w)


def key(w, name, mods=""):
    if any(c in name + mods for c in ",;\n\r"):
        raise RuntimeError("Pass one key name and modifiers separately.")
    check_focus(w)
    dispatch("sendshortcut", f"{mods},{name},address:{w['address']}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--window", help="Exact Hyprland window address from 'windows'")
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("windows")
    commands.add_parser("launch")
    shot = commands.add_parser("screenshot")
    shot.add_argument("output", type=Path)
    click = commands.add_parser("click")
    click.add_argument("x", type=int)
    click.add_argument("y", type=int)
    click.add_argument("--snapshot", type=Path, required=True, help="PNG from a recent screenshot; coordinates are relative to it")
    click.add_argument("--button", choices=["left", "right", "middle"], default="left")
    press = commands.add_parser("key")
    press.add_argument("key", help="XKB key name, e.g. Escape, Return, o")
    press.add_argument("--mods", default="", help="e.g. CTRL or CTRL SHIFT")
    typing = commands.add_parser("type")
    typing.add_argument("text")
    args = parser.parse_args()
    if args.command == "windows":
        print(json.dumps(windows(), indent=2))
        return
    if args.command == "launch":
        if not windows():
            dispatch("exec", "flatpak run " + APP_ID)
            for _ in range(60):
                if windows():
                    break
                time.sleep(0.5)
        print(json.dumps(identity(focus(choose(args.window))), indent=2))
        return
    snapshot = None
    if args.command == "click":
        snapshot = json.loads(Path(str(args.snapshot) + ".json").read_text())
        if not 0 <= time.time() - snapshot["captured_at"] <= 120:
            raise RuntimeError("Screenshot expired; take a fresh screenshot before clicking.")
        if args.window and args.window != snapshot["window"]["address"]:
            raise RuntimeError("Window does not match screenshot.")
    w = focus(choose(snapshot["window"]["address"] if snapshot else args.window))
    if args.command == "screenshot":
        output = args.output.expanduser().resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
        x, y = w["at"]
        width, height = w["size"]
        run("grim", "-s", "1", "-g", f"{x},{y} {width}x{height}", str(output))
        if identity(check_focus(w)) != identity(w):
            output.unlink(missing_ok=True)
            raise RuntimeError("Window moved during capture; retry.")
        metadata = {"window": identity(w), "captured_at": time.time(), "image": str(output)}
        Path(str(output) + ".json").write_text(json.dumps(metadata, indent=2) + "\n")
        print(json.dumps(metadata, indent=2))
    elif args.command == "click":
        if identity(w) != snapshot["window"]:
            raise RuntimeError("Window changed since screenshot; take a new screenshot.")
        if not 0 <= args.x < w["size"][0] or not 0 <= args.y < w["size"][1]:
            raise RuntimeError("Click falls outside the screenshot.")
        if not w["xwayland"]:
            raise RuntimeError("Mouse input currently requires Bambu Studio under XWayland.")
        xid = run("xdotool", "getwindowfocus")
        geometry = dict(line.split("=", 1) for line in run("xdotool", "getwindowgeometry", "--shell", xid).splitlines())
        x = round(args.x * int(geometry["WIDTH"]) / w["size"][0])
        y = round(args.y * int(geometry["HEIGHT"]) / w["size"][1])
        run("xdotool", "mousemove", "--sync", "--window", xid, str(x), str(y))
        check_focus(w)
        run("xdotool", "click", {"left": "1", "right": "3", "middle": "2"}[args.button])
    elif args.command == "key":
        key(w, args.key, args.mods)
    elif args.command == "type":
        if not w["xwayland"]:
            raise RuntimeError("Text entry currently requires Bambu Studio running under XWayland.")
        if any(c in args.text for c in "\n\r\t"):
            raise RuntimeError("Use 'key' explicitly for Return or Tab; type accepts a single line.")
        check_focus(w)
        run("xdotool", "type", "--clearmodifiers", "--delay", "2", "--", args.text)
        check_focus(w)


if __name__ == "__main__":
    os.umask(0o077)
    try:
        main()
    except (RuntimeError, OSError, ValueError, KeyError, subprocess.TimeoutExpired) as error:
        print(f"bambu-desktop: {error}", file=sys.stderr)
        sys.exit(1)
