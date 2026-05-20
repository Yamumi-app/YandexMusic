// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this
// package.

import PackageDescription

let package = Package(
    name: "YandexMusic",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(name: "YandexMusic", targets: ["YandexMusic"]),
    ],
    targets: [
        .target(
            name: "YandexMusic",
            path: "Sources"
        ),
        .executableTarget(
            name: "Playground",
            dependencies: ["YandexMusic"],
            path: "Playground"
        ),
    ]
)
