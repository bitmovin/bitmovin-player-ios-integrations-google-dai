import Foundation

/// Describes a source to load through the Google DAI integration.
public struct GoogleDaiSource: Sendable {
    enum ContentType: Sendable {
        case live(assetKey: String)
    }

    let contentType: ContentType
    let apiKey: String?
    let networkCode: String?
    let adTagParameters: [String: String]

    /// Configures a Google DAI live source.
    ///
    /// - Parameters:
    ///   - assetKey: The Google DAI asset key.
    ///   - apiKey: An optional Google DAI API key.
    ///   - networkCode: An optional Google Ad Manager network code.
    ///   - adTagParameters: Additional ad tag parameters forwarded to Google DAI.
    public static func live(
        assetKey: String,
        apiKey: String? = nil,
        networkCode: String? = nil,
        adTagParameters: [String: String] = [:]
    ) -> Self {
        Self(
            contentType: .live(assetKey: assetKey),
            apiKey: apiKey,
            networkCode: networkCode,
            adTagParameters: adTagParameters
        )
    }
}
