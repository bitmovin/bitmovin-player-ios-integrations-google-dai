import BitmovinGoogleDAIPlayer
import Foundation
import PlayerTesting
import Testing

@Suite("Google DAI playback", .serialized)
struct GoogleDaiPlaybackTest {
    @MainActor
    @Suite("when loading a live source")
    struct WhenLoadingLiveSource {
        private let googleDaiSource = makeGoogleDaiTestSource()

        @Test("becomes ready")
        func becomesReady() async throws {
            try await startGoogleDaiTest {
                try await loadGoogleDaiSource(googleDaiSource: googleDaiSource)
            }
        }

        @Test("emits source lifecycle events before becoming ready")
        func emitsSourceLifecycleEventsBeforeBecomingReady() async throws {
            try await startGoogleDaiTest {
                try await callPlayerAndExpectEvents({ player in
                        player.googleDai.load(source: googleDaiSource)
                    },
                    SourceLoadEvent.self,
                    SourceLoadedEvent.self,
                    ReadyEvent.self
                )
            }
        }

        @Test("loads a customized source config")
        func loadsCustomizedSource() async throws {
            let expectedTitle = "Google DAI system test"

            try await startGoogleDaiTest {
                let sourceLoadedEvent = try await loadGoogleDaiSource(
                    googleDaiSource: googleDaiSource
                ) { sourceConfig in
                    sourceConfig.title = expectedTitle
                }

                #expect(sourceLoadedEvent.source.sourceConfig.title == expectedTitle)
            }
        }

        @Test("emits ordered play, pause, and resume events")
        func emitsOrderedPlaybackEvents() async throws {
            try await startGoogleDaiTest {
                try await callPlayerAndExpectEvents({ player in
                        player.googleDai.load(source: googleDaiSource)
                    },
                    PlayEvent.self,
                    PlayingEvent.self
                )
                verifyPlayer { player in
                    #expect(player.isPlaying)
                }

                try await callPlayerAndExpectEvent({ player in
                        player.pause()
                    },
                    PausedEvent.self
                )
                verifyPlayer { player in
                    #expect(!player.isPlaying)
                }

                try await callPlayerAndExpectEvents({ player in
                        player.play()
                    },
                    PlayEvent.self,
                    PlayingEvent.self
                )
                verifyPlayer { player in
                    #expect(player.isPlaying)
                }
            }
        }
    }
}
