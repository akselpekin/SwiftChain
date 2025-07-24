// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "SwiftChain",
    platforms: [
        .macOS(.v15),
    ],
    targets: [
        .executableTarget(
            name: "swiftchain",
            dependencies: ["LOGIC", "CONTRACT"],
            path: "Sources/CORE"
        ),
        .target(
            name: "CONTRACT",
            path: "Sources/CONTRACT"
        ),
        .target(
            name: "LOGIC",
            dependencies: ["CONTRACT"],
            path: "Sources/LOGIC"
        ),
    ]
)