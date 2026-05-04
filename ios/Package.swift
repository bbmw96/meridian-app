// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MERIDIAN",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(name: "MERIDIAN", targets: ["MERIDIAN"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apollographql/apollo-ios",
            from: "1.9.0"
        ),
        .package(
            url: "https://github.com/apple/swift-collections",
            from: "1.1.0"
        ),
        .package(
            url: "https://github.com/nicklockwood/SwiftFormat",
            from: "0.54.0"
        ),
    ],
    targets: [
        .target(
            name: "MERIDIAN",
            dependencies: [
                .product(name: "Apollo", package: "apollo-ios"),
                .product(name: "ApolloAPI", package: "apollo-ios"),
                .product(name: "Collections", package: "swift-collections"),
            ],
            path: "MERIDIAN",
            resources: [
                .process("Resources"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "MERIDIANTests",
            dependencies: ["MERIDIAN"],
            path: "MERIDIANTests"
        ),
    ]
)
