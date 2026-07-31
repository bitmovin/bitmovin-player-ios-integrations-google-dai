@_spi(ExperimentalApi) import BitmovinPlayerCore
import Foundation
import GoogleInteractiveMediaAds

/// Adapts immutable IMA ad metadata to the Bitmovin Player SSAI ad model.
/// It also carries the associated break identity needed to construct the SSAI break on ad start.
final class GoogleDaiSsaiAd: SsaiProviderAd {
    let identifier: String?
    let duration: TimeInterval
    let clickThroughUrl: URL? = nil

    let adBreakIdentifier: String
    let adBreakScheduleTime: TimeInterval

    init(ad: IMAAd) {
        identifier = ad.adId.isEmpty ? nil : ad.adId
        duration = ad.duration
        adBreakIdentifier = "google-dai-\(ad.adPodInfo.podIndex)-\(ad.adPodInfo.timeOffset)"
        adBreakScheduleTime = ad.adPodInfo.timeOffset
    }
}
