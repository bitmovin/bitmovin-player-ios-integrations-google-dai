import BitmovinPlayer
import Foundation

/// A Google DAI module that can be attached to an existing ``Player`` instance.
///
/// Create instances with ``_InternalGoogleDaiPlayerModuleFactory``. Regular Swift integrations should create
/// the player with ``PlayerFactory/createGoogleDaiPlayer(playerConfig:analytics:)`` instead.
@MainActor
public protocol _InternalGoogleDaiPlayerModule: _PlayerModule {}
