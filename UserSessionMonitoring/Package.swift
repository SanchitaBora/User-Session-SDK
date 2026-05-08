// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UserSessionSDK",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(name: "UserSessionSDK", targets: ["UserSessionSDK"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Core",
            dependencies: [],
            path: "Sources/Core"
        ),
        .target(
            name: "UserSessionSDK",
            dependencies: ["Core"],
            path: "Sources/UserSessionSDK"
        ),
    ]
)
