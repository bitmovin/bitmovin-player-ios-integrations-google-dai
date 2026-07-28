import BitmovinPlayer
import Foundation

enum _InternalPlayerGoogleDaiFactory {
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
