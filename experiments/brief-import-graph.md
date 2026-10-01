# Brief: Swift import-graph checker

The same brief is used unchanged for every experiment. Do not edit it per run.

## Task

Build a small command-line tool in Swift that reads a directory of Swift source and prints the dependencies between its components.

## Definitions

- **Component:** the top-level folder (relative to the given path) that contains a source file.
- **Dependency:** a component imports a module, e.g. `import Domain` in a file under `UI/`.

## Acceptance criteria

1. `depgraph <path>` prints one line per distinct edge, sorted, in the form `UI → Domain`.
2. Only `import` declarations are considered. Parsing uses SwiftSyntax, not regular expressions.
3. A fixture project exists with three components (`UI`, `Domain`, `Data`) layered `UI → Domain → Data`, plus one planted violation where `Domain` imports `UI`.
4. Running the tool on the fixture prints exactly the expected edges, including the violation. This is an automated test.
5. `depgraph` exits non-zero when it finds a cycle between components, and prints the cycle. The fixture's planted violation must trigger this.
6. All tests pass with `swift test`.

## Out of scope

Type-reference analysis, configuration files, allowed/forbidden rules, CI integration.
