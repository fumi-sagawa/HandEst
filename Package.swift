// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HandEst",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "HandEst",
            targets: ["HandEst"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "HandEst",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
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
