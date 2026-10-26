# Run every updater with --merge, then rebuild from the updated checkout.
# `updaters` (the *-update commands) is defined by default.nix.

repo=${NIXOS_CONFIG:-$HOME/nixos-config}
base=$(git -C "$repo" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/mainline)
base=${base#origin/}
# nix-rebuild builds whatever $repo has checked out, so it must track $base.
if [ "$(git -C "$repo" branch --show-current)" != "$base" ]; then
  echo "update: $repo must be on $base to rebuild from it" >&2
  exit 1
fi
cd "$repo"

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
