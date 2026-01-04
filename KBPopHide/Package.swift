// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KSAPDismiss",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "KSAPDismiss", targets: ["KSAPDismiss"])
    ],
    targets: [
        .executableTarget(
            name: "KSAPDismiss",
            path: "KSAPDismiss",
            exclude: ["Info.plist"],
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "KSAPDismissTests",
            dependencies: ["KSAPDismiss"],
            path: "Tests"
        )
    ]
)
