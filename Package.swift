// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HandEst",
    platforms: [
        .iOS(.v17),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "HandEst",
            targets: ["HandEst"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0"),
        .package(path: "./LocalPackages/SwiftTasksVision")
    ],
    targets: [
        .target(
            name: "HandEst",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "SwiftTasksVision", package: "SwiftTasksVision")
            ],
            path: "HandEst",
            exclude: [
                "Preview Content",
                "Assets.xcassets"
            ]
        ),
        .testTarget(
            name: "HandEstTests",
            dependencies: ["HandEst"],
            path: "HandEstTests"
        )
    ]
)
