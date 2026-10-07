# Experiment NN — <pack> — findings

Date: · Branch: · Backend/model: · Baseline commit:

## Setup
Commands actually run, in order. Anything that needed adapting for Swift.

## Outcome
- Brief acceptance criteria met (list 1–6, pass/fail):
- `swift test` passes: yes/no

## Measurements
| Measure | Value |
|---|---|
| Agent iterations / handoffs | |
| Human interventions (approvals, clarifications, manual fixes) | |
| Wall-clock time | |
| Token / API cost (all sessions / result-producing sessions) | |
| Output, thinking, cache tokens; model | |
| Agent-active time (first to last assistant message) | |
| Quality gates that ran / fired | |
| Test count / coverage (if available) | |

Per-session table and method: see "Capture benchmarks" in `experiments/setup.md`.

## What went wrong or surprised us
Swift-specific friction, gate failures, stuck loops.

## Does this answer the question?
Did the quality feedback in this setup change what the agents did? Evidence only, no opinion.
