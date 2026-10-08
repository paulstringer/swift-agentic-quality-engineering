import Foundation

enum SourceLoader {
    /// Every `.swift` file under `root`, with paths relative to `root`.
    static func load(from root: URL) throws -> [SourceFile] {
        let root = root.standardizedFileURL.resolvingSymlinksInPath()
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        let prefix = root.path + "/"
        return try enumerator.compactMap { item in
            guard let url = item as? URL, url.pathExtension == "swift" else { return nil }
            let path = url.standardizedFileURL.resolvingSymlinksInPath().path
            return SourceFile(
                relativePath: String(path.dropFirst(prefix.count)),
                contents: try String(contentsOf: url, encoding: .utf8)
            )
        }
    }
}
