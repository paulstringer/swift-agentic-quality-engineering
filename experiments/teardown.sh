#!/usr/bin/env zsh
# Teardown after an experiment run. Run from any branch, after tearing the swarm down from its UI.
# Removes the SwarmForge commit-msg hook that the swarm installs in the shared .git/hooks,
# which otherwise breaks commits on branches (e.g. main) that have no swarmforge/ scripts.
# Also removes the run state (.swarmforge/), the role worktrees and their swarmforge-* branches, so the
# next run starts clean. Write the findings note before running it: the run state is deleted.
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

for wt in .worktrees/*(N/); do
  git worktree remove --force "$wt"
  echo "teardown: removed worktree $wt"
done
git worktree prune

for branch in $(git for-each-ref --format='%(refname:short)' 'refs/heads/swarmforge-*'); do
  git branch -D "$branch" >/dev/null
  echo "teardown: deleted branch $branch"
done

for state in .swarmforge .worktrees; do
  if [[ -e "$state" ]]; then
    rm -r "$state"
    echo "teardown: removed $state/"
  fi
done
exit 0
