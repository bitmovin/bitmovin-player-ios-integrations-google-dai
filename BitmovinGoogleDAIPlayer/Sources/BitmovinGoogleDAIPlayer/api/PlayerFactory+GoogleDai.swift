import BitmovinPlayer
import Foundation

/// Extends ``PlayerFactory`` to create a player with Google DAI support.
public extension PlayerFactory {
    /// Creates and configures a player instance with Google DAI support.
    ///
    /// - Parameters:
    ///   - playerConfig: Player configuration
    ///   - analytics: Analytics player config to customize analytics data collection, or to disable analytics support
    /// - Returns: A ``Player`` instance with Google DAI support.
    @MainActor
    static func createGoogleDaiPlayer(
        playerConfig: PlayerConfig = PlayerConfig(),
        analytics: AnalyticsPlayerConfig = .enabled
    ) -> Player {
        GoogleDaiPlayerFactory.create(
            playerConfig: playerConfig,
            analytics: analytics
        )
    }
}
