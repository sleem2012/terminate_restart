// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "terminate_restart",
    platforms: [.iOS(.v12)],
    products: [
        .library(name: "terminate-restart", targets: ["terminate_restart"])
    ],
    // Older SwiftPM-enabled Flutter versions do not generate FlutterFramework
    // as a package. Flutter supplies the framework to the plugin build.
    targets: [.target(name: "terminate_restart")]
)
