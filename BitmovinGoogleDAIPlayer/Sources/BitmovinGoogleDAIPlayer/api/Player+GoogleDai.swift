import BitmovinPlayerCore
import Foundation

public extension Player {
    /// Allows access to the Google DAI APIs.
    ///
    /// - Note: Accessing this namespace on a Player instance without Google DAI enabled has no effect
    /// and logs a warning. Use ``PlayerFactory/createGoogleDaiPlayer(playerConfig:analytics:)`` to
    /// create a Player instance with Google DAI enabled. To check dynamically whether Google DAI is
    /// enabled, use ``GoogleDaiApi/isEnabled``.
    /// logs a warning. Use ``PlayerFactory/createGoogleDaiPlayer(playerConfig:analytics:)`` to create a Player
    /// instance with Google DAI enabled. To dynamically check whether Google DAI is enabled
    /// use ``GoogleDaiApi/isEnabled``.
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
