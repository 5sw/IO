// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "IO",
    products: [
        .library(name: "IO", targets: ["IO"]),
        .library(name: "CompressedIO", targets: ["CompressedIO"])
    ],
    targets: [
        .target(
            name: "IO",
            dependencies: []
        ),
        .target(
            name: "CompressedIO",
            dependencies: [
                .target(name: "IO"),
            ]
        )
    ]
)
