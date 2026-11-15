// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "PairHop",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "PairHop",
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
