import Foundation

/// Receives playback commands issued by IMA and applies them to the integration's player.
/// This keeps IMA's imperative `IMAVideoDisplay` API out of the player module.
@MainActor
protocol GoogleDaiPlaybackControlDelegate: AnyObject {
    func playbackDidRequestPlay()
    func playbackDidRequestPause()
    func playbackDidRequestReset()
    func playbackDidRequestSeek(to time: TimeInterval)
    func playbackDidRequestVolume(_ volume: Float)
}
