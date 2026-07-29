import BitmovinPlayerCore
import Foundation

/// Provides access to Google DAI-specific APIs for a Bitmovin Player instance.
@MainActor
public protocol GoogleDaiApi: AnyObject {
    /// Whether Google DAI is enabled for this Player instance.
    var isEnabled: Bool { get }

    /// Loads a Google DAI source.
    ///
    /// - Parameters:
    ///   - source: The Google DAI source to load.
    ///   - configureSourceConfig: Modify the source config created for the resolved Google DAI stream before it is
    ///     loaded into the Player. Use this to apply source-specific settings such as DRM configuration.
    func load(
        source: GoogleDaiSource,
        configureSourceConfig: @escaping @MainActor (SourceConfig) -> Void
    )

    func destroy()
}

public extension GoogleDaiApi {
    /// Loads a Google DAI source without customizing its source config.
    ///
    /// - Parameter source: The Google DAI source to load.
    func load(source: GoogleDaiSource) {
        load(source: source, configureSourceConfig: { _ in })
    }
}
