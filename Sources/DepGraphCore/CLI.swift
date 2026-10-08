import Foundation

public struct CLIResult: Equatable {
    public let output: String
    public let errorOutput: String
    public let exitCode: Int32
}

public enum CLI {
    public static func run(arguments: [String]) -> CLIResult {
        guard arguments.count == 1 else {
            return CLIResult(output: "", errorOutput: "usage: depgraph <path>\n", exitCode: 2)
        }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: arguments[0], isDirectory: &isDirectory), isDirectory.boolValue else {
            return CLIResult(output: "", errorOutput: "depgraph: not a directory: \(arguments[0])\n", exitCode: 2)
        }
        do {
            let files = try SourceLoader.load(from: URL(fileURLWithPath: arguments[0]))
            let edges = GraphBuilder.edges(from: files)
            var output = edges.map { $0.description + "\n" }.joined()
            guard let cycle = CycleFinder.cycle(in: edges) else {
                return CLIResult(output: output, errorOutput: "", exitCode: 0)
            }
            output += "cycle: " + cycle.joined(separator: " → ") + "\n"
            return CLIResult(output: output, errorOutput: "", exitCode: 1)
        } catch {
            return CLIResult(output: "", errorOutput: "depgraph: \(error.localizedDescription)\n", exitCode: 2)
        }
    }
}
