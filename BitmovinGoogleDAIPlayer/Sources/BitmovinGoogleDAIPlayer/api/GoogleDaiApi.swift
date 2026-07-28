import Foundation

/// Provides access to Google DAI-specific APIs for a Bitmovin Player instance.
@MainActor
public protocol GoogleDaiApi: AnyObject {
    /// Whether Google DAI is enabled for this Player instance.
    var isEnabled: Bool { get }

    /// Loads the Google DAI integration.
    func load(source: GoogleDaiSource)
    func destroy()
}
