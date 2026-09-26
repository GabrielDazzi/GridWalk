// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "GridWalkKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "GridWalkKit", targets: ["GridWalkKit"])
    ],
    targets: [
        .target(
            name: "GridWalkKit",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "GridWalkKitTests",
            dependencies: ["GridWalkKit"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
