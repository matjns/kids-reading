// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ReadingQuest",
    products: [
        .library(name: "ReadingCore", targets: ["ReadingCore"])
    ],
    targets: [
        .target(
            name: "ReadingCore",
            path: "Sources/ReadingCore",
            resources: [
                .copy("Passages")
            ]
        ),
        .testTarget(
            name: "ReadingCoreTests",
            dependencies: ["ReadingCore"],
            path: "Tests/ReadingCoreTests"
        )
    ]
)
