import BitmovinPlayerCore
import Foundation

@MainActor
final class UnavailableGoogleDaiApi: GoogleDaiApi {
    static let shared = UnavailableGoogleDaiApi()

    let isEnabled = false

    private init() {}

    func load(
        source _: GoogleDaiSource,
        configureSourceConfig _: @escaping @MainActor (SourceConfig) -> Void
    ) {}

    func destroy() {}
}
