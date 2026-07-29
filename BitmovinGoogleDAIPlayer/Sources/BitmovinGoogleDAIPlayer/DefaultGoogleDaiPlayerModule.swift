import AVFoundation
@_spi(ExperimentalApi) import BitmovinPlayerCore
import Combine
import Foundation

/// Coordinates Google DAI with a Bitmovin Player instance.
/// It is the single boundary that performs Player loading, playback control, and SSAI API interactions.
@MainActor
final class DefaultGoogleDaiPlayerModule: _PlayerModule {
    private(set) weak var player: Player?

    private lazy var streamSessionController = GoogleDaiStreamSessionController(
        playbackControlDelegate: self,
        playbackInfoDataSource: self,
        adEventDelegate: self
    )

    private var loadTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var hasReportedPlaybackStart = false
    private var activeSsaiAdBreak: GoogleDaiSsaiAdBreak?
    private var activeSsaiAd: GoogleDaiSsaiAd?

    init(player: Player) {
        self.player = player
        subscribeToPlayerEvents(player)
    }
}

extension DefaultGoogleDaiPlayerModule: GoogleDaiApi {
    var isEnabled: Bool {
        true
    }

    func load(source: GoogleDaiSource) {
        guard let player else {
            Logger.error("Google DAI cannot load because the Player is no longer available.")
            return
        }
        guard let presentationContext = player.ads.presentationContext else {
            Logger.error(
                """
                Google DAI cannot load because the Player has no advertising presentation context. \
                Attach the Player to a PlayerView before calling 'player.googleDai.load(source:)'.
                """
            )
            return
        }

        cancelLoading()

        streamSessionController.register(
            adContainer: presentationContext.adContainer,
            viewController: presentationContext.viewController
        )

        loadTask = Task { @MainActor [weak self] in
            guard let self, let player = self.player else {
                return
            }

            do {
                try Task.checkCancellation()
                let streamUrl = try await streamSessionController.load(source: source)
                try Task.checkCancellation()
                player.load(sourceConfig: SourceConfig(url: streamUrl, type: .hls))
            } catch is CancellationError {
                return
            } catch {
                player.ssai.reportFatalError(message: error.localizedDescription)
            }
        }
    }

    func destroy() {
        cancelLoading()
        streamSessionController.destroy()
    }
}

extension DefaultGoogleDaiPlayerModule: GoogleDaiPlaybackControlDelegate {
    func playbackDidRequestPlay() {
        player?.play()
    }

    func playbackDidRequestPause() {
        player?.pause()
    }

    func playbackDidRequestReset() {
        player?.unload()
    }

    func playbackDidRequestSeek(to time: TimeInterval) {
        player?.seek(time: time)
    }

    func playbackDidRequestVolume(_ volume: Float) {
        player?.volume = Int((min(max(volume, 0), 1) * 100).rounded())
    }
}

extension DefaultGoogleDaiPlayerModule: GoogleDaiPlaybackInfoDataSource {
    var currentMediaTime: TimeInterval {
        player?.currentTime ?? 0
    }

    var totalMediaTime: TimeInterval {
        let duration = player?.duration ?? 0
        return duration.isFinite ? duration : 0
    }

    var bufferedMediaTime: TimeInterval {
        guard let player else {
            return 0
        }
        return player.currentTime + player.buffer.getLevel(.forwardDuration).level
    }

    var isPlaying: Bool {
        player?.isPlaying ?? false
    }

    var volume: Float {
        guard let player, !player.isMuted else {
            return 0
        }
        return Float(player.volume) / 100
    }
}

extension DefaultGoogleDaiPlayerModule: GoogleDaiAdEventDelegate {
    func adStarted(_ ad: GoogleDaiSsaiAd) {
        guard let player else {
            return
        }

        finishSsaiAd()
        if let activeSsaiAdBreak, activeSsaiAdBreak.identifier == ad.adBreakIdentifier {
            activeSsaiAdBreak.add(ad: ad)
        } else {
            finishSsaiAdBreak()
            let adBreak = GoogleDaiSsaiAdBreak(firstAd: ad)
            activeSsaiAdBreak = adBreak
            adBreak.playerAdBreak = player.ssai.start(adBreak: adBreak)
        }

        activeSsaiAd = ad
        ad.playerAd = player.ssai.start(ad: ad)
    }

    func adClicked() {
        activeSsaiAd?.playerAd?.clickThroughUrlOpened?()
    }

    func adTapped() {
        guard let player else {
            return
        }

        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
    }

    func adCompleted() {
        finishSsaiAd()
    }

    func adSkipped() {
        finishSsaiAd()
    }

    func adPeriodEnded() {
        finishSsaiAdBreak()
    }

    func adBreakEnded() {
        finishSsaiAdBreak()
    }

    func allAdsCompleted() {
        finishSsaiAdBreak()
    }

    func adReachedFirstQuartile() {
        player?.ssai.reportAdQuartile(.firstQuartile)
    }

    func adReachedMidpoint() {
        player?.ssai.reportAdQuartile(.midpoint)
    }

