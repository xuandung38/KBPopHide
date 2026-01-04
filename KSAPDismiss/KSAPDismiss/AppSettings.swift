import SwiftUI
import ServiceManagement

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @AppStorage("automaticMode") var automaticMode: Bool = false {
        didSet { onAutomaticModeChanged() }
    }

    @AppStorage("showInDock") var showInDock: Bool = false {
        didSet { onShowInDockChanged() }
    }

    @AppStorage("startAtLogin") private var _startAtLogin: Bool = false

    var startAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                _startAtLogin = newValue
            } catch {
                print("Failed to update login item: \(error)")
            }
        }
    }

    var onAutomaticModeChanged: () -> Void = {}
    var onShowInDockChanged: () -> Void = {}

    private init() {
        // Sync stored value with actual system state on init
        _startAtLogin = SMAppService.mainApp.status == .enabled
    }
}
