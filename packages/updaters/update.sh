# Run every updater in parallel in throwaway worktrees, land the bumps that
# build together as a single PR, then rebuild from the updated checkout.
# `updaters` (the *-update commands) is defined by default.nix.

repo=${NIXOS_CONFIG:-$HOME/nixos-config}
base=$(git -C "$repo" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/mainline)
base=${base#origin/}
# nix-rebuild builds whatever $repo has checked out, so switch it to $base.
cd "$repo"
if [ "$(git branch --show-current)" != "$base" ]; then
  echo "==> Switching $repo to $base"
  git switch --quiet "$base"
fi
# Fail before the PR is merged if $base can't fast-forward.
echo "==> Pulling $base"
git pull --ff-only --quiet origin "$base"

branch=t3/update-$(date +%Y%m%d-%H%M%S)
tmpdir=$(mktemp -d)
work=$tmpdir/nixos-config
base_rev=$(git rev-parse "origin/$base")
git worktree add --quiet -b "$branch" "$work" "$base_rev"

pids=()
uworks=()
cleanup_updaters() {
  trap - ERR INT TERM
  set +m
  local pid uwork
  for pid in "${pids[@]+"${pids[@]}"}"; do
    kill -- -"$pid" 2>/dev/null || true
  done
  for pid in "${pids[@]+"${pids[@]}"}"; do
    wait "$pid" 2>/dev/null || true
  done
  for uwork in "${uworks[@]+"${uworks[@]}"}"; do
    git -C "$repo" worktree remove --force "$uwork" 2>/dev/null || true
  done
  rm -f "$tmpdir"/*.log
}

# Keep $work if anything fails so it can be inspected, while cleaning up any
# in-flight updater jobs and detached worktrees.
trap 'cleanup_updaters; echo "update: failed; worktree left at $work" >&2' ERR
trap 'cleanup_updaters; echo "update: interrupted; worktree left at $work" >&2; exit 130' INT
trap 'cleanup_updaters; echo "update: interrupted; worktree left at $work" >&2; exit 143' TERM

# Fetch and pin each package in parallel in its own detached worktree, then
# cherry-pick into $work and build the combined configuration once. If the
# combined build fails, fall back to testing each bump incrementally so a bad
# one doesn't hold back the rest.
echo "==> Running ${#updaters[@]} updaters in parallel"
set -m
for updater in "${updaters[@]}"; do
  uwork="$tmpdir/$updater"
  git worktree add --quiet --detach "$uwork" "$base_rev"
  uworks+=("$uwork")
  (cd "$uwork" &&
    GIT_SSH_COMMAND='ssh -o BatchMode=yes' GIT_TERMINAL_PROMPT=0 \
      exec "$updater" --commit </dev/null) >"$tmpdir/$updater.log" 2>&1 &
  pids+=($!)
done
set +m

failed=()
picked_updaters=()
picked_revs=()
for i in "${!updaters[@]}"; do
  updater=${updaters[$i]}
  uwork=${uworks[$i]}
  log="$tmpdir/$updater.log"
  if wait "${pids[$i]}"; then
    rev=$(git -C "$uwork" rev-parse HEAD)
    if [ "$rev" != "$base_rev" ]; then
      picked_updaters+=("$updater")
      picked_revs+=("$rev")
    fi
  else
    failed+=("$updater")
  fi
  unset 'pids[i]'
  echo "==> $updater"
  cat "$log"
  git -C "$repo" worktree remove --force "$uwork"
  unset 'uworks[i]'
  rm -f "$log"
done

cd "$work"
if [ "${#picked_revs[@]}" -gt 0 ]; then
  git cherry-pick --quiet "${picked_revs[@]}" >/dev/null
  echo "==> Building nixosConfigurations.framework"
  if ! nix build --no-link "$work#nixosConfigurations.framework.config.system.build.toplevel"; then
    if [ "${#picked_revs[@]}" -eq 1 ]; then
      failed+=("${picked_updaters[0]}")
      git reset --quiet --hard "$base_rev"
    else
      echo "==> Combined build failed; checking each bump individually"
      git reset --quiet --hard "$base_rev"
      for i in "${!picked_revs[@]}"; do
        echo "==> Checking ${picked_updaters[$i]}"
        prev=$(git rev-parse HEAD)
        git cherry-pick --quiet "${picked_revs[$i]}" >/dev/null
        if ! nix build --no-link "$work#nixosConfigurations.framework.config.system.build.toplevel"; then
          git reset --quiet --hard "$prev"
          failed+=("${picked_updaters[$i]}")
        fi
      done
    fi
  fi
fi

bumps=$(git log --reverse --format='- %b' "origin/$base..")
if [ -n "$bumps" ]; then
  echo "==> Opening PR"
  git push --quiet -u origin "$branch"
  pr=$(gh pr create --base "$base" --head "$branch" --title "Update packages ($(date +%F))" \
    --body "$bumps"$'\n\n'"Verified \`nixosConfigurations.framework\` builds.")
  gh pr merge "$pr" --merge
  echo "Merged $pr"
fi

trap - ERR INT TERM
cd "$repo"
git worktree remove "$work"
rmdir "$tmpdir"
git branch -D "$branch" >/dev/null

echo "==> Pulling $base"
git pull --ff-only --quiet origin "$base"
echo "==> nix-rebuild"
nix-rebuild

if [ "${#failed[@]}" -gt 0 ]; then
  echo "update: these updaters failed: ${failed[*]}" >&2
  exit 1
fi
