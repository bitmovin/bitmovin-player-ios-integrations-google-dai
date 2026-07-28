import Foundation
import GoogleInteractiveMediaAds
import UIKit

/// Owns the lifecycle and IMA objects for one active Google DAI stream session.
/// It hides delegate-based stream setup behind `async throws` and exposes only semantic collaborators to the module.
@MainActor
final class GoogleDaiStreamSessionController: NSObject {
    /// Identifies callbacks belonging to one IMA stream request so stale loader callbacks can be ignored.
    private final class LoadContext: NSObject {
        let identifier = UUID()
    }

    /// Describes invalid states encountered while establishing an IMA stream session.
    enum Error: Swift.Error {
        case loadAlreadyInProgress
        case missingAdDisplayContainer
        case missingStreamManager
    }

    private let imaAdsLoader = IMAAdsLoader()
    private let videoDisplayAdapter: GoogleDaiVideoDisplayAdapter

    private var adDisplayContainer: IMAAdDisplayContainer?
    private var streamManager: IMAStreamManager?
    private var loadContext: LoadContext?
    private var loadContinuation: CheckedContinuation<URL, Swift.Error>?

    var playbackEventReporter: any GoogleDaiPlaybackEventReporting {
        videoDisplayAdapter
    }

    init(
        playbackControlDelegate: any GoogleDaiPlaybackControlDelegate,
        playbackInfoDataSource: any GoogleDaiPlaybackInfoDataSource
    ) {
        videoDisplayAdapter = GoogleDaiVideoDisplayAdapter(
            playbackControlDelegate: playbackControlDelegate,
            playbackInfoDataSource: playbackInfoDataSource
        )

        super.init()

        videoDisplayAdapter.streamLoadHandler = { [weak self] streamUrl in
            self?.finishLoading(with: .success(streamUrl))
        }
        imaAdsLoader.delegate = self
    }

    /// Registers the UIKit presentation context IMA needs before a stream can be requested.
    func register(adContainer: UIView, viewController: UIViewController) {
        adDisplayContainer = IMAAdDisplayContainer(
            adContainer: adContainer,
            viewController: viewController
        )
    }

    func clearPresentationContext() {
        adDisplayContainer = nil
    }

    func load(source: GoogleDaiSource) async throws -> URL {
        guard loadContinuation == nil else {
            throw Error.loadAlreadyInProgress
        }

        guard let adDisplayContainer else {
            throw Error.missingAdDisplayContainer
        }

        destroyStreamManager()
        let loadContext = LoadContext()
        self.loadContext = loadContext

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                loadContinuation = continuation
                imaAdsLoader.requestStream(
                    with: streamRequest(
                        for: source,
                        loadContext: loadContext,
                        adDisplayContainer: adDisplayContainer
                    )
                )
            }
        } onCancel: { [weak self, identifier = loadContext.identifier] in
            Task { @MainActor in
                self?.cancelLoading(identifier: identifier)
            }
        }
    }

    func destroy() {
        finishLoading(with: .failure(CancellationError()))
        destroyStreamManager()
        adDisplayContainer = nil
    }

    private func streamRequest(
        for source: GoogleDaiSource,
        loadContext: LoadContext,
        adDisplayContainer: IMAAdDisplayContainer,
    ) -> IMAStreamRequest {
        switch source {
        case let .live(assetKey, apiKey, networkCode):
            let request = IMALiveStreamRequest(
                assetKey: assetKey,
                networkCode: networkCode,
                adDisplayContainer: adDisplayContainer,
                videoDisplay: videoDisplayAdapter,
                userContext: loadContext
            )
            request.apiKey = apiKey
            return request
        }
    }

    private func finishLoading(with result: Result<URL, Swift.Error>) {
        guard let loadContinuation else {
            return
        }

        self.loadContinuation = nil
        loadContext = nil
        loadContinuation.resume(with: result)
    }

    private func cancelLoading(identifier: UUID) {
        guard loadContext?.identifier == identifier else {
            return
        }
        destroy()
    }

    private func destroyStreamManager() {
        streamManager?.delegate = nil
        streamManager?.destroy()
        streamManager = nil
    }
}

extension GoogleDaiStreamSessionController: @preconcurrency IMAAdsLoaderDelegate {
    func adsLoader(_: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
        guard (adsLoadedData.userContext as AnyObject?) === loadContext else {
            return
        }
        guard let streamManager = adsLoadedData.streamManager else {
            finishLoading(with: .failure(Error.missingStreamManager))
            return
        }

        self.streamManager = streamManager
        streamManager.initialize(with: nil)
    }

    func adsLoader(_: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        guard (adErrorData.userContext as AnyObject?) === loadContext else {
            return
        }
        let adError = adErrorData.adError
        let error = NSError(
            domain: "GoogleInteractiveMediaAds",
            code: adError.code.rawValue,
            userInfo: [NSLocalizedDescriptionKey: adError.message ?? "Google DAI stream loading failed."]
        )
        finishLoading(with: .failure(error))
    }
}
