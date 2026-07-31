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
    enum Error: Swift.Error, LocalizedError {
        case missingAdDisplayContainer
        case missingStreamManager

        var errorDescription: String? {
            switch self {
            case .missingAdDisplayContainer:
                "Google DAI cannot load a stream without an advertising presentation context."
            case .missingStreamManager:
                "Google IMA did not provide a stream manager for the Google DAI stream request."
            }
        }
    }

    private let imaAdsLoader = IMAAdsLoader()
    private let videoDisplayAdapter: GoogleDaiVideoDisplayAdapter
    private let adEventAdapter: GoogleDaiAdEventAdapter

    private var adDisplayContainer: IMAAdDisplayContainer?
    private var streamManager: IMAStreamManager?
    private var loadContext: LoadContext?
    private var loadContinuation: CheckedContinuation<URL, Swift.Error>?

    var playbackEventReporter: any GoogleDaiPlaybackEventReporting {
        videoDisplayAdapter
    }

    init(
        playbackControlDelegate: any GoogleDaiPlaybackControlDelegate,
        playbackInfoDataSource: any GoogleDaiPlaybackInfoDataSource,
        adEventDelegate: any GoogleDaiAdEventDelegate
    ) {
        videoDisplayAdapter = GoogleDaiVideoDisplayAdapter(
            playbackControlDelegate: playbackControlDelegate,
            playbackInfoDataSource: playbackInfoDataSource
        )
        adEventAdapter = GoogleDaiAdEventAdapter(delegate: adEventDelegate)

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
        cancelLoading()

        guard let adDisplayContainer else {
            throw Error.missingAdDisplayContainer
        }

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

    func cancelLoading() {
        finishLoading(with: .failure(CancellationError()))
        destroyStreamManager()
    }

    func destroy() {
        cancelLoading()
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

    private func finishLoading(with adError: IMAAdError) {
        let error = NSError(
            domain: "GoogleInteractiveMediaAds",
            code: adError.code.rawValue,
            userInfo: [NSLocalizedDescriptionKey: adError.message ?? "Google DAI stream loading failed."]
        )
        finishLoading(with: .failure(error))
    }

    private func cancelLoading(identifier: UUID) {
        guard loadContext?.identifier == identifier else {
            return
        }
        cancelLoading()
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
        streamManager.delegate = self
        streamManager.initialize(with: nil)
    }

    func adsLoader(_: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        guard (adErrorData.userContext as AnyObject?) === loadContext else {
            return
        }
        finishLoading(with: adErrorData.adError)
    }
}

extension GoogleDaiStreamSessionController: @preconcurrency IMAStreamManagerDelegate {
    func streamManager(_ streamManager: IMAStreamManager, didReceive event: IMAAdEvent) {
        guard streamManager === self.streamManager else {
            return
        }
        adEventAdapter.handle(event: event)
    }

    func streamManager(_ streamManager: IMAStreamManager, didReceive adError: IMAAdError) {
        guard streamManager === self.streamManager else {
            return
        }

        if loadContinuation != nil {
            finishLoading(with: adError)
            destroyStreamManager()
        } else {
            adEventAdapter.handle(error: adError)
        }
    }
}
