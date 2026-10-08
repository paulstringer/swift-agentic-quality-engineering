import XCTest
@testable import DepGraphCore

final class ImportScannerTests: XCTestCase {
    func testFindsPlainImports() {
        XCTAssertEqual(ImportScanner.imports(in: "import Domain\nimport Data\n"), ["Domain", "Data"])
    }

    func testUsesTopLevelModuleOfSubmoduleAndDeclImports() {
        let source = "import struct Foundation.URL\nimport Domain.Sub\n@testable import UI\n"
        XCTAssertEqual(ImportScanner.imports(in: source), ["Foundation", "Domain", "UI"])
    }

    func testIgnoresImportsInCommentsAndStrings() {
        let source = "// import Domain\nlet s = \"import Data\"\n/* import UI */\nimport Real\n"
        XCTAssertEqual(ImportScanner.imports(in: source), ["Real"])
    }
}
