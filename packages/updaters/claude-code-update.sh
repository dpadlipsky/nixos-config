name="Claude Code"
slug=claude-code
sources=pkgs/claude-code.json

releases=https://downloads.claude.ai/claude-code-releases

latest_version() {
  # Anthropic also publishes a lagging "stable" channel; nixpkgs tracks latest.
  curl -fsSL "$releases/latest"
}

write_sources() {
  # The release manifest carries per-platform checksums; nixpkgs'
  # claude-code takes it as-is via its `manifest` argument.
  curl -fsSL "$releases/$1/manifest.zst.json" -o "$2"
}

release_url() {
  echo "https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md"
}

updater_main "$@"
