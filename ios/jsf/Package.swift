// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "jsf",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "jsf", targets: ["jsf"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "jsf",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            cSettings: [
                .headerSearchPath("include/jsf"),
                .define("_GNU_SOURCE", to: "1"),
                .define("CONFIG_VERSION", to: "\"2026-06-04\""),
                .unsafeFlags([
                    "-fwrapv",
                    "-Wno-shorten-64-to-32",
                    "-Wno-conditional-uninitialized",
                    "-Wno-comma"
                ])
            ]
        )
    ]
)
