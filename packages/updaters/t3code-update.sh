name="T3 Code"
slug=t3code
sources=pkgs/t3-code.json

latest_version() {
  # Only "Nightly" pre-releases; "Preview" builds are maintainer-only.
  github_releases pingdotgg/t3code |
    jq -r '[.[] | select(.tag_name | test("-nightly\\."))][0].tag_name // empty | ltrimstr("v")'
}

write_sources() {
  # The AppImage's name changes between releases (T3-Code-<version>-x86_64,
  # T3-Code-Nightly-x86_64), so take it from the release's assets.
  local url
  url=$(curl -fsSL "https://api.github.com/repos/pingdotgg/t3code/releases/tags/v$1" |
    jq -r '[.assets[].browser_download_url | select(endswith("x86_64.AppImage"))][0] // empty')
  [ -n "$url" ] || { echo "$name: no x86_64 AppImage in release v$1" >&2; exit 1; }
  write_pinned_sources "$2" "$1" appimage "$url"
}

release_url() {
  echo "https://github.com/pingdotgg/t3code/releases/tag/v$1"
}

updater_main "$@"
