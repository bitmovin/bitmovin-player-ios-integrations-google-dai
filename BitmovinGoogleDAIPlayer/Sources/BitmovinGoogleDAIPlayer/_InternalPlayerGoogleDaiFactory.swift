import BitmovinPlayer
import Foundation

enum GoogleDaiPlayerFactory {
    /// Creates a Player instance with an attached Google DAI module
    @MainActor
    static func create(
        playerConfig: PlayerConfig,
        analytics: AnalyticsPlayerConfig
    ) -> Player {
        let player = PlayerFactory.createPlayer(
            playerConfig: playerConfig,
            analytics: analytics
        )

        player._modules._registerModule {
            DefaultGoogleDaiPlayerModule(player: $0)
        }

        return player
    }
}
