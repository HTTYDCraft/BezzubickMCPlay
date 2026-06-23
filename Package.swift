// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "BezzubickMCPlay",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "CSS", targets: ["CSS"]),
        .executable(name: "BezzubickMCPlay", targets: ["BezzubickMCPlay"]),
        .executable(name: "UpdateData", targets: ["UpdateData"]),
        .executable(name: "SiteClient", targets: ["SiteClient"])
    ],
    dependencies: [
        .package(url: "https://github.com/johnsundell/publish.git", from: "0.9.0"),
        .package(url: "https://github.com/johnsundell/plot", from: "0.14.0"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.53.0")
    ],
    targets: [
        .target(
            name: "CSS",
            dependencies: [],
            path: "Sources/CSS"
        ),
        .executableTarget(
            name: "BezzubickMCPlay",
            dependencies: [
                "CSS",
                .product(name: "Publish", package: "publish"),
                .product(name: "Plot", package: "plot")
            ],
            path: "Sources/BezzubickMCPlay",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .executableTarget(
            name: "UpdateData",
            dependencies: [],
            path: "Sources/UpdateData",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .executableTarget(
            name: "SiteClient",
            dependencies: [
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "JavaScriptEventLoop", package: "JavaScriptKit")
            ],
            path: "Sources/SiteClient",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
