// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "coherent-swift",
    products: [
        .executable(name: "coherent-swift", targets: ["coherent-swift"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/jakeheis/SwiftCLI",
            from: "6.0.0"
        ),
        .package(
            url: "https://github.com/kylef/PathKit",
            from: "1.0.0"
        ),
        .package(
            url: "https://github.com/jpsim/Yams.git",
            from: "2.0.0"
        )
    ],
    targets: [
        .target(
            name: "coherent-swift",
            dependencies: [
                "SwiftCLI",
                "PathKit",
                "Yams"
            ]
        ),
        .testTarget(
            name: "coherent-swiftTests",
            dependencies: ["coherent-swift"]
        ),
    ]
)
