// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeIPBarCore",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ClaudeIPBarCore",
            targets: ["ClaudeIPBarCore"]
        )
    ],
    targets: [
        .target(
            name: "ClaudeIPBarCore",
            path: "Sources/ClaudeIPBarCore"
        ),
        .testTarget(
            name: "ClaudeIPBarCoreTests",
            dependencies: ["ClaudeIPBarCore"],
            path: "Tests/ClaudeIPBarCoreTests",
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
