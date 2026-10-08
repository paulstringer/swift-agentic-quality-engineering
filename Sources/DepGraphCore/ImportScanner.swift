import SwiftParser
import SwiftSyntax

enum ImportScanner {
    /// Top-level module names of every `import` declaration, in source order.
    static func imports(in source: String) -> [String] {
        let collector = ImportCollector(viewMode: .sourceAccurate)
        collector.walk(Parser.parse(source: source))
        return collector.modules
    }
}

private final class ImportCollector: SyntaxVisitor {
    var modules: [String] = []

    override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        if let first = node.path.first {
            modules.append(first.name.text)
        }
        return .skipChildren
    }
}