    func adReachedThirdQuartile() {
        player?.ssai.reportAdQuartile(.thirdQuartile)
    }

    func adLog(message: String, errorCode: Int) {
        player?.ssai.reportAdError(message: message, errorCode: errorCode)
    }

    func adBreakFetchFailed(message: String, errorCode: Int) {
        player?.ssai.reportAdError(message: message, errorCode: errorCode)
    }

    func adPlaybackFailed(message: String, errorCode: Int) {
        player?.ssai.reportAdError(message: message, errorCode: errorCode)
    }

    private func finishSsaiAdBreak() {
        guard activeSsaiAdBreak != nil else {
            return
        }

        finishSsaiAd()
        player?.ssai.finishAdBreak()
        activeSsaiAdBreak = nil
    }

    private func finishSsaiAd() {
        guard activeSsaiAd != nil else {
            return
        }

        player?.ssai.finishAd()
        activeSsaiAd = nil
    }
}

private extension DefaultGoogleDaiPlayerModule {
    func cancelLoading() {
        loadTask?.cancel()
        loadTask = nil
        finishSsaiAdBreak()
        hasReportedPlaybackStart = false
    }

    func subscribeToPlayerEvents(_ player: Player) {
        player.events.on(ReadyEvent.self)
            .sink { [weak self] _ in
                self?.streamSessionController.playbackEventReporter.playbackDidLoad()
                self?.streamSessionController.playbackEventReporter.playbackDidBecomeReady()
            }
            .store(in: &cancellables)

        player.events.on(PlayingEvent.self)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                if hasReportedPlaybackStart {
                    streamSessionController.playbackEventReporter.playbackDidResume()
                } else {
                    hasReportedPlaybackStart = true
                    streamSessionController.playbackEventReporter.playbackDidStart()
                }
            }
            .store(in: &cancellables)

        player.events.on(PausedEvent.self)
            .sink { [weak self] _ in
                self?.streamSessionController.playbackEventReporter.playbackDidPause()
            }
            .store(in: &cancellables)

        player.events.on(TimeChangedEvent.self)
            .sink { [weak self] event in
                guard let self else {
                    return
                }
                streamSessionController.playbackEventReporter.playbackDidProgress(
                    to: event.currentTime,
                    duration: totalMediaTime
                )
                streamSessionController.playbackEventReporter.playbackDidBuffer(to: bufferedMediaTime)
            }
            .store(in: &cancellables)

        player.events.on(MetadataEvent.self)
            .sink { [weak self] event in
                guard let self,
                      event.metadataType == .ID3,
                      let metadata = event.metadata as? Id3Metadata
                else {
                    return
                }

                // IMA expects custom video displays to forward AVMetadataItem keys and values:
                // https://groups.google.com/g/ima-sdk/c/YDaAi0joR08
                let timedMetadata = metadata.entries.reduce(into: [String: String]()) { result, entry in
                    guard let item = entry as? AVMetadataItem,
                          let key = item.key?.description,
                          let value = item.stringValue
                    else {
                        return
                    }
                    result[key] = value
                }
                guard !timedMetadata.isEmpty else { return }
                streamSessionController.playbackEventReporter.playbackDidReceiveTimedMetadata(timedMetadata)
            }
            .store(in: &cancellables)

        player.events.on(PlaybackFinishedEvent.self)
            .sink { [weak self] _ in
                self?.streamSessionController.playbackEventReporter.playbackDidComplete()
            }
            .store(in: &cancellables)

        player.events.on(StallStartedEvent.self)
            .sink { [weak self] _ in
                self?.streamSessionController.playbackEventReporter.playbackDidStartBuffering()
            }
            .store(in: &cancellables)

        player.events.on(StallEndedEvent.self)
            .sink { [weak self] _ in
                self?.streamSessionController.playbackEventReporter.playbackDidBecomeReady()
            }
            .store(in: &cancellables)

        player.events.on(MutedEvent.self)
            .sink { [weak self] _ in
                self?.streamSessionController.playbackEventReporter.playbackDidChangeVolume(to: 0)
            }
            .store(in: &cancellables)

        player.events.on(UnmutedEvent.self)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                streamSessionController.playbackEventReporter.playbackDidChangeVolume(to: volume)
            }
            .store(in: &cancellables)

        player.events.on(PlayerErrorEvent.self)
            .sink { [weak self] event in
                self?.streamSessionController.playbackEventReporter.playbackDidFail(
                    with: NSError(
                        domain: "BitmovinPlayer",
                        code: event.errorCode,
                        userInfo: [NSLocalizedDescriptionKey: event.message]
                    )
                )
            }
            .store(in: &cancellables)

        player.events.on(SourceErrorEvent.self)
            .sink { [weak self] event in
                self?.streamSessionController.playbackEventReporter.playbackDidFail(
                    with: NSError(
                        domain: "BitmovinPlayer.Source",
                        code: event.errorCode,
                        userInfo: [NSLocalizedDescriptionKey: event.message]
                    )
                )
            }
            .store(in: &cancellables)
    }
}
