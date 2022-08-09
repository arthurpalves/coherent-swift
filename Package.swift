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
            .exact("0.50600.1")
        )
    ],
    targets: [
        .target(
            name: "CoherentSwiftCore",
            dependencies: [
                "PathKit",
                "Yams",
                .product(name: "SwiftSyntax", package: "SwiftSyntax"),
                .product(name: "SwiftSyntaxParser", package: "SwiftSyntax"),
                "lib_InternalSwiftSyntaxParser"
            ],
            // Pass `-dead_strip_dylibs` to ignore the dynamic version of `lib_InternalSwiftSyntaxParser`
            // that ships with SwiftSyntax because we want the static version from
            // `StaticInternalSwiftSyntaxParser`.
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-dead_strip_dylibs"])
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

        .binaryTarget(
            name: "lib_InternalSwiftSyntaxParser",
            url: "https://github.com/keith/StaticInternalSwiftSyntaxParser/releases/download/5.6/lib_InternalSwiftSyntaxParser.xcframework.zip",
            checksum: "88d748f76ec45880a8250438bd68e5d6ba716c8042f520998a438db87083ae9d"
        )
    ]
)
