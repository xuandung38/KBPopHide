import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var keyboardManager: KeyboardManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var appSettings: AppSettings
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with status indicator
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text("KSAP Dismiss")
                    .font(.headline)
                Spacer()
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            // Quick Toggle Section
            VStack(alignment: .leading, spacing: 2) {
                Button(action: disableKSA) {
                    HStack {
                        Image(systemName: keyboardManager.isKSADisabled ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(keyboardManager.isKSADisabled ? .green : .secondary)
                        Text(L("Disable Popup"))
                        Spacer()
                        if keyboardManager.isKSADisabled {
                            Text(L("Active"))
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

                Button(action: enableKSA) {
                    HStack {
                        Image(systemName: keyboardManager.isKSADisabled ? "circle" : "checkmark.circle.fill")
                            .foregroundColor(keyboardManager.isKSADisabled ? .secondary : .green)
                        Text(L("Enable Popup"))
                        Spacer()
                        if !keyboardManager.isKSADisabled {
                            Text(L("Active"))
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }

            // Keyboard count if any
            if let keyboards = keyboardManager.configuredKeyboards, !keyboards.isEmpty {
                HStack {
                    Image(systemName: "keyboard")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(keyboards.count == 1
                        ? L("1 keyboard configured")
                        : String(format: L("%lld keyboards configured"), keyboards.count))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }

            Divider()

            // Language Submenu
            Menu {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        languageManager.setLanguage(language)
                    } label: {
                        HStack {
                            Text(language.displayName)
                            if languageManager.currentLanguage == language {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "globe")
                    Text(L("Language"))
                    Spacer()
                    Text(languageManager.currentLanguage.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .menuStyle(.borderlessButton)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Divider()

            // Settings & Actions
            Button {
                SettingsWindowController.shared.showSettings(
                    keyboardManager: keyboardManager,
                    languageManager: languageManager,
                    appSettings: appSettings
                )
            } label: {
                HStack {
                    Image(systemName: "gearshape")
                    Text(L("Settings..."))
                    Spacer()
                    Text("⌘,")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .keyboardShortcut(",", modifiers: .command)

            Button {
                keyboardManager.refreshStatus()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text(L("Refresh Status"))
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Divider()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                    Text(L("Quit KSAP Dismiss"))
                    Spacer()
                    Text("⌘Q")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .keyboardShortcut("q", modifiers: .command)
        }
        .frame(width: 260)
        .alert(Text(L("Error")), isPresented: $showingError) {
            Button(L("OK"), role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private var statusColor: Color {
        switch keyboardManager.status {
        case .disabled:
            return .green
        case .enabled:
            return .gray
        case .error:
            return .red
        case .unknown:
            return .orange
        }
    }

    private var statusText: String {
        switch keyboardManager.status {
        case .disabled:
            return L("Popup Disabled")
        case .enabled:
            return L("Popup Enabled")
        case .error:
            return L("Error")
        case .unknown:
            return L("Unknown")
        }
    }

    private func enableKSA() {
        Task {
            do {
                try await keyboardManager.enableKSA()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }

    private func disableKSA() {
        Task {
            do {
                try await keyboardManager.disableKSA()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }

}
