// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GoeKit",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "GoeKit",
            targets: ["GoeKit"]
        )
    ],
    targets: [
        .target(
            name: "GoeKit"
        ),
        .testTarget(
            name: "GoeKitTests",
            dependencies: ["GoeKit"]
        )
    ]
)
