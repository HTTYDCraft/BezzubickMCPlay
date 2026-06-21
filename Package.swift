// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BezzubickMCPlay",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "BezzubickMCPlay", targets: ["BezzubickMCPlay"]),
        .executable(name: "UpdateData", targets: ["UpdateData"])
    ],
    dependencies: [
        .package(url: "https://github.com/johnsundell/publish.git", from: "0.9.0"),
        .package(url: "https://github.com/johnsundell/plot", from: "0.14.0")
    ],
    targets: [
        .executableTarget(
            name: "BezzubickMCPlay",
            dependencies: [
                .product(name: "Publish", package: "publish"),
                .product(name: "Plot", package: "plot")
            ],
            path: "Sources/BezzubickMCPlay"
        ),
        .executableTarget(
            name: "UpdateData",
            dependencies: [],
            path: "Sources/UpdateData"
        )
    ]
)
