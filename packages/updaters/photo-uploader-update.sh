name=photo-uploader
slug=photo-uploader
sources=flake.lock

remote=git@github.com:dpadlipsky/photo-uploader.git

# Versions are short revs of the flake input's main branch.
latest_version() {
  git ls-remote "$remote" refs/heads/main | cut -c1-7
}

current_version() {
  jq -r '.nodes["photo-uploader"].locked.rev[:7]' "$1"
}

write_sources() {
  nix flake update photo-uploader --flake "${2%/*}"
  if [ "$(current_version "$2")" != "$1" ]; then
    echo "$name: only the head of main can be pinned; $1 isn't it" >&2
    exit 1
  fi
}

release_url() {
  echo "https://github.com/dpadlipsky/photo-uploader/commit/$1"
}

updater_main "$@"
