// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "depgraph",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        .target(
            name: "DepGraphCore",
            dependencies: [
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ]
        ),
        .executableTarget(name: "depgraph", dependencies: ["DepGraphCore"]),
        .testTarget(name: "DepGraphTests", dependencies: ["DepGraphCore"]),
    ]
)
