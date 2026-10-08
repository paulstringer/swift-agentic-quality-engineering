enum CycleFinder {
    /// The first cycle found (deterministic, alphabetical DFS), as a closed path
    /// such as `["A", "B", "A"]`, or nil when the graph is acyclic.
    static func cycle(in edges: [Edge]) -> [String]? {
        var successors: [String: [String]] = [:]
        for edge in edges.sorted() {
            successors[edge.from, default: []].append(edge.to)
        }
        var finished = Set<String>()
        var path: [String] = []

        func visit(_ node: String) -> [String]? {
            if let start = path.firstIndex(of: node) {
                return Array(path[start...]) + [node]
            }
            if finished.contains(node) { return nil }
            path.append(node)
            for next in successors[node] ?? [] {
                if let found = visit(next) { return found }
            }
            path.removeLast()
            finished.insert(node)
            return nil
        }

        for start in successors.keys.sorted() {
            if let found = visit(start) { return found }
        }
        return nil
    }
}
