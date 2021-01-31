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
            dependencies: [],
            swiftSettings: [.crossModuleOptimization]
        ),
        .testTarget(
            name: "JsonNinjaCoreTests",
            dependencies: ["JsonNinja"]
        ),
        .testTarget(
            name: "JsonNinjaMinefieldTests",
            dependencies: ["JsonNinja"],
            resources: [.copy("Data")]
        ),
        .testTarget(
            name: "JsonNinjaPerformanceTests",
            dependencies: ["JsonNinja"],
            resources: [.copy("Data")]
        ),
    ]
)

extension SwiftSetting {
    static let crossModuleOptimization: SwiftSetting  = .unsafeFlags(["-cross-module-optimization"])
}
