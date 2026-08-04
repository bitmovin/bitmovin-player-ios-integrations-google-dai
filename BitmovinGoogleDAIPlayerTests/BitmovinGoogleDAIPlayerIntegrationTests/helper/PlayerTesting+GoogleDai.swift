import BitmovinGoogleDAIPlayer
import Foundation
import PlayerTesting

let googleDaiAdEventTimeout: TimeInterval = 60

@MainActor
func startGoogleDaiTest(
    config: PlayerConfig = PlayerConfig(),
    buildViewHierarchyMode: ViewHierarchyBuildMode = .full,
    globalTimeout: TimeInterval = defaultGlobalTimeout,
    heartbeatWindow: TimeInterval? = nil,
    failOnError: Bool = true,
    file: StaticString = #file,
    line: UInt = #line,
    _ testBlock: PlayerTestBlock
) async throws {
    try await startPlayerTest(
        config: config,
        buildViewHierarchyMode: buildViewHierarchyMode,
        globalTimeout: globalTimeout,
        heartbeatWindow: heartbeatWindow,
        failOnError: failOnError,
        playerCreator: { PlayerFactory.createGoogleDaiPlayer(playerConfig: $0) },
        file: file,
        line: line,
        testBlock
    )
}

@MainActor
@discardableResult
func loadGoogleDaiSource(
    googleDaiSource: GoogleDaiSource,
    configureSourceConfig: @escaping @MainActor (SourceConfig) -> Void = { _ in },
    timeout: TimeInterval? = nil,
    file: StaticString = #file,
    line: UInt = #line
) async throws -> SourceLoadedEvent {
    let events = try await callPlayerAndExpectEvents({ player in
            player.googleDai.load(
                source: googleDaiSource,
                configureSourceConfig: configureSourceConfig
            )
        },
        B(ReadyEvent.self, SourceLoadedEvent.self),
        timeout: timeout,
        file: file,
        line: line
    )

    guard let sourceLoadedEvent = events.first(where: { $0 is SourceLoadedEvent }) as? SourceLoadedEvent else {
        throw PlayerTestingError.expectationNotMet
    }
    return sourceLoadedEvent
}

func makeGoogleDaiTestSource(
    adTagParameters: [String: String] = [:]
) -> GoogleDaiSource {
    GoogleDaiSource.live(
        assetKey: "c-rArva4ShKVIAkNfy6HUQ",
        networkCode: "21775744923",
        adTagParameters: adTagParameters
    )
}
