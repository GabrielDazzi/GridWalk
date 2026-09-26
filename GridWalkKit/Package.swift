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
        .library(name: "GridWalkKit", targets: ["GridWalkKit"]),
        .library(name: "GridWalkDesign", targets: ["GridWalkDesign"]),
    ],
    targets: [
        .target(
            name: "GridWalkKit",
            resources: [.process("Resources")]
        ),
        // SwiftUI tokens and shared components; the kit itself stays UI-free
        .target(
            name: "GridWalkDesign",
            dependencies: ["GridWalkKit"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "GridWalkKitTests",
            dependencies: ["GridWalkKit"],
            resources: [.copy("Fixtures")]
        ),
        .testTarget(
            name: "GridWalkDesignTests",
            dependencies: ["GridWalkDesign", "GridWalkKit"]
        ),
    ]
)
