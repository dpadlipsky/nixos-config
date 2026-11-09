name="Antigravity IDE"
slug=antigravity-ide
sources=pkgs/antigravity-ide.json

# The IDE's auto-updater. It only serves the current release, and only carries
# the version inside the download URL (.../stable/<version>-<build>/...).
manifest=https://antigravity-ide-auto-updater-974169037036.us-central1.run.app/api/update/linux-x64/stable/latest

url_version() {
  sed -nE 's|.*/antigravity/stable/([0-9.]+)-[0-9]+/.*|\1|p' <<<"$1"
}

latest_version() {
  url_version "$(curl -fsSL "$manifest" | jq -r '.url // empty')"
}

write_sources() {
  local json
  json=$(curl -fsSL "$manifest")
  if [ "$(url_version "$(jq -r .url <<<"$json")")" != "$1" ]; then
    echo "$name: only the latest release can be pinned; $1 isn't it" >&2
    exit 1
  fi
  jq --arg version "$1" '{
    version: $version,
    vscodeVersion: .productVersion,
    url: (.url | gsub(" "; "%20")),
    sha256: .sha256hash
  }' <<<"$json" >"$2"
}

release_url() {
  echo "https://antigravity.google/changelog"
}

updater_main "$@"
