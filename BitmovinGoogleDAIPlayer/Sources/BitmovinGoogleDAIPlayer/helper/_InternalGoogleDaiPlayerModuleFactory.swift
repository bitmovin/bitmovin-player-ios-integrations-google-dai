import BitmovinPlayer
import Foundation

/// Creates a Google DAI module for a ``Player`` that already exists.
///
/// This factory is intended for bridge integrations, such as React Native, that create the player before attaching
/// optional modules. Regular Swift integrations should use
/// ``PlayerFactory/createGoogleDaiPlayer(playerConfig:analytics:)`` instead.
@MainActor
public enum _InternalGoogleDaiPlayerModuleFactory {
    /// Creates a Google DAI module for the provided player.
    ///
    /// Register the module before calling any Google DAI APIs:
    ///
    /// ```swift
    /// player._modules._registerModule {
    ///     _InternalGoogleDaiPlayerModuleFactory.create(player: $0)
    /// }
    /// ```
    ///
    /// - Parameter player: The player that will own the module.
    /// - Returns: A Google DAI module to register with the same player.
    public static func create(player: Player) -> _InternalGoogleDaiPlayerModule {
        DefaultGoogleDaiPlayerModule(player: player)
    }
}
