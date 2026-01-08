import Foundation
import ServiceManagement
import AppKit
import os.log

/// Handles privileged helper registration via SMAppService (macOS 13.0+)
@MainActor
final class HelperInstaller: ObservableObject {

    static let shared = HelperInstaller()

    @Published private(set) var isRegistered = false
    @Published private(set) var requiresApproval = false
    @Published private(set) var isRegistering = false

    private let helperBundleID = kHelperBundleID
    private let daemonPlistName = "com.hxd.ksapdismiss.helper.plist"
    private let logger = Logger(subsystem: "com.hxd.ksapdismiss", category: "HelperInstaller")

    // SMAppService instance
    private lazy var service: SMAppService = {
        SMAppService.daemon(plistName: daemonPlistName)
    }()

    private init() {
        checkRegistrationStatus()
    }

    // MARK: - Registration Status

    /// Check if helper is registered and approved
    func checkRegistrationStatus() {
        let status = service.status

        switch status {
        case .notRegistered:
            isRegistered = false
            requiresApproval = false
            logger.info("Helper not registered")

        case .enabled:
            isRegistered = true
            requiresApproval = false
            logger.info("Helper registered and enabled")

        case .requiresApproval:
            isRegistered = true
            requiresApproval = true
            logger.info("Helper registered but requires user approval")

        case .notFound:
            isRegistered = false
            requiresApproval = false
            logger.error("Helper daemon plist not found in bundle")

        @unknown default:
            isRegistered = false
            requiresApproval = false
            logger.warning("Unknown helper status: \(status.rawValue)")
        }
    }

    /// Check if helper is ready to use
    var isEnabled: Bool {
        service.status == .enabled
    }

    /// Check if registration is needed
    var needsRegistration: Bool {
        service.status == .notRegistered
    }

    // MARK: - Registration

    /// Register the helper (first-time setup)
    func register() async throws {
        guard !isRegistering else {
            throw HelperInstallerError.alreadyRegistering
        }

        isRegistering = true
        defer { isRegistering = false }

        logger.info("Registering helper with SMAppService...")

        do {
            try service.register()
            logger.info("Helper registered successfully")
            checkRegistrationStatus()

            // Show approval UI if needed
            if requiresApproval {
                showApprovalRequiredDialog()
            }
        } catch {
            logger.error("Helper registration failed: \(error.localizedDescription)")
            throw HelperInstallerError.registrationFailed(error.localizedDescription)
        }
    }

    /// Unregister the helper
    func unregister() async throws {
        logger.info("Unregistering helper...")

        do {
            try await service.unregister()
            logger.info("Helper unregistered successfully")
            checkRegistrationStatus()
        } catch {
            logger.error("Helper unregistration failed: \(error.localizedDescription)")
            throw HelperInstallerError.unregistrationFailed(error.localizedDescription)
        }
    }

    // MARK: - Convenience

    /// Register if needed, return true if registration occurred
    func registerIfNeeded() async throws -> Bool {
        if isEnabled {
            return false
        }

        if needsRegistration {
            try await register()
            return true
        }

        if requiresApproval {
            showApprovalRequiredDialog()
            return false
        }

        return false
    }

    // MARK: - User Guidance

    /// Show dialog guiding user to approve helper in System Settings
    private func showApprovalRequiredDialog() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Background Service Required", comment: "")
        alert.informativeText = NSLocalizedString(
            "KSAP Dismiss needs permission to run a background service for managing keyboard settings.\n\n" +
            "Please enable it in System Settings:\n" +
            "General → Login Items → KSAP Dismiss → Allow in the Background",
            comment: ""
        )
        alert.addButton(withTitle: NSLocalizedString("Open System Settings", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Remind Me Later", comment: ""))
        alert.alertStyle = .informational

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openSystemSettingsLoginItems()
        }
    }

    /// Open System Settings to Login Items page
    private func openSystemSettingsLoginItems() {
        // macOS 13.0+ System Settings URL
        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
            NSWorkspace.shared.open(url)
        } else {
            // Fallback: Open Login Items preference pane
            let url = URL(fileURLWithPath: "/System/Library/PreferencePanes/LoginItems.prefPane")
            NSWorkspace.shared.open(url)
        }
    }

    /// Show error alert
    func showErrorAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Error", comment: "")
        alert.informativeText = message
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        alert.alertStyle = .critical
        alert.runModal()
    }
}

// MARK: - Errors

enum HelperInstallerError: LocalizedError {
    case alreadyRegistering
    case registrationFailed(String)
    case unregistrationFailed(String)
    case notEnabled

    var errorDescription: String? {
        switch self {
        case .alreadyRegistering:
            return "Registration already in progress"
        case .registrationFailed(let msg):
            return "Helper registration failed: \(msg)"
        case .unregistrationFailed(let msg):
            return "Helper unregistration failed: \(msg)"
        case .notEnabled:
            return "Helper is not enabled. Please approve in System Settings."
        }
    }
}
