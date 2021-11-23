// swift-tools-version:5.5

// Copyright © 2021 SpotHero, Inc. All rights reserved.

import PackageDescription

let package = Package(
    name: "CoreDataHero",
    platforms: [
        .iOS(.v15),         // supports NSPersistentContainer
        .macOS(.v10_12),    // supports NSPersistentContainer
        .tvOS(.v10),        // supports NSPersistentContainer
        .watchOS(.v3),      // supports NSPersistentContainer
    ],
    products: [
        .library(name: "CoreDataHero", targets: ["CoreDataHero"]),
    ],
    dependencies: [],
    targets: [
        // Library Product Targets
        .target(name: "CoreDataHero"),
        // Test Targets
        .testTarget(
            name: "CoreDataHeroTests",
            dependencies: [
                .target(name: "CoreDataHero"),
            ]
        ),
    ],
    swiftLanguageVersions: [
        .v5,
    ]
)
