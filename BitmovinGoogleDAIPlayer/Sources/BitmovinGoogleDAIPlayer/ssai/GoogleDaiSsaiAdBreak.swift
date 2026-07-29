@_spi(ExperimentalApi) import BitmovinPlayerCore
import Foundation

/// Represents an IMA ad pod as a mutable Bitmovin Player SSAI ad break.
/// Ads are appended as IMA announces them because live DAI does not provide the full pod upfront.
final class GoogleDaiSsaiAdBreak: SsaiProviderAdBreak {
    let identifier: String
    let scheduleTime: TimeInterval
    let linearAdUiConfig: LinearAdUiConfig
    private(set) var ads: [SsaiProviderAd]
    /// The Player ad break returned after registering this provider ad break with the Player through
    /// `SsaiApi.start(adBreak:)`.
    var playerAdBreak: SsaiAdBreak?

    init(firstAd: GoogleDaiSsaiAd) {
        linearAdUiConfig = LinearAdUiConfig()
        linearAdUiConfig.requestsUi = false
        identifier = firstAd.adBreakIdentifier
        scheduleTime = firstAd.adBreakScheduleTime
        ads = [firstAd]
    }

    func add(ad: GoogleDaiSsaiAd) {
        ads.append(ad)
    }
}
