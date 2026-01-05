import Foundation

/// Represents a single analytics log entry
struct AnalyticsLog: Codable {
    let timestamp: Date
    let event: String
    let properties: [String: String]
}

/// Manager for privacy-first analytics tracking
final class AnalyticsManager {
    static let shared = AnalyticsManager()

    private init() {
        // Ensure analytics directory exists
        try? FileManager.default.createDirectory(
            at: logsURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    private let logsURL: URL = {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let bundleID = Bundle.main.bundleIdentifier ?? "com.hxd.ksapdismiss"
        return appSupport
            .appendingPathComponent(bundleID)
            .appendingPathComponent("analytics.log")
    }()

    /// Log an analytics event
    func log(_ entry: AnalyticsLog) {
        guard UserDefaults.standard.bool(forKey: "EnableAnalytics") else { return }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(entry) else { return }
        let line = String(data: data, encoding: .utf8)! + "\n"

        // Append to log file
        if let handle = try? FileHandle(forWritingTo: logsURL) {
            handle.seekToEndOfFile()
            handle.write(line.data(using: .utf8)!)
            handle.closeFile()
        } else {
            // Create new file
            try? line.write(to: logsURL, atomically: true, encoding: .utf8)
        }
    }

    /// Export all logs as a string
    func exportLogs() -> String? {
        try? String(contentsOf: logsURL)
    }

    /// Clear all analytics logs
    func clearLogs() {
        try? FileManager.default.removeItem(at: logsURL)
    }

    /// Get the size of the analytics log file
    func logSize() -> Int64 {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: logsURL.path) else {
            return 0
        }
        return attributes[.size] as? Int64 ?? 0
    }
}
