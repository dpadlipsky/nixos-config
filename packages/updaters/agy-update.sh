name="Antigravity CLI"
slug=agy
sources=pkgs/antigravity-cli.json

# The auto-updater the official install script uses. It only serves the
# current release, as {version, url, sha512}.
manifest=https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_amd64.json

latest_version() {
  curl -fsSL "$manifest" | jq -r '.version // empty'
}

write_sources() {
  local json
  json=$(curl -fsSL "$manifest")
  if [ "$(jq -r .version <<<"$json")" != "$1" ]; then
    echo "$name: only the latest release can be pinned; $1 isn't it" >&2
    exit 1
  fi
  printf '%s\n' "$json" >"$2"
}

release_url() {
  echo "https://antigravity.google/changelog"
}

updater_main "$@"
