// swift-tools-version:6.2
import Foundation
import PackageDescription

// The Mac App Store edition is sandboxed and has no Sparkle, because the store does the updating.
// scripts/appstore-app.sh sets this.
let appStore = ProcessInfo.processInfo.environment["PAIRHOP_APPSTORE"] != nil

let package = Package(
    name: "PairHop",
    platforms: [.macOS(.v26)],
    dependencies: appStore ? [] : [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0"),
    ],
    targets: [
        .executableTarget(
            name: "PairHop",
            dependencies: appStore ? [] : [
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources/PairHop",
            exclude: ["Info.plist"],
            swiftSettings: appStore ? [.define("APPSTORE")] : [],
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
