// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "OrchidKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "OrchidProtocol", targets: ["OrchidProtocol"]),
        .library(name: "OrchidKit", targets: ["OrchidKit"]),
        .library(name: "OrchidChatUI", targets: ["OrchidChatUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/steipete/ElevenLabsKit", exact: "0.1.0"),
        .package(url: "https://github.com/gonzalezreal/textual", exact: "0.3.1"),
    ],
    targets: [
        .target(
            name: "OrchidProtocol",
            path: "Sources/OrchidProtocol",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "OrchidKit",
            dependencies: [
                "OrchidProtocol",
                .product(name: "ElevenLabsKit", package: "ElevenLabsKit"),
            ],
            path: "Sources/OrchidKit",
            resources: [
                .process("Resources"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .target(
            name: "OrchidChatUI",
            dependencies: [
                "OrchidKit",
                .product(
                    name: "Textual",
                    package: "textual",
                    condition: .when(platforms: [.macOS, .iOS])),
            ],
            path: "Sources/OrchidChatUI",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .testTarget(
            name: "OrchidKitTests",
            dependencies: ["OrchidKit", "OrchidChatUI"],
            path: "Tests/OrchidKitTests",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableExperimentalFeature("SwiftTesting"),
            ]),
    ])
