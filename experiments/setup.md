# Standing setup for every experiment

Each experiment runs on its own branch (`exp-NN-<pack>`) cut from `main`. `main` never contains a pack.

## Steps after installing a pack

1. `git checkout -b exp-NN-<pack>` from `main`.
2. `get-swarm-forge <two-pack|four-pack|six-pack>`.
3. Edit `swarmforge/swarmforge.conf` on **every role line**:
   - backend: `claude` (the pack defaults, `grok` and `codex`, are not installed here)
   - append `--dangerously-skip-permissions` as an extra argument, after any `batch`/`back-one`/`back-all` tokens
4. Commit the pack and config on the experiment branch.
5. Launch with the dedicated config dir: `CLAUDE_CONFIG_DIR=$HOME/.claude-swarm ./swarm` (see below).
6. Liveness check: within a few minutes of typing the brief, confirm there is a `claude` process per role and the coder shows tool activity or a first commit. The board alone does not show whether an agent is running.
7. Use `experiments/brief-import-graph.md` unchanged, and fill in `experiments/findings-template.md`.

## Teardown after every run

Tear the swarm down from its UI, then run `experiments/teardown.sh`. The swarm installs a `commit-msg` hook in the shared `.git/hooks/`, so it applies to every branch. On `main` the hook points at scripts that do not exist and every commit fails. The script removes that hook (only if it is SwarmForge's), prunes worktrees and reports leftover `.swarmforge/` and `.worktrees/`. Run it before committing anything on `main`, and never commit with `--no-verify` to get round the hook.

## Why the flag is standing

Agents run with permission prompts off in every experiment, so runs are comparable. Without it, tool-approval prompts would count as human interventions in some runs and not others. The agents are not sandboxed, so run experiments only in this repo.

Findings should note that "human interventions" counts only SwarmForge approval gates and clarification questions.

## Why a dedicated config dir

The operator's user-level `~/.claude/settings.json` sets `permissions.blockReadsOutsideWorkingDirectories: true`. That setting blocks commands the shell parser cannot analyse (e.g. `cd "$(pwd)/x"`), and it is not overridden by `--dangerously-skip-permissions` or by any project-level setting (tested: `.claude/settings.json`, `settings.local.json` and `--settings` all failed). Agents launched by SwarmForge hit it and have to rewrite commands, which makes runs noisy and not comparable.

`~/.claude-swarm/` is a separate Claude config dir with a minimal `settings.json` and its own login (one-time: `CLAUDE_CONFIG_DIR=$HOME/.claude-swarm claude`, then `/login`, in a real terminal). Launching the swarm with `CLAUDE_CONFIG_DIR` set leaves the operator's global settings untouched. Verified: the computed-path `cd` check passes with it.

## Repo rules

- `main` holds the baseline and, later, deliberately built tooling. It never contains a pack, `.swarmforge/` or `.worktrees/`.
- `exp-*` branches are throwaway. **They are never pushed, never merged into `main`, and need not be kept.** Delete them freely once the findings note is written. A run can always be reproduced from `main`, the brief and the pack.
- Findings notes are copied to the umbrella repo (`swift-agentic-engineering/research/findings/`). That is where conclusions are published.
