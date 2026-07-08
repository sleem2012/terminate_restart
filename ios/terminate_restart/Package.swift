// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "terminate_restart",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "terminate-restart", targets: ["terminate_restart"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "terminate_restart",
            dependencies: [],
            path: "Sources/terminate_restart"
        )
    ]
)
