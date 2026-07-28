import BitmovinPlayerCore
import Foundation

public extension Player {
    /// Allows access to the Google DAI APIs.
    ///
    /// Accessing this property logs an informational message when this player was not created using
    /// ``PlayerFactory/createGoogleDaiPlayer(playerConfig:analytics:)``. Calls to the returned API have no effect.
    @MainActor
    var googleDai: GoogleDaiApi {
        guard let googleDai = _modules._module(DefaultGoogleDaiPlayerModule.self) else {
            Logger.warn(
                """
                Google DAI is not enabled for this Player. Calls to 'player.googleDai' have no effect. \
                Create the Player using 'PlayerFactory.createGoogleDaiPlayer(...)'.
                """
            )
            return UnavailableGoogleDaiApi.shared
        }

        return googleDai
    }
}
