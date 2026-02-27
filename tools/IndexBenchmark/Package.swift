// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IndexBenchmark",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "index-bench",
            path: ".",
            exclude: ["setup-symlinks.sh", "reset-index.sh"],
            sources: [
                "Sources/index-bench",
                "SharedSources/Indexing",
                "SharedSources/Model",
                "SharedSources/Search",
                "SharedSources/Services",
                "SharedSources/Utilities",
                "SharedSources/Support",
            ],
            swiftSettings: [
                .define("INDEX_BENCH_CLI"),
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3"),
            ]
        ),
    ]
)
