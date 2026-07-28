// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BitmovinGoogleDAIPlayer",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BitmovinGoogleDAIPlayer",
            targets: ["BitmovinGoogleDAIPlayer"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/bitmovin/player-ios.git", exact: "3.119.0-a.1"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-interactive-media-ads-ios", exact: "3.31.0"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-interactive-media-ads-tvos", exact: "4.16.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BitmovinGoogleDAIPlayer",
            dependencies: [
                .product(name: "BitmovinPlayer", package: "player-ios"),
                .product(
                    name: "GoogleInteractiveMediaAds",
                    package: "swift-package-manager-google-interactive-media-ads-ios",
                    condition: .when(platforms: [.iOS])
                ),
                .product(
                    name: "GoogleInteractiveMediaAdsTvOS",
                    package: "swift-package-manager-google-interactive-media-ads-tvos",
                    condition: .when(platforms: [.tvOS])
                )
            ],
            path: "BitmovinGoogleDAIPlayer/Sources/BitmovinGoogleDAIPlayer"
        ),
    ]
)
