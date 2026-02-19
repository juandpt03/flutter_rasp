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
    dependencies: [],
    targets: [
        .target(
            name: "flutter_rasp",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
