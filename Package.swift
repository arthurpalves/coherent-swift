// swift-tools-version:5.4

import PackageDescription

#if swift(>=5.5)
let branch = "release/5.5"
#elseif swift(>=5.4)
let branch = "release/5.4"
#else
let branch = "release/5.3"
#endif

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
	.package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax.git", .branch(branch)),
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
