// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacAndroidToolbox",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MacAndroidToolbox",
            targets: ["MacAndroidToolbox"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MacAndroidToolbox",
            path: "Sources"
        )
    ]
)
