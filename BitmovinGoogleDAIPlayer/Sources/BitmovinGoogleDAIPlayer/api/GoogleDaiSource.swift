import Foundation

/// Describes a source to load through the Google DAI integration.
public enum GoogleDaiSource: Sendable {
    case live(assetKey: String, apiKey: String?, networkCode: String?)
}
