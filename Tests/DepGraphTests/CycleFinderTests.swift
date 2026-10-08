import XCTest
@testable import DepGraphCore

final class CycleFinderTests: XCTestCase {
    func testNoCycleInLayeredEdges() {
        XCTAssertNil(CycleFinder.cycle(in: [Edge("UI", "Domain"), Edge("Domain", "Data")]))
    }

    func testFindsTwoNodeCycle() {
        let cycle = CycleFinder.cycle(in: [Edge("UI", "Domain"), Edge("Domain", "UI")])
        XCTAssertEqual(cycle, ["Domain", "UI", "Domain"])
    }

    func testFindsLongerCycleIgnoringTail() {
        let edges = [Edge("A", "B"), Edge("B", "C"), Edge("C", "A"), Edge("C", "D")]
        XCTAssertEqual(CycleFinder.cycle(in: edges), ["A", "B", "C", "A"])
    }
}
