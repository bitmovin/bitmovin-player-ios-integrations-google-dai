import BitmovinPlayerCore
import Foundation

@MainActor
final class DefaultGoogleDaiPlayerModule: _PlayerModule {
    private(set) weak var player: Player?

    init(player: Player) {
        self.player = player
    }
}

extension DefaultGoogleDaiPlayerModule: GoogleDaiApi {
    func load(source _: GoogleDaiSource) {}
    func destroy() {}
}
