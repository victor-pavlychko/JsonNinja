// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JsonNinja",
    products: [
        .library(name: "JsonNinja", targets: ["JsonNinja"]),
    ],
    targets: [
        .target(
            name: "JsonNinja",
            dependencies: []

            // Looks like we no longer need @_specialize with cross-module optimization
            // Need to research and test more.
            // swiftSettings: [.unsafeFlags(["-cross-module-optimization"])]
        ),
        .testTarget(
            name: "JsonNinjaCoreTests",
            dependencies: ["JsonNinja"]
        ),
        .testTarget(
            name: "JsonNinjaPerformanceTests",
            dependencies: ["JsonNinja"],
            resources: [.copy("Data")]
        ),
    ]
)
