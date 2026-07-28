import BitmovinPlayerCore
import Foundation

enum Logger {
    static func log(_ message: String) {
        log(message, level: .info)
    }

    static func warn(_ message: String) {
        log(message, level: .warning)
    }

    static func error(_ message: String) {
        log(message, level: .error)
    }

    private static func log(_ message: String, level: LogLevel) {
        DebugConfig.logging.logger?.log(
            LogEntry(
                message: message,
                level: level,
                sender: "BitmovinGoogleDAIPlayer"
            )
        )
    }
}
