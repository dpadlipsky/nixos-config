name="T3 Code"
slug=t3code
sources=pkgs/t3-code.json

latest_version() {
  # Only "Nightly" pre-releases; "Preview" builds are maintainer-only.
  github_releases pingdotgg/t3code |
    jq -r '[.[] | select(.tag_name | test("-nightly\\."))][0].tag_name // empty | ltrimstr("v")'
}

write_sources() {
  write_pinned_sources "$2" "$1" \
    appimage "https://github.com/pingdotgg/t3code/releases/download/v$1/T3-Code-$1-x86_64.AppImage"
}

release_url() {
  echo "https://github.com/pingdotgg/t3code/releases/tag/v$1"
}

updater_main "$@"
