if [[ $# -eq 0 || $1 == --help ]]; then
  echo 'Usage: headless-run COMMAND [ARGUMENTS...]'
  echo 'Runs a command with a private Xvfb display, /tmp, and network namespace.'
  echo 'Keep inputs and outputs in your workspace; host /tmp and network are unavailable.'
  if [[ $# -eq 0 ]]; then exit 2; fi
  exit 0
fi

# Xvfb's automatic display probing can unlink a live Hyprland X11 socket.
# Isolate both filesystem and abstract sockets, including X server lock files.
exec bwrap \
  --bind / / \
  --dev-bind /dev /dev \
  --unshare-pid --proc /proc \
  --unshare-ipc --unshare-net \
  --die-with-parent \
  --tmpfs /tmp \
  --unsetenv DISPLAY --unsetenv WAYLAND_DISPLAY --unsetenv WAYLAND_SOCKET \
  --setenv TMPDIR /tmp \
  -- xvfb-run --error-file=/dev/stderr --server-num=99 --auto-servernum \
  --server-args='-screen 0 1400x1400x24 -nolisten tcp' "$@"
