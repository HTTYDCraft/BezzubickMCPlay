// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BezzubickMCPlay",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/johnsundell/publish.git", from: "0.12.0"),
        .package(url: "https://github.com/johnsundell/plugin-markdown.git", from: "0.4.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "BezzubickMCPlay",
            dependencies: [
                .product(name: "Publish", package: "publish"),
                .product(name: "PluginMarkdown", package: "plugin-markdown"),
            ]
        ),
        .testTarget(
            name: "BezzubickMCPlayTests",
            dependencies: ["BezzubickMCPlay"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
