// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "BezzubickMCPlay",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/johnsundell/publish.git", from: "0.9.0"),
        .package(url: "https://github.com/johnsundell/plot.git", from: "0.14.0"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.53.0")
    ],
    targets: [
        // Small CSS DSL used by the static site generator.
        .target(
            name: "CSS",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        // Static site generator (Publish). Produces the Output/ directory.
        .executableTarget(
            name: "BezzubickMCPlay",
            dependencies: [
                .product(name: "Publish", package: "publish"),
                .product(name: "Plot", package: "plot"),
                "CSS"
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        // CLI that fetches subscriber counts / live status and writes data.json + streams_history.json.
        .executableTarget(
            name: "UpdateData",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        // WebAssembly progressive enhancement (Liquid Glass WebGL background).
        .executableTarget(
            name: "SiteClient",
            dependencies: [
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "JavaScriptEventLoop", package: "JavaScriptKit")
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        // Unit tests for the generator helpers (run with `swift test`).
        .testTarget(
            name: "BezzubickMCPlayTests",
            dependencies: ["BezzubickMCPlay"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
