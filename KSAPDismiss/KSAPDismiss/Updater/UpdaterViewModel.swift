import Foundation
import Sparkle

/// ViewModel for Sparkle updater integration
@MainActor
final class UpdaterViewModel: ObservableObject {

    private let updaterController: SPUStandardUpdaterController
    private let delegate = UpdaterDelegate()

    @Published var canCheckForUpdates = false
    @Published var automaticallyChecksForUpdates = true

    init() {
        // Initialize updater with delegate for beta channels and analytics
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: delegate,
            userDriverDelegate: nil
        )

        // Bind to updater state
        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)

        updaterController.updater.publisher(for: \.automaticallyChecksForUpdates)
            .assign(to: &$automaticallyChecksForUpdates)
    }

    /// Trigger manual update check
    func checkForUpdates() {
        updaterController.updater.checkForUpdates()
    }

    /// Toggle automatic update checks
    func setAutomaticChecks(_ enabled: Bool) {
        updaterController.updater.automaticallyChecksForUpdates = enabled
    }

    /// Get last update check date
    var lastUpdateCheckDate: Date? {
        updaterController.updater.lastUpdateCheckDate
    }
}
