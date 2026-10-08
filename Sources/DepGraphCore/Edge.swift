struct Edge: Hashable, Comparable {
    let from: String
    let to: String

    init(_ from: String, _ to: String) {
        self.from = from
        self.to = to
    }

    var description: String { "\(from) → \(to)" }

    static func < (lhs: Edge, rhs: Edge) -> Bool {
        (lhs.from, lhs.to) < (rhs.from, rhs.to)
    }
}
