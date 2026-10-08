import XCTest
@testable import DepGraphCore

final class CLITests: XCTestCase {
    private func fixtureURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Fixtures/Layered")
    }

    private func tempProject(_ files: [String: String]) throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        for (path, contents) in files {
            let url = root.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try contents.write(to: url, atomically: true, encoding: .utf8)
        }
        return root
    }

    func testFixturePrintsExpectedEdgesAndCycleAndFails() {
        let result = CLI.run(arguments: [fixtureURL().path])
        XCTAssertEqual(result.output, """
            Domain → Data
            Domain → UI
            UI → Domain
            cycle: Domain → UI → Domain
            """ + "\n")
        XCTAssertEqual(result.exitCode, 1)
    }

    func testAcyclicProjectExitsZero() throws {
        let root = try tempProject([
            "UI/V.swift": "import Domain\n",
            "Domain/M.swift": "import Data\n",
            "Data/S.swift": "import Foundation\n",
        ])
        let result = CLI.run(arguments: [root.path])
        XCTAssertEqual(result.output, "Domain → Data\nUI → Domain\n")
        XCTAssertEqual(result.exitCode, 0)
    }

    func testIgnoresNonSwiftFiles() throws {
        let root = try tempProject(["UI/notes.txt": "import Domain\n", "Domain/M.swift": ""])
        XCTAssertEqual(CLI.run(arguments: [root.path]).output, "")
    }

    func testMissingArgumentIsUsageError() {
        let result = CLI.run(arguments: [])
        XCTAssertEqual(result.exitCode, 2)
        XCTAssertTrue(result.errorOutput.contains("usage: depgraph <path>"))
    }

    func testMissingDirectoryIsError() {
        let result = CLI.run(arguments: ["/nonexistent/dir/xyz"])
        XCTAssertEqual(result.exitCode, 2)
        XCTAssertFalse(result.errorOutput.isEmpty)
    }
}
