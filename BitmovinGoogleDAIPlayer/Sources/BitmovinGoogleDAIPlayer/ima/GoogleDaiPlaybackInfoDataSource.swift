import Foundation

/// Supplies IMA with synchronous information about the current player state.
/// This separates IMA's state queries from the commands it sends to the player.
@MainActor
protocol GoogleDaiPlaybackInfoDataSource: AnyObject {
    var currentMediaTime: TimeInterval { get }
    var totalMediaTime: TimeInterval { get }
    var bufferedMediaTime: TimeInterval { get }
    var isPlaying: Bool { get }
    var volume: Float { get }
}
