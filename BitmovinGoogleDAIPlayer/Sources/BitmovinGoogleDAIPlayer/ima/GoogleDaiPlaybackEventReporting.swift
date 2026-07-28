import Foundation

/// Reports Bitmovin Player playback updates to IMA for the active stream session.
/// This gives the module a semantic API without exposing `IMAVideoDisplayDelegate`.
@MainActor
protocol GoogleDaiPlaybackEventReporting: AnyObject {
    func playbackDidLoad()
    func playbackDidStart()
    func playbackDidPause()
    func playbackDidResume()
    func playbackDidComplete()
    func playbackDidFail(with error: Error)
    func playbackDidProgress(to mediaTime: TimeInterval, duration: TimeInterval)
    func playbackDidReceiveTimedMetadata(_ metadata: [String: String])
    func playbackDidChangeVolume(to volume: Float)
    func playbackDidBuffer(to mediaTime: TimeInterval)
    func playbackDidBecomeReady()
    func playbackDidStartBuffering()
}
