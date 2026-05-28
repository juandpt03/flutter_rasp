// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_rasp",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "flutter-rasp", targets: ["flutter_rasp"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_rasp",
            dependencies: [
                "FlutterRaspCore",
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        ),
        .binaryTarget(
            name: "FlutterRaspCore",
            path: "FlutterRaspCore.xcframework"
        )
    ]
)
