import Foundation
import GoogleInteractiveMediaAds

/// Translates raw IMA stream manager callbacks into semantic integration events.
/// This prevents IMA event enums and loosely typed payload dictionaries from reaching the player module.
@MainActor
final class GoogleDaiAdEventAdapter {
    weak var delegate: (any GoogleDaiAdEventDelegate)?

    init(delegate: any GoogleDaiAdEventDelegate) {
        self.delegate = delegate
    }

    func handle(event: IMAAdEvent) {
        switch event.type {
        case .STARTED:
            guard let ad = event.ad else {
                return
            }
            delegate?.adStarted(GoogleDaiSsaiAd(ad: ad))
        case .CLICKED:
            delegate?.adClicked()
        case .COMPLETE:
            delegate?.adCompleted()
        case .SKIPPED:
            delegate?.adSkipped()
        case .AD_PERIOD_ENDED:
            delegate?.adPeriodEnded()
        case .AD_BREAK_ENDED:
            delegate?.adBreakEnded()
        case .ALL_ADS_COMPLETED:
            delegate?.allAdsCompleted()
        case .FIRST_QUARTILE:
            delegate?.adReachedFirstQuartile()
        case .MIDPOINT:
            delegate?.adReachedMidpoint()
        case .THIRD_QUARTILE:
            delegate?.adReachedThirdQuartile()
        case .LOG:
            let logData = event.adData?["logData"] as? [String: Any]
            let message = logData?["errorMessage"] as? String
                ?? "Google DAI reported a non-fatal ad error."
            let errorCode = (logData?["errorCode"] as? NSNumber)?.intValue ?? 0
            delegate?.adLog(message: message, errorCode: errorCode)
        case .AD_BREAK_FETCH_ERROR:
            delegate?.adBreakFetchFailed(
                message: "Google DAI failed to fetch an ad break.",
                errorCode: IMAErrorCode.FAILED_TO_REQUEST_ADS.rawValue
            )
        case .TAPPED:
            delegate?.adTapped()
        default:
            break
        }
    }

    func handle(error: IMAAdError) {
        delegate?.adPlaybackFailed(
            message: error.message ?? "Google DAI ad playback failed.",
            errorCode: error.code.rawValue
        )
    }
}
