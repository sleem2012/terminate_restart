// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "terminate_restart",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        // The library name is hyphen separated because Swift Package Manager uses
        // it as the CFBundleIdentifier when the product is linked dynamically, and
        // a CFBundleIdentifier cannot contain underscores.
        .library(name: "terminate-restart", targets: ["terminate_restart"])
    ],
    // The Flutter framework is intentionally not declared as a package dependency.
    //
    // Flutter 3.44+ generates a local `FlutterFramework` package next to the
    // plugin and prints an author-only warning suggesting:
    //     .package(name: "FlutterFramework", path: "../FlutterFramework")
    // That package does not exist on Flutter < 3.42, so declaring it would break
    // Swift Package Manager builds for anyone on an older SDK. Flutter still
    // supplies the framework to this target either way, so the dependency is
    // omitted to stay compatible across every SwiftPM-capable Flutter release.
    dependencies: [],
    targets: [
        .target(
            name: "terminate_restart",
            dependencies: []
        )
    ]
)
