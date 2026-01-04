import AppKit
import SwiftUI

/// Manages Settings window lifecycle manually to avoid SwiftUI Window Scene overhead.
/// Window created on-demand and released when closed.
@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?
    private var hostingController: NSHostingController<AnyView>?

    private init() {}

    func showSettings(
        keyboardManager: KeyboardManager,
        languageManager: LanguageManager,
        appSettings: AppSettings
    ) {
        // Reuse existing window if open
        if let window = window, window.isVisible {
            window.level = .floating
            centerWindowOnMainScreen(window)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create view with environment objects
        let settingsView = SettingsView()
            .environmentObject(keyboardManager)
            .environmentObject(languageManager)
            .environmentObject(appSettings)
            .environment(\.locale, languageManager.locale)

        // Create hosting controller
        let hosting = NSHostingController(rootView: AnyView(settingsView))
        hostingController = hosting

        // Create window
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        win.title = L("KSAP Dismiss Settings")
        win.contentViewController = hosting
        win.isReleasedWhenClosed = false
        win.minSize = NSSize(width: 600, height: 400)

        // Make window appear on top of all other windows (floating panel level)
        win.level = .floating

        // Center window on main screen (explicit calculation for multi-monitor support)
        centerWindowOnMainScreen(win)

        // Setup close handler to release memory
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: win,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.releaseWindow()
            }
        }

        window = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func releaseWindow() {
        hostingController = nil
        window = nil
    }

    /// Centers window on the main screen (where mouse cursor is or primary display)
    private func centerWindowOnMainScreen(_ window: NSWindow) {
        // Get the screen where the mouse cursor is, or fall back to main screen
        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        } ?? NSScreen.main ?? NSScreen.screens.first

        guard let screen = targetScreen else {
            window.center()
            return
        }

        // Calculate center position on the visible frame (excludes menu bar and dock)
        let visibleFrame = screen.visibleFrame
        let windowSize = window.frame.size

        let x = visibleFrame.origin.x + (visibleFrame.width - windowSize.width) / 2
        let y = visibleFrame.origin.y + (visibleFrame.height - windowSize.height) / 2

        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
