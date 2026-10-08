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
7. Use the experiment's brief (`experiments/brief-*.md`) unchanged, and fill in `experiments/findings-template.md`.

## Pinned starting points

Briefs that extend existing code start from a tagged commit, so every run begins from identical code. `main` still carries no product code: the tag keeps the commit reachable after its `exp-*` branch is deleted.

| Tag | Commit | What it is | Used by |
|---|---|---|---|
| `baseline/depgraph-exp02` | `06e815f` | `depgraph` as produced by exp-02 (two-pack): 107 source lines, 9 tests | `brief-depgraph-metrics.md` |

To start a run from a pinned baseline, after cutting `exp-NN-<pack>` from `main` and installing the pack (steps 1 to 4), copy only the product files, then commit them as the run's baseline:

`git checkout baseline/depgraph-exp02 -- Package.swift Package.resolved Sources Tests Fixtures .gitignore`

Tags are local: they are not pushed unless the operator decides to. If the repo is cloned elsewhere, push the tag first (`git push origin baseline/depgraph-exp02`) or the baseline is lost with this machine.

## Restarting an agent by hand

Both runs so far (exp-01, exp-02) had a coder that never started: the pane's launch command was garbled when the "You have new handoff mail" text was typed into it, leaving the shell at `quote>`. The root cause is in SwarmForge's launcher and is not fixed here (see below). When the liveness check fails, restart the role like this, and record it as an **operator action** in the findings.

SwarmForge types one line into each role's tmux pane (`launch-command` in `swarmforge/scripts/swarmforge.bb`, checked against the exp-02 pack with `--test-launch-command`). The line does **not** set `CLAUDE_CONFIG_DIR`: the agent only gets it if the pane's environment already has it. A hand restart must set it, or the agent loads the operator's global settings and hits `blockReadsOutsideWorkingDirectories` prompts (exp-02, finding 2).

1. Attach to the role's pane and clear the broken line: `tmux -S "$(cat .swarmforge/tmux-socket)" attach-session -t swarmforge-<role>` (the file holds the socket path), then `Ctrl-C` until the shell prompt is clean.
2. Run, with `<root>` the repo root, `<wt>` the role's worktree (`<root>` for the coder, `<root>/.worktrees/cleaner` for the cleaner), `<Role>` the display name (`Coder`, `Cleaner`):

```
export SWARMFORGE_ROLE=<role> && export PATH=<root>/.swarmforge/bin:<wt>/swarmforge/scripts:$PATH && cd <wt> && CLAUDE_CONFIG_DIR=$HOME/.claude-swarm CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1 claude --append-system-prompt-file <root>/.swarmforge/prompts/<role>.md --permission-mode bypassPermissions -n 'SwarmForge <Role>' --dangerously-skip-permissions "$(cat <root>/.swarmforge/prompts/<role>.md)"
```

3. Check it started: `pgrep -fl "claude.*SwarmForge <Role>"`, and a new transcript under `~/.claude-swarm/projects/` (not `~/.claude/projects/`, which means the config dir was missed). Its startup runs `ready_for_next.sh`, which picks up queued handoffs, so nothing is lost.
4. Note in the findings: which role, when, and why (liveness check failure).

This is the same line the launcher builds, minus the pane-specific exit and cleanup wrapper that only the first role gets. Check it against `swarmforge.bb` again if SwarmForge is upgraded.

**Open, not fixed:** the garbling itself. `handoffd.bb` `notify!` types the wake text into the pane with `tmux send-keys` without checking that an agent is running. That is an upstream (`unclebob/swarm-forge`) change, and changing it would alter the condition under test, so it needs a decision before any run depends on it.

## Capture benchmarks at the end of every run

Do this after the swarm stops and **before** `teardown.sh`, and write the numbers into the findings note (Measurements section). Use the format of `swift-agentic-engineering/research/findings/benchmarks-first-runs.md`.

1. **Find every session of the run.** Transcripts are `~/.claude-swarm/projects/<project-dir>/*.jsonl` (main checkout and `…--worktrees-<role>` for each role). Any agent restarted without `CLAUDE_CONFIG_DIR` logs to `~/.claude/projects/` instead, so check both. Include only sessions whose first user message starts `Read swarmforge/constitution.prompt` (agent sessions). Operator probe sessions are setup cost, not run cost: list them separately.
2. **Per session, read the last `cost-state` record**: `totalCostUSD`, `modelUsage` (input, output, thinking, cache read, cache write tokens, model name), `totalAPIDuration`, `totalToolDuration`.
   `python3 -I -c` over the file is enough: parse each line as JSON and keep the record with `type == "cost-state"`.
3. **Agent-active window**: first and last assistant-message `timestamp` (UTC; convert to local time for the note). Note it is not the same as launch-to-done wall-clock.
4. **Tools and role**: count `tool_use` names per session and note the role (coder, cleaner, …).
5. **Classify each session**: produced the result, or produced nothing (failed launch, restart, abandoned). Report two totals: all sessions, and result-producing sessions only.
6. **Code and tests** on the result commit: `git ls-files Sources Tests Fixtures | xargs wc -l`, test count and time from `swift test`, commits per role from `git log main..HEAD`.
7. **Gate behaviour**: from the transcripts, record which quality tools each role tried, what they returned, and any gate that fired (e.g. `AUDIT_REQUIRED`). This is the evidence for "did the quality feedback change what the agents did?".
8. State the cost caveat: `costUSD` is Claude Code's estimate, not an invoice. Record the model name for each session.

## Teardown after every run

Tear the swarm down from its UI, capture benchmarks (above), then run `experiments/teardown.sh`. The swarm installs a `commit-msg` hook in the shared `.git/hooks/`, so it applies to every branch. On `main` the hook points at scripts that do not exist and every commit fails. The script removes that hook (only if it is SwarmForge's), removes the role worktrees, their `swarmforge-*` branches and the run state (`.swarmforge/`, `.worktrees/`), so the next run starts clean. Write the findings note first: the run state is deleted. Run it before committing anything on `main`, and never commit with `--no-verify` to get round the hook.

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
