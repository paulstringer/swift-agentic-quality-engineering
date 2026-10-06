#!/usr/bin/env zsh
# Teardown after an experiment run. Run from any branch, after tearing the swarm down from its UI.
# Removes the SwarmForge commit-msg hook that the swarm installs in the shared .git/hooks,
# which otherwise breaks commits on branches (e.g. main) that have no swarmforge/ scripts.
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

if pgrep -f "$root/swarmforge/scripts/(handoffd|pack_web)" >/dev/null; then
  echo "teardown: swarm daemons are still running. Tear the swarm down from its UI first." >&2
  exit 1
fi

hook="$(git rev-parse --git-path hooks/commit-msg)"
if [[ -f "$hook" ]] && grep -q "swarmforge/scripts/commit_msg_hook.bb" "$hook"; then
  rm "$hook"
  echo "teardown: removed SwarmForge commit-msg hook"
else
  echo "teardown: no SwarmForge commit-msg hook present"
fi

git worktree prune
for leftover in .swarmforge .worktrees; do
  [[ -e "$leftover" ]] && echo "teardown: leftover $leftover/ (gitignored; delete when the findings are written)"
done
exit 0
