import BitmovinPlayerCore
import Foundation

public extension Player {
    /// Allows access to the Google DAI APIs when Google DAI is enabled for the player.
    ///
    /// Returns `nil` if the player was not created using ``PlayerFactory/createGoogleDaiPlayer(playerConfig:)``.
    @MainActor
    var googleDaiIfEnabled: GoogleDaiApi? {
        _modules._module(DefaultGoogleDaiPlayerModule.self)
    }

    /// Allows access to the Google DAI APIs.
    ///
    /// The player must have been created using ``PlayerFactory/createGoogleDaiPlayer(playerConfig:)``.
    ///
    /// - Important: Accessing this property when Google DAI is not enabled triggers a fatal error and terminates the app.
    @MainActor
    var googleDai: GoogleDaiApi {
        guard let googleDai = googleDaiIfEnabled else {
            fatalError(
                "Google DAI is unavailable because this player instance was not created using "
                    + "PlayerFactory.createGoogleDaiPlayer(playerConfig:)."
            )
        }

        return googleDai
    }
}
