# Run every updater in one throwaway worktree, land the bumps as a single PR,
# then rebuild from the updated checkout.
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
work=$(mktemp -d)/nixos-config
git worktree add --quiet -b "$branch" "$work" "origin/$base"
# Keep the worktree if anything fails so it can be inspected.
trap 'echo "update: failed; worktree left at $work" >&2' ERR
cd "$work"

# Each bump is built on top of the ones before it, so a bad one can be dropped
# without holding back the rest, and whatever lands is known to build.
failed=()
for updater in "${updaters[@]}"; do
  echo "==> $updater"
  "$updater" --commit || { failed+=("$updater"); git reset --quiet --hard; }
done

bumps=$(git log --reverse --format='- %b' "origin/$base..")
if [ -n "$bumps" ]; then
  echo "==> Opening PR"
  git push --quiet -u origin "$branch"
  pr=$(gh pr create --base "$base" --head "$branch" --title "Update packages ($(date +%F))" \
    --body "$bumps"$'\n\n'"Verified \`nixosConfigurations.framework\` builds.")
  gh pr merge "$pr" --merge
  echo "Merged $pr"
fi

trap - ERR
cd "$repo"
git worktree remove "$work"
rmdir "${work%/*}"
git branch -D "$branch" >/dev/null

echo "==> Pulling $base"
git pull --ff-only --quiet origin "$base"
echo "==> nix-rebuild"
nix-rebuild

if [ "${#failed[@]}" -gt 0 ]; then
  echo "update: these updaters failed: ${failed[*]}" >&2
  exit 1
fi
