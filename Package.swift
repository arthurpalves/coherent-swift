// swift-tools-version:5.4

import PackageDescription


let package = Package(
    name: "CoherentSwift",
	platforms: [
		.macOS(.v10_15)
	],
    products: [
        .executable(name: "coherent-swift", targets: ["CoherentSwift"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            from: "1.0.1"
        ),
        .package(
            url: "https://github.com/kylef/PathKit",
            from: "1.0.1"
        ),
        .package(
            url: "https://github.com/jpsim/Yams.git",
            from: "4.0.6"
        ),
        .package(
            name: "SwiftSyntax",
            url: "https://github.com/apple/swift-syntax.git",
            .revision("093e5ee151d206454e2c1950d81333c4d4a4472e")
        ),
    ],
    targets: [
        .target(
            name: "CoherentSwiftCore",
            dependencies: [
                "PathKit",
                "Yams",
                .product(name: "SwiftSyntax", package: "SwiftSyntax"),
                .product(name: "SwiftParser", package: "SwiftSyntax")
            ]
        ),
        .executableTarget(
            name: "CoherentSwift",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "CoherentSwiftCore"
            ]
        ),
        .testTarget(
            name: "CLITests",
            dependencies: ["CoherentSwift"]
        ),
    ]
)
