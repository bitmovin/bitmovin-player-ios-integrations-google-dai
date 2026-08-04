import Foundation
import PlayerTesting

final class TestConfiguration: NSObject {
    override init() {
        PlayerTestingConfig.playerLicenseKeyForTesting = "YOUR-LICENSE-KEY"
        DebugConfig.logging.logger?.level = .verbose
    }
}
