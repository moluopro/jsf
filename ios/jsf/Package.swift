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
        .iOS("13.0")
    ],
    products: [
        // Keep FFI exports in a framework, outside Runner's archive stripping.
        .library(name: "jsf", type: .dynamic, targets: ["jsf"])
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
                    "-fvisibility=hidden",
                    "-fwrapv",
                    "-Wno-shorten-64-to-32",
                    "-Wno-conditional-uninitialized",
                    "-Wno-comma"
                ])
            ],
            // Keep a native reference so the app loads the framework even
            // though Dart resolves its functions by name.
            linkerSettings: [.unsafeFlags(["-Xlinker", "-u", "-Xlinker", "_JSF_RuntimeNew"])]
        )
    ]
)
