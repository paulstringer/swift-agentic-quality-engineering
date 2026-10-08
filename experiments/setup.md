# Standing setup for every experiment

Each experiment runs on its own branch (`exp-NN-<pack>`) cut from `main`. `main` never contains a pack.

## Steps after installing a pack

1. `git checkout -b exp-NN-<pack>` from `main`.
2. `get-swarm-forge <two-pack|four-pack|six-pack>`.
3. Edit `swarmforge/swarmforge.conf` on **every role line**:
   - backend: `claude` (the pack defaults, `grok` and `codex`, are not installed here)
   - append `--dangerously-skip-permissions` as an extra argument, after any `batch`/`back-one`/`back-all` tokens
4. Commit the pack and config on the experiment branch.
5. Launch with the dedicated config dir **and** the minimal shell dir: `ZDOTDIR=$HOME/.zdotdir-swarm CLAUDE_CONFIG_DIR=$HOME/.claude-swarm ./swarm` (see "Why a minimal ZDOTDIR" and "Why a dedicated config dir"). One-time: `mkdir -p ~/.zdotdir-swarm && touch ~/.zdotdir-swarm/.zshrc`.
6. Liveness check: within a few minutes of typing the brief, confirm there is a `claude` process per role and the coder shows tool activity or a first commit. The board alone does not show whether an agent is running.
7. Use the experiment's brief (`experiments/brief-*.md`) unchanged, and fill in `experiments/findings-template.md`.

## What a start looks like

`ZDOTDIR=$HOME/.zdotdir-swarm CLAUDE_CONFIG_DIR=$HOME/.claude-swarm ./swarm` prints (two-pack; the dashboard port changes every run):

```
SwarmForge v1.0 Starting
Launching SwarmForge tmux sessions...
Started handoff daemon with OS sleep prevention.
Dashboard: http://127.0.0.1:<port>
Starting agents...
  [Coder] started in session swarmforge-coder
  [Cleaner] started in session swarmforge-cleaner

SwarmForge is ready.
Working directory: <root>
Tip: Reattach manually with 'tmux -S /tmp/swarmforge-<user>/<id>.sock attach-session -t <session-name>' if needed.

No visible Terminal surfaces; use the dashboard.
```

- "No visible Terminal surfaces" is expected: the roles are `window-invisible`. Use the dashboard, or attach with the tmux line it prints.
- **"started in session" does not mean the agent is running.** It is printed right after the launch line is typed into the pane (`launch-role!`), without checking the result. Do the liveness check every time.

## Why a minimal ZDOTDIR

SwarmForge builds one long shell line per role (about 1,500 characters for the coder with our 99-character repo path) and types it into a freshly started zsh pane with `tmux send-keys`, without waiting for the shell to be ready. While zsh is still loading the operator's dotfiles (about 0.6 s here), typed-ahead input is held in the terminal's line buffer, which is limited to 1,024 characters on macOS. The coder's line goes over and is lost or cut, so `claude` never starts and the board still looks busy.

An empty `.zshrc` in `~/.zdotdir-swarm` brings zsh's start-up to about 0.03 s. Tmux panes inherit `ZDOTDIR` from the launching shell, so no change to SwarmForge is needed. Tools still resolve, because the panes inherit the launching shell's `PATH`. Aliases and functions from the operator's dotfiles are not available to agents' shells, which also makes the agents' shell environment the same from run to run.

This narrows the race but does not remove it. Evidence and test tables: `swift-agentic-engineering/research/findings/launch-race-fix.md`. A line under 1,024 characters (a short repo path, e.g. a symlink such as `/tmp/saqe` passed as `./swarm /tmp/saqe`) would remove the dependency on timing and is a further option, untested end to end.

## Pinned starting points

Briefs that extend existing code start from a tagged commit, so every run begins from identical code. `main` still carries no product code: the tag keeps the commit reachable after its `exp-*` branch is deleted.

| Tag | Commit | What it is | Used by |
|---|---|---|---|
| `baseline/depgraph-exp03` | `138877c` | `depgraph` as produced by exp-03 (two-pack, clean run): 153 source lines, 14 tests, all six criteria met | `brief-depgraph-metrics.md` |

To start a run from a pinned baseline, after cutting `exp-NN-<pack>` from `main` and installing the pack (steps 1 to 4), copy only the product files, then commit them as the run's baseline:

`git checkout baseline/depgraph-exp03 -- Package.swift Package.resolved Sources Tests Fixtures .gitignore`

Tags are local: they are not pushed unless the operator decides to. If the repo is cloned elsewhere, push the tag first (`git push origin baseline/depgraph-exp03`) or the baseline is lost with this machine.

## Restarting an agent by hand

With the minimal `ZDOTDIR` launch the coder has started on its own in both launches so far, 2 of 2 (see "Why a minimal ZDOTDIR"). Without it, the coder's launch line was lost in 3 of 3 launches (exp-01, exp-02, and a test launch on 2026-10-08): the line is longer than the terminal's 1,024-character typed-ahead limit and zsh was still loading `.zshrc` when it arrived. If the liveness check ever fails anyway, restart the role like this and record it as an **operator action** in the findings.

SwarmForge types one line into each role's tmux pane (`launch-command` in `swarmforge/scripts/swarmforge.bb`, checked against the exp-02 pack with `--test-launch-command`). The line does **not** set `CLAUDE_CONFIG_DIR`: the agent only gets it if the pane's environment already has it. A hand restart must set it, or the agent loads the operator's global settings and hits `blockReadsOutsideWorkingDirectories` prompts (exp-02, finding 2).

1. Attach to the role's pane and clear the broken line: `tmux -S "$(cat .swarmforge/tmux-socket)" attach-session -t swarmforge-<role>` (the file holds the socket path), then `Ctrl-C` until the shell prompt is clean.
2. Run, with `<root>` the repo root, `<wt>` the role's worktree (`<root>` for the coder, `<root>/.worktrees/cleaner` for the cleaner), `<Role>` the display name (`Coder`, `Cleaner`):

```
export SWARMFORGE_ROLE=<role> && export PATH=<root>/.swarmforge/bin:<wt>/swarmforge/scripts:$PATH && cd <wt> && CLAUDE_CONFIG_DIR=$HOME/.claude-swarm CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1 claude --append-system-prompt-file <root>/.swarmforge/prompts/<role>.md --permission-mode bypassPermissions -n 'SwarmForge <Role>' --dangerously-skip-permissions "$(cat <root>/.swarmforge/prompts/<role>.md)"
```

3. Check it started: `pgrep -fl "claude.*SwarmForge <Role>"`, and a new transcript under `~/.claude-swarm/projects/` (not `~/.claude/projects/`, which means the config dir was missed). Its startup runs `ready_for_next.sh`, which picks up queued handoffs, so nothing is lost.
4. Note in the findings: which role, when, and why (liveness check failure).

This is the same line the launcher builds, minus the pane-specific exit and cleanup wrapper that only the first role gets. Check it against `swarmforge.bb` again if SwarmForge is upgraded.

**Not a SwarmForge change:** the fix is in how we launch (minimal `ZDOTDIR`), so the SwarmForge scripts stay unmodified and runs stay comparable. An upstream change (send the line via a file, or wait for the shell prompt) would remove the cause but is not needed while the launch check passes.

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
