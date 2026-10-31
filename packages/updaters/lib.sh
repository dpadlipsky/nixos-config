# Shared driver for the *-update scripts. An updater sets:
#   name     name for the commit/PR title, e.g. "T3 Code"
#   slug     branch slug, e.g. "t3code"
#   sources  repo-relative JSON pin read by the package; must have .version
#            unless current_version is defined
# defines:
#   latest_version              print the newest upstream version
#   current_version FILE        (optional) print the pinned version from FILE;
#                               defaults to its .version
#   write_sources VERSION FILE  write the pin for VERSION to FILE
#   release_url VERSION         (optional) release link for the PR description
# and ends with `updater_main "$@"`.
#
# By default the bump happens in a throwaway worktree off origin's default
# branch, gets build-checked, committed, pushed, and opened as a PR, leaving
# the main checkout alone. With --merge the PR is merged straight away (an
# already-open PR for the same version is merged too). With --local it only
# rewrites the pin in place.

set -o errtrace

# prefetch URL: print the SRI hash of URL, adding it to the store.
prefetch() {
  nix store prefetch-file --json "$1" | jq -r .hash
}

# github_releases OWNER/REPO: print recent releases as a JSON array.
github_releases() {
  curl -fsSL "https://api.github.com/repos/$1/releases?per_page=30"
}

# write_pinned_sources FILE VERSION KEY URL [KEY URL...]: write
# {version, sources.KEY = {url, hash}} to FILE, prefetching each URL.
write_pinned_sources() {
  local file=$1 version=$2 json hash
  shift 2
  json=$(jq -n --arg version "$version" '{version: $version, sources: {}}')
  while [ "$#" -gt 0 ]; do
    echo "Fetching $2" >&2
    hash=$(prefetch "$2")
    json=$(jq --arg key "$1" --arg url "$2" --arg hash "$hash" \
      '.sources[$key] = {url: $url, hash: $hash}' <<<"$json")
    shift 2
  done
  printf '%s\n' "$json" >"$file"
}

updater_usage() {
  echo "usage: $(basename "$0") [--local | --merge] [VERSION]" >&2
  exit 1
}

updater_main() {
  local local_only='' merge='' version='' arg repo base branch work current body pr

  for arg in "$@"; do
    case "$arg" in
      --local) local_only=1 ;;
      --merge) merge=1 ;;
      -h | --help | -*) updater_usage ;;
      *) [ -z "$version" ] || updater_usage; version=${arg#v} ;;
    esac
  done

  # Prefer the checkout we're standing in (e.g. a worktree), else ~/nixos-config.
  repo=$(git rev-parse --show-toplevel 2>/dev/null || true)
  if [ -z "$repo" ] || [ ! -f "$repo/$sources" ]; then
    repo=${NIXOS_CONFIG:-$HOME/nixos-config}
  fi
  [ -f "$repo/$sources" ] || { echo "$name: no $sources in $repo" >&2; exit 1; }

  if [ -z "$version" ]; then
    version=$(latest_version)
    [ -n "$version" ] || { echo "$name: could not find the latest version" >&2; exit 1; }
  fi
  branch=t3/update-$slug-$version

  if [ -n "$local_only" ]; then
    work=$repo
  else
    git -C "$repo" fetch --quiet origin
    base=$(git -C "$repo" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/mainline)
    base=${base#origin/}
    if git -C "$repo" ls-remote --exit-code --heads origin "$branch" >/dev/null; then
      echo "Branch $branch already exists on origin."
      if [ -n "$merge" ] && [ "$(cd "$repo" && gh pr view "$branch" --json state -q .state)" = OPEN ]; then
        (cd "$repo" && gh pr merge "$branch" --merge)
        echo "Merged the open PR for $branch"
      fi
      exit 0
    fi
    work=$(mktemp -d)/nixos-config
    git -C "$repo" worktree add --quiet -b "$branch" "$work" "origin/$base"
    # Keep the worktree if anything fails so it can be inspected.
    trap 'echo "$name: failed; worktree left at $work" >&2' ERR
  fi

  if declare -F current_version >/dev/null; then
    current=$(current_version "$work/$sources")
  else
    current=$(jq -r .version "$work/$sources")
  fi
  if [ "$version" = "$current" ]; then
    echo "$name is already at $version"
    [ -n "$local_only" ] || updater_remove_worktree "$repo" "$work" "$branch"
    exit 0
  fi

  write_sources "$version" "$work/$sources"
  echo "Updated $name: $current -> $version"

  if [ -n "$local_only" ]; then
    git -C "$work" --no-pager diff -- "$sources"
    echo "Run nix-rebuild to install it."
    exit 0
  fi

  echo "Building nixosConfigurations.framework"
  nix build --no-link "$work#nixosConfigurations.framework.config.system.build.toplevel"

  body="Bumps $name from $current to $version"
  if declare -F release_url >/dev/null; then
    body+=" ([release]($(release_url "$version")))"
  fi
  body+=". Verified \`nixosConfigurations.framework\` builds."

  git -C "$work" commit --quiet -am "Update $name to $version"
  git -C "$work" push --quiet -u origin "$branch"
  pr=$(cd "$work" && gh pr create --base "$base" --head "$branch" \
    --title "Update $name to $version" --body "$body")

  trap - ERR
  updater_remove_worktree "$repo" "$work" "$branch"
  echo "Opened $pr"
  if [ -n "$merge" ]; then
    (cd "$repo" && gh pr merge "$pr" --merge)
    echo "Merged $pr"
  else
    echo "After merging: cd $repo && git pull && nix-rebuild"
  fi
}

updater_remove_worktree() {
  trap - ERR
  git -C "$1" worktree remove "$2"
  rmdir "${2%/*}"
  git -C "$1" branch -D "$3" >/dev/null
}

