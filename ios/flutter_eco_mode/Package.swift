// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_eco_mode",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(
            name: "flutter-eco-mode",
            targets: ["flutter_eco_mode"]
        )
    ],
    targets: [
        .target(
            name: "flutter_eco_mode"
        ),
    ]
)