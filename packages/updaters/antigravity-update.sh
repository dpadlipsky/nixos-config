name="Antigravity"
slug=antigravity
sources=pkgs/antigravity.json

# The app's auto-updater. It only serves the current release; its files are
# the AppImage and .deb, and the tarball nixpkgs builds from sits beside them.
manifest=https://antigravity-hub-auto-updater-974169037036.us-central1.run.app/manifest/latest-x64-linux.yml

manifest_field() {
  sed -nE "s|^ *(- )?$1: *||p" | head -1
}

latest_version() {
  curl -fsSL "$manifest" | manifest_field version
}

write_sources() {
  local yml url
  yml=$(curl -fsSL "$manifest")
  if [ "$(manifest_field version <<<"$yml")" != "$1" ]; then
    echo "$name: only the latest release can be pinned; $1 isn't it" >&2
    exit 1
  fi
  url=$(manifest_field url <<<"$yml")
  write_pinned_sources "$2" "$1" linux-x64 "${url%/*}/Antigravity.tar.gz"
}

release_url() {
  echo "https://antigravity.google/changelog"
}

updater_main "$@"
