import BitmovinPlayer
import Foundation

/// Extends ``PlayerFactory`` to create a player with Google DAI support.
public extension PlayerFactory {
    /// Creates and configures a player instance with Google DAI support.
    ///
    /// - Parameter playerConfig: Player configuration.
    /// - Returns: A player instance with Google DAI support.
    @MainActor
    static func createGoogleDaiPlayer(
        playerConfig: PlayerConfig = PlayerConfig(),
        analytics: AnalyticsPlayerConfig = .enabled
    ) -> Player {
        _InternalPlayerGoogleDaiFactory.create(
            playerConfig: playerConfig,
            analytics: analytics
        )
    }
}
