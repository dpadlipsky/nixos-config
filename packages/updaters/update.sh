# Run every updater with --merge, then rebuild from the updated checkout.
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
# Fail before any PRs are merged if $base can't fast-forward.
echo "==> Pulling $base"
git pull --ff-only --quiet origin "$base"

failed=()
for updater in "${updaters[@]}"; do
  echo "==> $updater"
  "$updater" --merge || failed+=("$updater")
done

echo "==> Pulling $base"
git pull --ff-only --quiet origin "$base"
echo "==> nix-rebuild"
nix-rebuild

if [ "${#failed[@]}" -gt 0 ]; then
  echo "update: these updaters failed: ${failed[*]}" >&2
  exit 1
fi
