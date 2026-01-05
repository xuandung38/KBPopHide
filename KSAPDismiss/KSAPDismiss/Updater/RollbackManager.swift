import Foundation
import AppKit

/// Manager for tracking app launches and detecting crash loops for auto-rollback
final class RollbackManager {
    static let shared = RollbackManager()

    private let launchCountKey = "LaunchCountForVersion"
    private let lastVersionKey = "LastLaunchedVersion"
    private let stableThreshold = 3 // Considered stable after 3 successful launches

    private init() {}

    /// Track app launch and detect crash loops
    @MainActor
    func trackLaunch() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let lastVersion = UserDefaults.standard.string(forKey: lastVersionKey)

        if currentVersion != lastVersion {
            // First launch of this version
            UserDefaults.standard.set(currentVersion, forKey: lastVersionKey)
            UserDefaults.standard.set(1, forKey: launchCountKey)
            print("✅ First launch of version \(currentVersion)")
        } else {
            // Subsequent launch
            let currentCount = UserDefaults.standard.integer(forKey: launchCountKey)
            let newCount = currentCount + 1
            UserDefaults.standard.set(newCount, forKey: launchCountKey)

            if newCount >= stableThreshold {
                print("✅ Version \(currentVersion) is stable (launch #\(newCount))")
            } else {
                print("⏳ Version \(currentVersion) launch #\(newCount)/\(stableThreshold)")
            }
        }
    }

    /// Check if the current version appears to be crash looping
    @MainActor
    func checkForCrashLoop() -> Bool {
        // If we haven't reached stability threshold yet, not a crash loop
        // (Normal launches increment the count, so we'd be past threshold if stable)
        // If the app keeps crashing during startup, this count won't increment properly
        // We detect crash loop by checking if we're stuck at low launch counts

        // This is a simplified approach - Sparkle doesn't provide native rollback
        // In a production app, you'd track crash timestamps and frequency
        return false // Manual rollback only for now
    }

    /// Get current version info
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

    /// Get launch count for current version
    var launchCount: Int {
        UserDefaults.standard.integer(forKey: launchCountKey)
    }

    /// Check if current version is considered stable
    var isStable: Bool {
        launchCount >= stableThreshold
    }

    /// Show rollback dialog (manual fallback)
    @MainActor
    func showRollbackDialog() {
        let alert = NSAlert()
        alert.messageText = L("Update Issue Detected")
        alert.informativeText = L("If you're experiencing issues with version \(currentVersion), you can download a previous version from GitHub Releases.")
        alert.alertStyle = .warning
        alert.addButton(withTitle: L("Open GitHub Releases"))
        alert.addButton(withTitle: L("Cancel"))

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open GitHub Releases page
            if let url = URL(string: "https://github.com/xuandung38/ksap-dismiss/releases") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
