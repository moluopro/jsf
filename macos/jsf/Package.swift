// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let quickjsVersion = try String(contentsOf: URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().appendingPathComponent("../../src/quickjs/VERSION"),
    encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)

let package = Package(
    name: "jsf",
    platforms: [
        .macOS("10.15")
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
                .define("CONFIG_VERSION", to: "\"\(quickjsVersion)\""),
                .unsafeFlags([
                    "-fwrapv",
                    "-Wno-shorten-64-to-32",
                    "-Wno-conditional-uninitialized",
                    "-Wno-comma"
                ])
            ],
            linkerSettings: [.unsafeFlags(["-Xlinker", "-u", "-Xlinker", "_JSF_RuntimeNew"])]
        )
    ]
)
