import BitmovinGoogleDAIPlayer
import Foundation
import PlayerTesting
import Testing

@Suite("Google DAI advertising", .serialized)
struct GoogleDaiAdvertisingTest {
    @MainActor
    @Suite("with a Google DAI stream")
    struct WithGoogleDaiStream {
        private let googleDaiSource = makeGoogleDaiTestSource()

        @Test("exposes ad data and emits the complete lifecycle in order")
        func exposesAdDataAndEmitsLifecycleInOrder() async throws {
            try await startGoogleDaiTest {
                try await loadGoogleDaiSource(googleDaiSource: googleDaiSource)

                var startedAdBreak: AdBreak?
                var startedAd: Ad?

                try await callPlayerAndExpectEvents({ player in
                        player.play()
                    },
                    S(
                        F(AdBreakStartedEvent.self) { event in
                            #expect(event.adBreak.identifier.hasPrefix("google-dai-"))
                            #expect(event.adBreak.scheduleTime.isFinite)
                            #expect(event.adBreak.scheduleTime >= 0)
                            #expect(event.adBreak.totalNumberOfAds > 0)
                            startedAdBreak = event.adBreak
                            return true
                        },
                        F(AdStartedEvent.self) { event in
                            #expect(event.ad.identifier?.isEmpty == false)
                            #expect(event.duration > 0)
                            #expect(event.indexInQueue == 0)
                            #expect(event.clientType == AdSourceType.none)
                            #expect(event.timeOffset == startedAdBreak?.scheduleTime)
                            #expect(event.position == startedAdBreak.map { String($0.scheduleTime) })
                            startedAd = event.ad
                            verifyPlayer { player in
                                #expect(player.isAd)
                                #expect(player.ads.activeAd === event.ad)
                            }
                            return true
                        },
                        F(AdQuartileEvent.self) { event in
                            #expect(event.adQuartile == .firstQuartile)
                            verifyPlayer { player in
                                #expect(player.isAd)
                                #expect(player.ads.activeAd === startedAd)
                            }
                            return true
                        },
                        F(AdQuartileEvent.self) { event in
                            #expect(event.adQuartile == .midpoint)
                            verifyPlayer { player in
                                #expect(player.isAd)
                                #expect(player.ads.activeAd === startedAd)
                            }
                            return true
                        },
                        F(AdQuartileEvent.self) { event in
                            #expect(event.adQuartile == .thirdQuartile)
                            verifyPlayer { player in
                                #expect(player.isAd)
                                #expect(player.ads.activeAd === startedAd)
                            }
                            return true
                        },
                        F(AdFinishedEvent.self) { event in
                            #expect(event.ad === startedAd)
                            return true
                        },
                        F(AdBreakFinishedEvent.self) { event in
                            #expect(event.adBreak === startedAdBreak)
                            verifyPlayer { player in
                                #expect(!player.isAd)
                                #expect(player.ads.activeAd == nil)
                            }
                            return true
                        }
                    ),
                    timeout: googleDaiAdEventTimeout
                )
            }
        }

        @Test("reports a fatal advertising error for a rejected stream request")
        func reportsFatalAdvertisingError() async throws {
            let invalidSource = GoogleDaiSource.live(
                assetKey: "invalid-system-test-asset-key",
                networkCode: "21775744923"
            )

            try await startGoogleDaiTest(failOnError: false) {
                let errorEvent = try await callPlayerAndExpectEvent({ player in
                        player.googleDai.load(source: invalidSource)
                    },
                    PlayerErrorEvent.self,
                    timeout: 30
                )

                #expect(errorEvent.errorCode == PlayerError.Code.advertising.rawValue)
                #expect(!errorEvent.message.isEmpty)
                verifyPlayer { player in
                    #expect(player.playlist.sources.isEmpty)
                }
            }
        }
    }
}
