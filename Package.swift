// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PackIt",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "PackIt",
            path: "Sources/PackIt"
        ),
        .testTarget(
            name: "PackItTests",
            dependencies: ["PackIt"],
            path: "Tests/PackItTests"
        ),
    ]
)
