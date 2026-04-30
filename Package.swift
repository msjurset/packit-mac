// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PackIt",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.7.0"),
    ],
    targets: [
        .target(
            name: "PackItKit",
            path: "Sources/PackItKit"
        ),
        .executableTarget(
            name: "PackIt",
            dependencies: ["Sparkle", "PackItKit"],
            path: "Sources/PackIt"
        ),
        .executableTarget(
            name: "packit-backup",
            dependencies: ["PackItKit"],
            path: "Sources/packit-backup"
        ),
        .testTarget(
            name: "PackItTests",
            dependencies: ["PackIt", "PackItKit"],
            path: "Tests/PackItTests"
        ),
    ]
)
