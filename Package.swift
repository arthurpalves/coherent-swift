// swift-tools-version:5.2

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
            from: "0.3.0"
        ),
        .package(
            url: "https://github.com/kylef/PathKit",
            from: "1.0.0"
        ),
        .package(
            url: "https://github.com/jpsim/Yams.git",
            from: "4.0.1"
        ),
        .package(
			name: "SwiftSyntax",
            url: "https://github.com/apple/swift-syntax.git",
            .exact("0.50300.0")
        )
    ],
    targets: [
        .target(
            name: "CoherentSwiftCore",
            dependencies: [
                "PathKit",
                "Yams",
                "SwiftSyntax"
            ]
        ),
        .target(
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
