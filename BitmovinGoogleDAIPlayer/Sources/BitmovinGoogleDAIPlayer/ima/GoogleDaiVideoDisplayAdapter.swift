import Foundation
import GoogleInteractiveMediaAds

/// Adapts IMA's bidirectional `IMAVideoDisplay` API to the integration's directional protocols.
/// It isolates the Objective-C API while keeping playback commands, state reads, and event reporting distinct.
@MainActor
final class GoogleDaiVideoDisplayAdapter: NSObject {
    typealias StreamLoadHandler = @MainActor (URL) -> Void

    weak var playbackControlDelegate: (any GoogleDaiPlaybackControlDelegate)?
    weak var playbackInfoDataSource: (any GoogleDaiPlaybackInfoDataSource)?

    var streamLoadHandler: StreamLoadHandler?

    weak var delegate: (any IMAVideoDisplayDelegate)?

    init(
        playbackControlDelegate: any GoogleDaiPlaybackControlDelegate,
        playbackInfoDataSource: any GoogleDaiPlaybackInfoDataSource
    ) {
        self.playbackControlDelegate = playbackControlDelegate
        self.playbackInfoDataSource = playbackInfoDataSource
        super.init()
    }
}

extension GoogleDaiVideoDisplayAdapter: @preconcurrency IMAVideoDisplay {
    var volume: Float {
        get { playbackInfoDataSource?.volume ?? 1 }
        set { playbackControlDelegate?.playbackDidRequestVolume(newValue) }
    }

    var currentMediaTime: TimeInterval {
        playbackInfoDataSource?.currentMediaTime ?? 0
    }

    var totalMediaTime: TimeInterval {
        playbackInfoDataSource?.totalMediaTime ?? 0
    }

    var bufferedMediaTime: TimeInterval {
        playbackInfoDataSource?.bufferedMediaTime ?? 0
    }

    var isPlaying: Bool {
        playbackInfoDataSource?.isPlaying ?? false
    }

    func loadStream(_ streamURL: URL, withSubtitles _: [[String: String]]) {
        streamLoadHandler?(streamURL)
    }

    func play() {
        playbackControlDelegate?.playbackDidRequestPlay()
    }

    func pause() {
        playbackControlDelegate?.playbackDidRequestPause()
    }

    func reset() {
        playbackControlDelegate?.playbackDidRequestReset()
    }

    func seekStream(toTime _: TimeInterval) {
        // TODO: Forward IMA seek requests when Google DAI VOD support is added.
    }

    func skipCurrentInterstitialItem() {}
}

extension GoogleDaiVideoDisplayAdapter: GoogleDaiPlaybackEventReporting {
    func playbackDidLoad() {
        delegate?.videoDisplayDidLoad(self)
    }

    func playbackDidStart() {
        delegate?.videoDisplayDidStart(self)
    }

    func playbackDidPause() {
        delegate?.videoDisplayDidPause(self)
    }

    func playbackDidResume() {
        delegate?.videoDisplayDidResume(self)
    }

    func playbackDidComplete() {
        delegate?.videoDisplayDidComplete(self)
    }

    func playbackDidFail(with error: Error) {
        delegate?.videoDisplay(self, didReceiveError: error as NSError)
    }

    func playbackDidProgress(to mediaTime: TimeInterval, duration: TimeInterval) {
        delegate?.videoDisplay(self, didProgressWithMediaTime: mediaTime, totalTime: duration)
    }

    func playbackDidReceiveTimedMetadata(_ metadata: [String: String]) {
        delegate?.videoDisplay(self, didReceiveTimedMetadata: metadata)
    }

    func playbackDidChangeVolume(to volume: Float) {
        delegate?.videoDisplay(self, volumeChangedTo: NSNumber(value: volume))
    }

    func playbackDidBuffer(to mediaTime: TimeInterval) {
        delegate?.videoDisplay?(self, didBufferToMediaTime: mediaTime)
    }

    func playbackDidBecomeReady() {
        delegate?.videoDisplayIsPlaybackReady?(self)
    }

    func playbackDidStartBuffering() {
        delegate?.videoDisplayDidStartBuffering?(self)
    }
}
