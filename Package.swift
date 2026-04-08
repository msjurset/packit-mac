// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PackIt",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.7.0"),
    ],
    targets: [
        .executableTarget(
            name: "PackIt",
            dependencies: ["Sparkle"],
            path: "Sources/PackIt"
        ),
        .testTarget(
            name: "PackItTests",
            dependencies: ["PackIt"],
            path: "Tests/PackItTests"
        ),
    ]
)
