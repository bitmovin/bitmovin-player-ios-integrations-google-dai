import BitmovinGoogleDAIPlayer
import Foundation
import PlayerTesting
import Testing

@Suite("Google DAI session lifecycle", .serialized)
struct GoogleDaiSessionLifecycleTest {
    @MainActor
    @Suite("with a Google DAI source")
    struct WithGoogleDaiSource {
        private let googleDaiSource = makeGoogleDaiTestSource()

        @Test("enables Google DAI only on players created by the integration factory")
        func enablesGoogleDaiOnlyForIntegrationPlayers() async throws {
            try await startPlayerTest(buildViewHierarchyMode: .none) {
                verifyPlayer { player in
                    #expect(!player.googleDai.isEnabled)
                }
            }

            try await startGoogleDaiTest(buildViewHierarchyMode: .none) {
                verifyPlayer { player in
                    #expect(player.googleDai.isEnabled)
                }
            }
        }

        @Test("does not start loading without an advertising presentation context")
        func doesNotStartLoadingDaiSource() async throws {
            try await startGoogleDaiTest(buildViewHierarchyMode: .none) {
                callPlayer { player in
                    player.googleDai.load(source: googleDaiSource)
                }

                verifyPlayer { player in
                    #expect(player.googleDai.isEnabled)
                    #expect(player.playlist.sources.isEmpty)
                }
            }
        }

        @Test("loads only the most recently requested source")
        func loadsOnlyMostRecentlyRequestedSource() async throws {
            let supersededTitle = "Superseded Google DAI source"
            let expectedTitle = "Active Google DAI source"

            try await startGoogleDaiTest {
                let sourceLoadedEvent = try await callPlayerAndExpectEvent({ player in
                        player.googleDai.load(source: googleDaiSource) { sourceConfig in
                            sourceConfig.title = supersededTitle
                        }
                        player.googleDai.load(source: googleDaiSource) { sourceConfig in
                            sourceConfig.title = expectedTitle
                        }
                    },
                    SourceLoadedEvent.self
                )

                #expect(sourceLoadedEvent.source.sourceConfig.title == expectedTitle)
                verifyPlayer { player in
                    #expect(player.playlist.sources.count == 1)
                    #expect(player.playlist.sources.first?.sourceConfig.title == expectedTitle)
                }
            }
        }

        @Test("can load a new Google DAI session after destroying the active session")
        func canLoadNewGoogleDaiSession() async throws {
            let expectedTitle = "Reloaded Google DAI source"

            try await startGoogleDaiTest {
                try await loadGoogleDaiSource(googleDaiSource: googleDaiSource)
                callPlayer { player in
                    player.googleDai.destroy()
                }

                let sourceLoadedEvent = try await loadGoogleDaiSource(
                    googleDaiSource: googleDaiSource
                ) { sourceConfig in
                    sourceConfig.title = expectedTitle
                }

                #expect(sourceLoadedEvent.source.sourceConfig.title == expectedTitle)
                verifyPlayer { player in
                    #expect(player.playlist.sources.count == 1)
                }
            }
        }

        @Test("can load another Google DAI source after unloading")
        func canLoadAnotherGoogleDaiSource() async throws {
            try await startGoogleDaiTest {
                try await loadGoogleDaiSource(googleDaiSource: googleDaiSource)
                try await callPlayerAndExpectEvent({ player in
                        player.unload()
                    },
                    SourceUnloadedEvent.self
                )
                try await loadGoogleDaiSource(googleDaiSource: googleDaiSource)
            }
        }
    }
}
