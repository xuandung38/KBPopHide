import Foundation
import Sparkle

/// Delegate for Sparkle updater to handle beta channels and analytics
@MainActor
final class UpdaterDelegate: NSObject, @preconcurrency SPUUpdaterDelegate {

    // MARK: - Beta Channel Filtering

    /// Determine which update channels the user is subscribed to
    nonisolated func allowedChannels(for updater: SPUUpdater) -> Set<String> {
        let preferBeta = UserDefaults.standard.bool(forKey: "PreferBetaUpdates")
        return preferBeta ? ["beta", "default"] : ["default"]
    }

    // MARK: - Update Event Tracking (Analytics)

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        guard UserDefaults.standard.bool(forKey: "EnableAnalytics") else { return }

        let isBeta = item.channel == "beta"
        if isBeta {
            print("🧪 Beta update found: \(item.versionString)")
        } else {
            print("✅ Stable update found: \(item.versionString)")
        }

        logEvent("update_found", properties: [
            "current_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "available_version": item.versionString,
            "channel": item.channel ?? "default",
            "is_delta": !(item.deltaUpdates?.isEmpty ?? true) ? "true" : "false"
        ])
    }

    func updater(_ updater: SPUUpdater, didDownloadUpdate item: SUAppcastItem) {
        guard UserDefaults.standard.bool(forKey: "EnableAnalytics") else { return }

        logEvent("update_downloaded", properties: [
            "version": item.versionString
        ])
    }

    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        guard UserDefaults.standard.bool(forKey: "EnableAnalytics") else { return }

        logEvent("update_failed", properties: [
            "error": error.localizedDescription
        ])
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        guard UserDefaults.standard.bool(forKey: "EnableAnalytics") else { return }

        logEvent("no_update_available", properties: [
            "current_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ])
    }

    // MARK: - Analytics Backend

    private func logEvent(_ name: String, properties: [String: String]) {
        let log = AnalyticsLog(
            timestamp: Date(),
            event: name,
            properties: properties
        )

        AnalyticsManager.shared.log(log)
    }
}
