# Standing setup for every experiment

Each experiment runs on its own branch (`exp-NN-<pack>`) cut from `main`. `main` never contains a pack.

## Steps after installing a pack

1. `git checkout -b exp-NN-<pack>` from `main`.
2. `get-swarm-forge <two-pack|four-pack|six-pack>`.
3. Edit `swarmforge/swarmforge.conf` on **every role line**:
   - backend: `claude` (the pack defaults, `grok` and `codex`, are not installed here)
   - append `--dangerously-skip-permissions` as an extra argument, after any `batch`/`back-one`/`back-all` tokens
4. Commit the pack and config on the experiment branch.
5. Use `experiments/brief-import-graph.md` unchanged, and fill in `experiments/findings-template.md`.

## Why the flag is standing

Agents run with permission prompts off in every experiment, so runs are comparable. Without it, tool-approval prompts would count as human interventions in some runs and not others. The agents are not sandboxed, so run experiments only in this repo.

Findings should note that "human interventions" counts only SwarmForge approval gates and clarification questions.

## Repo rules

- `main` holds the baseline and, later, deliberately built tooling. It never contains a pack, `.swarmforge/` or `.worktrees/`.
- `exp-*` branches are throwaway. **They are never pushed, never merged into `main`, and need not be kept.** Delete them freely once the findings note is written. A run can always be reproduced from `main`, the brief and the pack.
- Findings notes are copied to the umbrella repo (`swift-agentic-engineering/research/findings/`). That is where conclusions are published.
