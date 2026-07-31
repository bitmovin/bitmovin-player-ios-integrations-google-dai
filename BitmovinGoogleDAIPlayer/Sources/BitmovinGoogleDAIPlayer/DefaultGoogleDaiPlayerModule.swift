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
    private var activeDaiSource: Source?
    private var activeDaiSourcePlayerEventCancellables = Set<AnyCancellable>()
    private var activeDaiSourceUnloadCancellable: AnyCancellable?
    private var hasReportedPlaybackStart = false
    private var activeSsaiAdBreak: GoogleDaiSsaiAdBreak?
    private var activeSsaiAd: GoogleDaiSsaiAd?

    init(player: Player) {
        self.player = player
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

        unloadGoogleDaiSession()

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

                let sourceConfig = SourceConfig(url: streamUrl, type: .hls)
                let source = createDaiSource(sourceConfig: sourceConfig, player: player)
                player.load(source: source)
            } catch is CancellationError {
                return
            } catch {
                player.ssai.reportFatalError(message: error.localizedDescription)
            }
        }
    }

    func destroy() {
        unloadGoogleDaiSession()
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

    func playbackDidRequestVolume(_ volume: Float) {
        player?.volume = Int((min(max(volume, 0), 1) * 100).rounded())
    }
}

extension DefaultGoogleDaiPlayerModule: GoogleDaiPlaybackInfoDataSource {
    var currentMediaTime: TimeInterval {
        player?.currentTime(.relativeTime) ?? 0
    }

    var totalMediaTime: TimeInterval {
        let duration = player?.duration ?? 0
        return duration.isFinite ? duration : 0
    }

    var bufferedMediaTime: TimeInterval {
        guard let player else {
            return 0
        }
        return player.currentTime(.relativeTime) + player.buffer.getLevel(.forwardDuration).level
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
            player.ssai.start(adBreak: adBreak)
        }

        activeSsaiAd = ad
        player.ssai.start(ad: ad)
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
    func createDaiSource(sourceConfig: SourceConfig, player: Player) -> Source {
        activeDaiSourceUnloadCancellable?.cancel()

        let source = SourceFactory.createSource(from: sourceConfig)
        activeDaiSource = source
        subscribeToPlayerEvents(forDaiSource: source, in: player)

        activeDaiSourceUnloadCancellable = source.events.on(SourceUnloadEvent.self)
            .sink { [weak self] event in
                guard let self, let activeDaiSource, activeDaiSource === event.source else {
                    return
                }

                unloadGoogleDaiSession()
            }

        return source
    }

    func unloadGoogleDaiSession() {
        // Cancel any ongoing loading
        loadTask?.cancel()
        loadTask = nil

        // Cancel and reset current loaded source if any
        activeDaiSourceUnloadCancellable?.cancel()
        activeDaiSourceUnloadCancellable = nil
        activeDaiSource = nil

        // Cancel current player subscriptions
        activeDaiSourcePlayerEventCancellables.removeAll()

        finishSsaiAdBreak()
        hasReportedPlaybackStart = false

        streamSessionController.destroy()
    }

    /// Forwards Player events to the IMA session only while `source` is the Player's current source.
    /// These subscriptions belong to the active DAI source and are cancelled when its session ends.
    func subscribeToPlayerEvents(forDaiSource source: Source, in player: Player) {
        player.events.on(SourceLoadedEvent.self)
            .filterForCurrentSource(source, in: player)
            .sink { [weak self] _ in
                self?.streamSessionController.playbackEventReporter.playbackDidLoad()
            }
            .store(in: &activeDaiSourcePlayerEventCancellables)

        player.events.on(ReadyEvent.self)
            .filterForCurrentSource(source, in: player)
            .sink { [weak self] _ in
                self?.streamSessionController.playbackEventReporter.playbackDidBecomeReady()
            }
            .store(in: &activeDaiSourcePlayerEventCancellables)

        player.events.on(PlayingEvent.self)
            .filterForCurrentSource(source, in: player)
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
            .store(in: &activeDaiSourcePlayerEventCancellables)

        player.events.on(PausedEvent.self)
            .filterForCurrentSource(source, in: player)
            .sink { [weak self] _ in
                self?.streamSessionController.playbackEventReporter.playbackDidPause()
            }
            .store(in: &activeDaiSourcePlayerEventCancellables)

        player.events.on(TimeChangedEvent.self)
            .filterForCurrentSource(source, in: player)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                streamSessionController.playbackEventReporter.playbackDidProgress(
                    to: currentMediaTime,
                    duration: totalMediaTime
                )
                streamSessionController.playbackEventReporter.playbackDidBuffer(to: bufferedMediaTime)
            }
            .store(in: &activeDaiSourcePlayerEventCancellables)

        player.events.on(MetadataEvent.self)
            .filterForCurrentSource(source, in: player)
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
            .store(in: &activeDaiSourcePlayerEventCancellables)

        player.events.on(PlaybackFinishedEvent.self)
            .filterForCurrentSource(source, in: player)
            .sink { [weak self] _ in
                self?.streamSessionController.playbackEventReporter.playbackDidComplete()
            }
            .store(in: &activeDaiSourcePlayerEventCancellables)

        player.events.on(StallStartedEvent.self)
            .filterForCurrentSource(source, in: player)
            .sink { [weak self] _ in
                self?.streamSessionController.playbackEventReporter.playbackDidStartBuffering()
            }
            .store(in: &activeDaiSourcePlayerEventCancellables)

        player.events.on(StallEndedEvent.self)
            .filterForCurrentSource(source, in: player)
            .sink { [weak self] _ in
                self?.streamSessionController.playbackEventReporter.playbackDidBecomeReady()
            }
            .store(in: &activeDaiSourcePlayerEventCancellables)

        player.events.on(MutedEvent.self)
            .filterForCurrentSource(source, in: player)
            .sink { [weak self] _ in
                self?.streamSessionController.playbackEventReporter.playbackDidChangeVolume(to: 0)
            }
            .store(in: &activeDaiSourcePlayerEventCancellables)

        player.events.on(UnmutedEvent.self)
            .filterForCurrentSource(source, in: player)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                streamSessionController.playbackEventReporter.playbackDidChangeVolume(to: volume)
            }
            .store(in: &activeDaiSourcePlayerEventCancellables)

        player.events.on(PlayerErrorEvent.self)
            .filterForCurrentSource(source, in: player)
            .sink { [weak self] event in
                self?.streamSessionController.playbackEventReporter.playbackDidFail(
                    with: NSError(
                        domain: "BitmovinPlayer",
                        code: event.errorCode,
                        userInfo: [NSLocalizedDescriptionKey: event.message]
                    )
                )
            }
            .store(in: &activeDaiSourcePlayerEventCancellables)

        player.events.on(SourceErrorEvent.self)
            .filterForCurrentSource(source, in: player)
            .sink { [weak self] event in
                self?.streamSessionController.playbackEventReporter.playbackDidFail(
                    with: NSError(
                        domain: "BitmovinPlayer.Source",
                        code: event.errorCode,
                        userInfo: [NSLocalizedDescriptionKey: event.message]
                    )
                )
            }
            .store(in: &activeDaiSourcePlayerEventCancellables)
    }
}

private extension Publisher {
    /// Emits values only while `source` is the Player's current source instance.
    func filterForCurrentSource(
        _ source: Source,
        in player: Player
    ) -> Publishers.Filter<Self> {
        filter { [weak player, weak source] _ in
            guard let player, let source else {
                return false
            }

            return player.source === source
        }
    }
}
