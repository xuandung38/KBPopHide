// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KSAPDismiss",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "KSAPDismiss", targets: ["KSAPDismiss"]),
        .executable(name: "KSAPDismissApp", targets: ["KSAPDismissApp"])
    ],
    targets: [
        // Library target containing all app code (testable)
        // Named "KSAPDismiss" to match Xcode module name
        .target(
            name: "KSAPDismiss",
            path: "KSAPDismiss",
            exclude: ["Info.plist"],
            resources: [
                .copy("Resources")
            ]
        ),
        // Executable target with app entry point
        .executableTarget(
            name: "KSAPDismissApp",
            dependencies: ["KSAPDismiss"],
            path: "App",
            sources: ["main.swift"]
        ),
        .testTarget(
            name: "KSAPDismissTests",
            dependencies: ["KSAPDismiss"],
            path: "Tests"
        )
    ]
)
