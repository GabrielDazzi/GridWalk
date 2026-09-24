// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "GridWalkKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "GridWalkKit", targets: ["GridWalkKit"]),
    ],
    targets: [
        .target(name: "GridWalkKit"),
        .testTarget(
            name: "GridWalkKitTests",
            dependencies: ["GridWalkKit"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
