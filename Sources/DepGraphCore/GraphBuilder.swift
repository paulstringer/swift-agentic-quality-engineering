struct SourceFile {
    let relativePath: String
    let contents: String

    /// The top-level folder containing the file, or nil for files at the root.
    var component: String? {
        let parts = relativePath.split(separator: "/")
        return parts.count > 1 ? String(parts[0]) : nil
    }
}

enum GraphBuilder {
    /// Distinct, sorted edges between components. Imports of modules that are
    /// not components (e.g. Foundation) and self-imports are ignored.
    static func edges(from files: [SourceFile]) -> [Edge] {
        let components = Set(files.compactMap(\.component))
        var edges = Set<Edge>()
        for file in files {
            guard let component = file.component else { continue }
            for module in ImportScanner.imports(in: file.contents)
            where module != component && components.contains(module) {
                edges.insert(Edge(component, module))
            }
        }
        return edges.sorted()
    }
}
