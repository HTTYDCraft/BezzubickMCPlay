// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MyWebsite",
    platforms: [.macOS(.v12)],
    products: [
        .executable(
            name: "MyWebsite",
            targets: ["MyWebsite"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/johnsundell/publish.git", from: "0.9.0")
    ],
    targets: [
        .executableTarget(
            name: "MyWebsite",
            dependencies: [
                .product(name: "Publish", package: "Publish")
            ]
        )
    ]
)
