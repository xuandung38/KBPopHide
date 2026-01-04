import SwiftUI
import AppKit

@main
struct KSAPDismissApp: App {
    @StateObject private var keyboardManager = KeyboardManager()
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var appSettings = AppSettings.shared

    init() {
        // Check for existing instance and terminate if found
        Self.ensureSingleInstance()

        // Delay setup to after NSApp is initialized
        DispatchQueue.main.async {
            Self.applyDockVisibility()
            Self.setupAutomaticMode()
            Self.setupDockVisibilityObserver()
        }
    }

    /// Ensures only one instance of the app is running.
    /// If another instance is already running, activates it and terminates this one.
    private static func ensureSingleInstance() {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.hxd.ksapdismiss"
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)

        // Filter out current process
        let otherInstances = runningApps.filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }

        if !otherInstances.isEmpty {
            // Activate the existing instance
            otherInstances.first?.activate(options: .activateIgnoringOtherApps)
            // Terminate this instance
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private static func setupAutomaticMode() {
        // Get the shared keyboard manager instance
        let keyboardManager = KeyboardManager()

        // Wire up USB monitor callback
        USBMonitor.shared.onKeyboardConnected = { vendorID, productID in
            guard AppSettings.shared.automaticMode else { return }
            Task { @MainActor in
                await keyboardManager.autoConfigureKeyboard(
                    vendorID: vendorID,
                    productID: productID
                )
            }
        }

        // Start monitoring if automatic mode is enabled
        if AppSettings.shared.automaticMode {
            USBMonitor.shared.startMonitoring()
        }

        // React to setting changes
        AppSettings.shared.onAutomaticModeChanged = {
            if AppSettings.shared.automaticMode {
                USBMonitor.shared.startMonitoring()
            } else {
                USBMonitor.shared.stopMonitoring()
            }
        }
    }

    /// Sets up observer for dock visibility setting changes
    private static func setupDockVisibilityObserver() {
        AppSettings.shared.onShowInDockChanged = {
            applyDockVisibility()
        }
    }

    /// Applies the dock visibility preference
    private static func applyDockVisibility() {
        guard let app = NSApplication.shared as NSApplication? else { return }
        let policy: NSApplication.ActivationPolicy =
            AppSettings.shared.showInDock ? .regular : .accessory
        app.setActivationPolicy(policy)
    }

    var body: some Scene {
        // Menu Bar only - Settings window managed by SettingsWindowController
        MenuBarExtra {
            MenuBarView()
                .environmentObject(keyboardManager)
                .environmentObject(languageManager)
                .environmentObject(appSettings)
                .environment(\.locale, languageManager.locale)
        } label: {
            Label("KSAP Dismiss", systemImage: keyboardManager.isKSADisabled ? "keyboard.fill" : "keyboard")
        }
        .menuBarExtraStyle(.window)
    }
}
