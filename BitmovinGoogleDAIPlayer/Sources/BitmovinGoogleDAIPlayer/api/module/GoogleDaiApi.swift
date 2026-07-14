import Foundation

/// Provides access to Google DAI-specific APIs for a Bitmovin Player instance.
@MainActor
public protocol GoogleDaiApi: AnyObject, Sendable {
    /// Loads the Google DAI integration.
    func load(source: GoogleDaiSource)
    func destroy()
}
