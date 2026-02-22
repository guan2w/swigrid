// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SchulteGridNative",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26),
    ],
    products: [
        .library(
            name: "SchulteDomain",
            targets: ["SchulteDomain"]
        ),
        .library(
            name: "SchulteData",
            targets: ["SchulteData"]
        ),
        .library(
            name: "SchulteFeatures",
            targets: ["SchulteFeatures"]
        ),
        .library(
            name: "SchulteAppUI",
            targets: ["SchulteAppUI"]
        ),
        .executable(
            name: "SchulteApp",
            targets: ["SchulteApp"]
        ),
    ],
    targets: [
        .target(
            name: "SchulteDomain"
        ),
        .target(
            name: "SchulteData",
            dependencies: ["SchulteDomain"]
        ),
        .target(
            name: "SchulteFeatures",
            dependencies: ["SchulteDomain"]
        ),
        .target(
            name: "SchulteAppUI",
            dependencies: ["SchulteDomain", "SchulteData", "SchulteFeatures"],
            path: "Sources/SchulteApp",
            resources: [
                .copy("Resources/audio"),
                .copy("Resources/font"),
                .copy("Resources/md"),
                .copy("Resources/icon"),
                .process("Resources/en.lproj"),
                .process("Resources/zh-Hans.lproj"),
            ]
        ),
        .executableTarget(
            name: "SchulteApp",
            dependencies: ["SchulteAppUI"],
            path: "Sources/SchulteAppExecutable"
        ),
        .testTarget(
            name: "SchulteDomainTests",
            dependencies: ["SchulteDomain"]
        ),
        .testTarget(
            name: "SchulteDataTests",
            dependencies: ["SchulteDomain", "SchulteData"]
        ),
        .testTarget(
            name: "SchulteFeaturesTests",
            dependencies: ["SchulteDomain", "SchulteFeatures"]
        ),
    ]
)
