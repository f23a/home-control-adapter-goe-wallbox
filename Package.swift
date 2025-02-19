// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "home-control-adapter-goe-wallbox",
    platforms: [.macOS(.v15)],
    dependencies: [
//        .package(path: "../home-control-kit"),
//        .package(path: "../home-control-client"),
        .package(url: "https://github.com/f23a/home-control-client.git", from: "1.7.3"),
        .package(url: "https://github.com/f23a/home-control-logging.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(path: "GoeKit")
    ],
    targets: [
        .executableTarget(
            name: "home-control-adapter-goe-wallbox",
            dependencies: [
                .product(name: "HomeControlClient", package: "home-control-client"),
                .product(name: "HomeControlLogging", package: "home-control-logging"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "GoeKit", package: "GoeKit")
            ]
        )
    ]
)

