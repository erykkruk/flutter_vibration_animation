// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "haptic_kit",
    platforms: [
        .iOS("15.0"),
    ],
    products: [
        .library(name: "haptic-kit", targets: ["haptic_kit"]),
    ],
    targets: [
        .target(
            name: "haptic_kit",
            resources: []
        ),
    ]
)
