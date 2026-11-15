// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "PairHop",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0"),
    ],
    targets: [
        .executableTarget(
            name: "PairHop",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources/PairHop",
            exclude: ["Info.plist"],
            linkerSettings: [
                .linkedFramework("IOBluetooth"),
                .linkedFramework("IOKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("CoreGraphics"),
            ]
        ),
        .testTarget(
            name: "PairHopTests",
            dependencies: ["PairHop"],
            path: "Tests/PairHopTests"
        )
    ]
)
