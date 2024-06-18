// swift-tools-version: 5.10.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenAI",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "OpenAI",
            targets: ["OpenAI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.8.2"),
    ],
    targets: [
        .target(
            name: "OpenAI",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
            ]
        ),
        .testTarget(
            name: "OpenAITests",
            dependencies: ["OpenAI"]
        ),
    ]
)
