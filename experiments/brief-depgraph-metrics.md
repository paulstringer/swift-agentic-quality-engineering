# Brief: add coupling metrics to the import-graph checker

The same brief is used unchanged for every experiment. Do not edit it per run.

**Kind of experiment:** feature added to **existing code**. The first brief (`brief-import-graph.md`) was greenfield. This one starts from a working `depgraph` and asks the swarm to extend it without breaking it. It tests whether quality feedback protects existing behaviour while code grows.

## Starting point

The code produced by exp-02 (two-pack), result commit `06e815f`: `DepGraphCore` library (`ImportScanner`, `DependencyGraph`, `SourceTree`, `DepGraphCommand`), `depgraph` executable, two fixtures (`Fixtures/Acyclic`, `Fixtures/Layered`), 9 passing tests.

Every run starts from this identical commit, tagged `baseline/depgraph-exp02`.

## Task

Extend `depgraph` to report coupling metrics for each component, as defined in `swift-agentic-engineering/research/experiments/metrics-spec.md` (dependency-checker-swift section).

## Definitions

- **Ce (efferent coupling):** number of distinct components this component depends on.
- **Ca (afferent coupling):** number of distinct components that depend on this component.
- **Instability:** `Ce / (Ca + Ce)`, a number from 0 to 1. Undefined (`null`) when both are 0.
- Edges are the same ones `depgraph` already prints. Imports of modules that are not components are not edges.

## Acceptance criteria

1. **Existing behaviour unchanged.** `depgraph <path>` with no new flags prints exactly what it printed before, and exits with the same code. The original 9 tests still pass, unmodified.
2. `depgraph <path> --metrics` prints, after the edge lines, one line per component, sorted by component name, in the form `Domain Ca=1 Ce=2 I=0.67` (instability rounded to 2 decimal places; `I=n/a` when undefined).
3. `depgraph <path> --format json` prints a single JSON object with `schema`, `components` (each with `name`, `ca`, `ce`, `instability`), `edges` and `cycles`. Lists are sorted, so output is byte-identical between runs. Instability is `null`, not `0`, when undefined.
4. On `Fixtures/Layered` the metrics are exactly: `Data` Ca=1 Ce=0 I=0.00; `Domain` Ca=1 Ce=2 I=0.67; `UI` Ca=1 Ce=1 I=0.50. This is an automated test.
5. On `Fixtures/Acyclic` the metrics are exactly: `Data` Ca=1 Ce=0 I=0.00; `Domain` Ca=1 Ce=1 I=0.50; `UI` Ca=0 Ce=1 I=1.00. This is an automated test.
6. A component with no edges at all (add a fixture `Fixtures/Isolated` with one extra component) reports Ca=0 Ce=0 and `I=n/a` / `null`. This is an automated test.
7. Cycle behaviour is unchanged: with `--metrics` or `--format json`, a cycle still makes `depgraph` exit non-zero and the cycle is still reported.
8. All tests pass with `swift test`.

## Out of scope

Abstractness and distance from the main sequence, rules files, type-reference analysis, CI integration, any change to how components or edges are found.

## What the experiment looks at (for the findings note, not for the agents)

- Did existing behaviour survive: criterion 1, and whether the original tests were edited (diff the test file against `06e815f`).
- Where the agents put the change: new files and types, or a bigger `DependencyGraph`/`DepGraphCommand`.
- Any quality gate that ran, what it returned, and whether the cleaner changed anything because of it (see `experiments/setup.md`, "Capture benchmarks").
- Metrics-spec numbers on the result commit, compared with the baseline commit `06e815f`.
- The usual session benchmarks.

## Operator note (not part of the brief)

The starting commit is preserved as the tag `baseline/depgraph-exp02`. How to start a run from it is in `experiments/setup.md`, "Pinned starting points".
