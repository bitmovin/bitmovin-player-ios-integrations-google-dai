# Bitmovin Player Google DAI Integration

This open-source project enables [Google Dynamic Ad Insertion (DAI)](https://developers.google.com/ad-manager/dynamic-ad-insertion) for the [Bitmovin Player iOS SDK](https://developer.bitmovin.com/playback/docs/getting-started-ios).

## Maintenance and Support

This project is not part of a regular maintenance or update schedule and is updated at Bitmovin's discretion.

If you encounter a Player or integration issue, open a support ticket through the [Bitmovin Dashboard](https://dashboard.bitmovin.com/support/tickets). As this integration is an open-source project and not a core product offering, requests and issues are excluded from any applicable SLA or support terms.

As an open-source project, we are pleased to accept any and all changes, updates and fixes from the community wishing to use this project. Please see [CONTRIBUTING.md](CONTRIBUTING.md) for more details on how to contribute.

## Supported Features

- Google DAI live streams
- iOS 15+
- tvOS 15+

## Getting Started

Follow the [Bitmovin Player iOS getting started guide](https://developer.bitmovin.com/playback/docs/getting-started-ios) for the general Player setup.

Before loading a Google DAI stream, you need:

- A Bitmovin Player license key
- A Google DAI live stream asset key
- An API key and network code when required by your Google DAI configuration

## Installation

`BitmovinGoogleDAIPlayer` is available through Swift Package Manager.

### Xcode

1. In Xcode, select **File** > **Add Package Dependencies...**
2. Enter `https://github.com/bitmovin/bitmovin-player-ios-integrations-google-dai.git`.
3. Select your desired version.
4. Add `BitmovinGoogleDAIPlayer` to your target.

### Package.swift

Add the package dependency:

```swift
dependencies: [
    .package(
        url: "https://github.com/bitmovin/bitmovin-player-ios-integrations-google-dai.git",
        exact: "<VERSION>"
    )
]
```

Then add the integration product to your target:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(
                name: "BitmovinGoogleDAIPlayer",
                package: "bitmovin-player-ios-integrations-google-dai"
            )
        ]
    )
]
```

## Basic Usage

Create the Player with `PlayerFactory.createGoogleDaiPlayer(...)` to enable Google DAI.

```swift
import BitmovinGoogleDAIPlayer
import BitmovinPlayer

let playerConfig = PlayerConfig()
playerConfig.key = "<PLAYER_LICENSE_KEY>"

let player = PlayerFactory.createGoogleDaiPlayer(
    playerConfig: playerConfig
)

// Attach the Player to a PlayerView or VideoPlayerView before loading the source.
player.googleDai.load(
    source: .live(
        assetKey: "<GOOGLE_DAI_ASSET_KEY>",
        apiKey: nil,
        networkCode: "<GOOGLE_DAI_NETWORK_CODE>"
    )
)
```

The Player must be attached to a `PlayerView` or `VideoPlayerView` before calling `load(source:)`. This gives the integration the view context required to present the Google IMA ad UI.

## Advanced Usage

### Integration Availability

The `player.googleDai` namespace is always available, but it is enabled only for Player instances created with `PlayerFactory.createGoogleDaiPlayer(...)`. Use `isEnabled` to check its availability at runtime:

```swift
guard player.googleDai.isEnabled else {
    return
}
```

When Google DAI is unavailable, accessing the namespace logs a warning and subsequent calls have no effect.

## Sample App

The [`BitmovinGoogleDAIPlayerExample`](BitmovinGoogleDAIPlayerExample) directory contains a minimal SwiftUI example. Configure it with your own Bitmovin Player license key and Google DAI stream values before running it.
