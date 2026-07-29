/// Receives semantic Google DAI ad lifecycle events from the IMA adapter.
/// Separate methods keep event meaning and payload requirements explicit at the module boundary.
@MainActor
protocol GoogleDaiAdEventDelegate: AnyObject {
    func adStarted(_ ad: GoogleDaiSsaiAd)
    func adClicked()
    func adTapped()
    func adCompleted()
    func adSkipped()
    func adPeriodEnded()
    func adBreakEnded()
    func allAdsCompleted()
    func adReachedFirstQuartile()
    func adReachedMidpoint()
    func adReachedThirdQuartile()
    func adLog(message: String, errorCode: Int)
    func adBreakFetchFailed(message: String, errorCode: Int)
    func adPlaybackFailed(message: String, errorCode: Int)
}
