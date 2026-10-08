import XCTest
@testable import DepGraphCore

final class GraphBuilderTests: XCTestCase {
    func testEdgesFromFilesGroupedByTopLevelFolder() {
        let files = [
            SourceFile(relativePath: "UI/View.swift", contents: "import Domain\nimport Foundation\n"),
            SourceFile(relativePath: "Domain/Model.swift", contents: "import Data\n"),
            SourceFile(relativePath: "Data/Store.swift", contents: "import Foundation\n"),
        ]
        XCTAssertEqual(GraphBuilder.edges(from: files), [Edge("Domain", "Data"), Edge("UI", "Domain")])
    }

    func testDeduplicatesEdgesAndIgnoresSelfImports() {
        let files = [
            SourceFile(relativePath: "UI/A.swift", contents: "import Domain\nimport UI\n"),
            SourceFile(relativePath: "UI/Sub/B.swift", contents: "import Domain\n"),
            SourceFile(relativePath: "Domain/C.swift", contents: ""),
        ]
        XCTAssertEqual(GraphBuilder.edges(from: files), [Edge("UI", "Domain")])
    }

    func testFilesAtRootBelongToNoComponent() {
        let files = [
            SourceFile(relativePath: "main.swift", contents: "import Domain\n"),
            SourceFile(relativePath: "Domain/C.swift", contents: ""),
        ]
        XCTAssertEqual(GraphBuilder.edges(from: files), [])
    }
}
