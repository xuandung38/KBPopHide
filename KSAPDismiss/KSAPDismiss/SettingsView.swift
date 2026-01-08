import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var keyboardManager: KeyboardManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var updaterViewModel: UpdaterViewModel
    @State private var selectedTab: SettingsTab = .general

    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case keyboards = "Keyboards"
        case updates = "Updates"
        case privacy = "Privacy"
        case about = "About"

        var localizedName: String {
            L(rawValue)
        }

        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .keyboards: return "keyboard"
            case .updates: return "arrow.down.circle"
            case .privacy: return "hand.raised"
            case .about: return "info.circle"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SettingsTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.localizedName, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 150)
        } detail: {
            // Content
            switch selectedTab {
            case .general:
                GeneralSettingsView()
                    .environmentObject(keyboardManager)
                    .environmentObject(languageManager)
                    .environmentObject(appSettings)
            case .keyboards:
                KeyboardListView()
                    .environmentObject(keyboardManager)
            case .updates:
                UpdatesSettingsView()
                    .environmentObject(updaterViewModel)
            case .privacy:
                PrivacySettingsView()
            case .about:
                AboutView()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .navigationTitle(Text(L("KSAP Dismiss Settings")))
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @EnvironmentObject var keyboardManager: KeyboardManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var appSettings: AppSettings
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Status Card
                StatusCard(keyboardManager: keyboardManager)

                Divider()

                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("Quick Actions"))
                        .font(.headline)

                    HStack(spacing: 16) {
                        ActionButton(
                            title: L("Disable Popup"),
                            subtitle: L("Block KSA for all keyboards"),
                            icon: "keyboard.badge.ellipsis",
                            isActive: keyboardManager.isKSADisabled,
                            isProcessing: isProcessing
                        ) {
                            await disableKSA()
                        }

                        ActionButton(
                            title: L("Enable Popup"),
                            subtitle: L("Restore default behavior"),
                            icon: "keyboard",
                            isActive: !keyboardManager.isKSADisabled,
                            isProcessing: isProcessing
                        ) {
                            await enableKSA()
                        }
                    }
                }

                Divider()

                // Automatic Mode Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("Automatic Mode"))
                        .font(.headline)

                    Toggle(isOn: $appSettings.automaticMode) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("Auto-suppress new keyboards"))
                            Text(L("Automatically configure keyboards when connected"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                }

                Divider()

                // Startup Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("Startup"))
                        .font(.headline)

                    Toggle(isOn: Binding(
                        get: { appSettings.startAtLogin },
                        set: { appSettings.startAtLogin = $0 }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("Start at Login"))
                            Text(L("Launch KSAP Dismiss when you log in"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                }

                Divider()

                // Appearance Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("Appearance"))
                        .font(.headline)

                    Toggle(isOn: $appSettings.showInDock) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("Show in Dock"))
                            Text(L("Display app icon in the Dock"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                }

                Divider()

                // Language Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("Language"))
                        .font(.headline)

                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.secondary)

                        Picker("", selection: Binding(
                            get: { languageManager.currentLanguage },
                            set: { languageManager.setLanguage($0) }
                        )) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 180)
                    }
                }

                Divider()

                // Info Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(L("How It Works"))
                        .font(.headline)

                    Text(L("KSAP Dismiss prevents the Keyboard Setup Assistant popup by pre-configuring keyboard types in macOS. When disabled, macOS thinks it already knows your keyboard layout."))
                        .font(.callout)
                        .foregroundColor(.secondary)

                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text(L("Admin password required for changes"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }

                Spacer()
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(Text(L("Error")), isPresented: $showingError) {
            Button(L("OK"), role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func disableKSA() async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            try await keyboardManager.disableKSA()
        } catch let error as TouchIDError where !error.shouldShowAlert {
            // User canceled - silently ignore
        } catch let error as HelperInstallerError {
            if case .notEnabled = error { return }
            errorMessage = error.errorDescription ?? "Registration failed"
            showingError = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func enableKSA() async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            try await keyboardManager.enableKSA()
        } catch let error as TouchIDError where !error.shouldShowAlert {
            // User canceled - silently ignore
        } catch let error as HelperInstallerError {
            if case .notEnabled = error { return }
            errorMessage = error.errorDescription ?? "Registration failed"
            showingError = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Status Card

struct StatusCard: View {
    @ObservedObject var keyboardManager: KeyboardManager

    var body: some View {
        HStack(spacing: 16) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: statusIcon)
                    .font(.system(size: 24))
                    .foregroundColor(statusColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(L("Current Status"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(statusTitle)
                    .font(.title2)
                    .fontWeight(.semibold)

                if let keyboards = keyboardManager.configuredKeyboards, !keyboards.isEmpty {
                    Text(keyboards.count == 1
                        ? L("1 keyboard configured")
                        : String(format: L("%lld keyboards configured"), keyboards.count))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                keyboardManager.refreshStatus()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
            }
            .buttonStyle(.bordered)
            .help(Text(L("Refresh Status")))
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    private var statusColor: Color {
        switch keyboardManager.status {
        case .disabled: return .green
        case .enabled: return .gray
        case .error: return .red
        case .unknown: return .orange
        }
    }

    private var statusIcon: String {
        switch keyboardManager.status {
        case .disabled: return "checkmark.shield.fill"
        case .enabled: return "keyboard"
        case .error: return "exclamationmark.triangle.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    private var statusTitle: String {
        switch keyboardManager.status {
        case .disabled: return L("Popup Disabled")
        case .enabled: return L("Popup Enabled")
        case .error: return L("Error")
        case .unknown: return L("Unknown")
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isActive: Bool
    let isProcessing: Bool
    let action: () async -> Void

    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20))

                    Spacer()

                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }

                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isActive ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isProcessing || isActive)
        .opacity(isProcessing ? 0.6 : 1.0)
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App Icon
            Image(systemName: "keyboard.badge.ellipsis")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            VStack(spacing: 8) {
                Text("KSAP Dismiss")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(L("Version 1.0.0"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(L("A lightweight macOS utility to disable the Keyboard Setup Assistant popup that appears when connecting third-party keyboards."))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Divider()
                .frame(maxWidth: 300)

            VStack(spacing: 12) {
                InfoRow(label: L("Author"), value: "Xuan Dung, Ho")
                InfoRow(label: L("Contact"), value: "me@hxd.vn")
                InfoRow(label: L("Platform"), value: "macOS 13+")
                InfoRow(label: L("Architecture"), value: "Native SwiftUI")
                InfoRow(label: L("License"), value: "MIT")
            }

            Spacer()

            Text(L("Made with Swift & SwiftUI"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .frame(maxWidth: 250)
    }
}

// MARK: - Updates Settings View

struct UpdatesSettingsView: View {
    @EnvironmentObject var updaterViewModel: UpdaterViewModel
    @AppStorage("PreferBetaUpdates") private var preferBeta = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Update Check Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("Software Update"))
                        .font(.headline)

                    HStack {
                        Button(L("Check for Updates...")) {
                            updaterViewModel.checkForUpdates()
                        }
                        .disabled(!updaterViewModel.canCheckForUpdates)

                        Spacer()

                        if let lastCheck = updaterViewModel.lastUpdateCheckDate {
                            Text(L("Last checked: ") + lastCheck.formatted())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Divider()

                // Update Channel Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("Update Channel"))
                        .font(.headline)

                    Picker("", selection: $preferBeta) {
                        Text(L("Stable releases only")).tag(false)
                        Text(L("Include beta versions")).tag(true)
                    }
                    .pickerStyle(.radioGroup)

                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text(L("Beta versions include the latest features but may be less stable"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }

                Divider()

                // Automatic Updates Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("Automatic Updates"))
                        .font(.headline)

                    Toggle(isOn: Binding(
                        get: { updaterViewModel.automaticallyChecksForUpdates },
                        set: { updaterViewModel.setAutomaticChecks($0) }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("Check for updates automatically"))
                            Text(L("Periodically check for new versions in the background"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                }

                Spacer()
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Privacy Settings View

struct PrivacySettingsView: View {
    @AppStorage("EnableAnalytics") private var enableAnalytics = false
    @State private var showingClearConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Analytics Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("Analytics"))
                        .font(.headline)

                    Toggle(isOn: $enableAnalytics) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("Enable analytics"))
                            Text(L("Help improve KSAP Dismiss by sending anonymous usage data"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.switch)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L("What we collect:"))
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(L("Update check events (version, channel, success/failure)"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text(L("NO personal information, NO device identifiers, NO keyboard data"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 8)
                }

                Divider()

                // Data Management Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("Data Management"))
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L("Analytics log size"))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatBytes(AnalyticsManager.shared.logSize()))
                                .fontWeight(.medium)
                        }

                        Button(L("Clear Analytics Data")) {
                            showingClearConfirmation = true
                        }
                        .confirmationDialog(
                            L("Are you sure you want to clear all analytics data?"),
                            isPresented: $showingClearConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button(L("Clear Data"), role: .destructive) {
                                AnalyticsManager.shared.clearLogs()
                            }
                            Button(L("Cancel"), role: .cancel) { }
                        }
                    }
                }

                Divider()

                // Privacy Policy Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(L("Privacy Commitment"))
                        .font(.headline)

                    Text(L("All analytics data is stored locally on your device. We never send data to third-party services or remote servers. You have full control over your data and can disable analytics or clear all data at any time."))
                        .font(.callout)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
