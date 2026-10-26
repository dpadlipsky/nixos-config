name=Codex
slug=codex
sources=pkgs/codex.json

latest_version() {
  # Newest non-prerelease, i.e. GitHub's "Latest" (alphas are prereleases).
  github_releases openai/codex |
    jq -r '[.[] | select(.prerelease | not)][0].tag_name // empty | ltrimstr("rust-v")'
}

write_sources() {
  local base="https://github.com/openai/codex/releases/download/rust-v$1"
  write_pinned_sources "$2" "$1" \
    cli "$base/codex-x86_64-unknown-linux-musl.tar.gz" \
    host "$base/codex-code-mode-host-x86_64-unknown-linux-musl.zst"
}

release_url() {
  echo "https://github.com/openai/codex/releases/tag/rust-v$1"
}

updater_main "$@"
