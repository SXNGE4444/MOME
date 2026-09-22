// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MOME",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MOME", targets: ["MOME"])
    ],
    targets: [
        .executableTarget(
            name: "MOME",
            linkerSettings: [
                .linkedFramework("Security")
            ]
        ),
        .testTarget(
            name: "MOMETests",
            dependencies: ["MOME"]
        )
    ]
)
