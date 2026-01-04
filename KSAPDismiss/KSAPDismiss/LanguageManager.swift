import SwiftUI

// MARK: - Supported Languages

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case vietnamese = "vi"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .english: return "English"
        case .vietnamese: return "Tiếng Việt"
        }
    }

    var icon: String {
        switch self {
        case .system: return "globe"
        case .english: return "flag"
        case .vietnamese: return "flag.fill"
        }
    }
}

// MARK: - Language Manager

@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @AppStorage("appLanguage") private var selectedLanguage: String = "system"
    @Published var locale: Locale = .current

    private init() {
        // Initialize locale from saved preference
        if selectedLanguage == "system" {
            locale = .current
        } else {
            locale = Locale(identifier: selectedLanguage)
        }
        LocalizationHelper.currentLocale = locale
    }

    // MARK: - Public API

    var currentLanguage: AppLanguage {
        AppLanguage(rawValue: selectedLanguage) ?? .system
    }

    func setLanguage(_ language: AppLanguage) {
        selectedLanguage = language.rawValue
        updateLocale()
    }

    // MARK: - Private

    private func updateLocale() {
        if selectedLanguage == "system" {
            locale = .current
        } else {
            locale = Locale(identifier: selectedLanguage)
        }
        // Update global locale for L() function
        LocalizationHelper.currentLocale = locale
        objectWillChange.send()
    }
}

// MARK: - Global Localization Helper

/// Thread-safe localization helper
enum LocalizationHelper {
    /// Current locale for localization (updated by LanguageManager)
    nonisolated(unsafe) static var currentLocale: Locale = .current

    /// Get localized string for key
    static func localized(_ key: String) -> String {
        let langCode = currentLocale.language.languageCode?.identifier ?? "en"
        let bundle = Bundle.main

        // Try to find the localized bundle for the specified language
        if let path = bundle.path(forResource: langCode, ofType: "lproj"),
           let localizedBundle = Bundle(path: path) {
            return localizedBundle.localizedString(forKey: key, value: key, table: "Localizable")
        }

        // Fallback to default bundle lookup
        return bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }
}

/// Convenience function for localized strings
/// Usage: L("Hello") or L("Settings...")
func L(_ key: String) -> String {
    LocalizationHelper.localized(key)
}

// MARK: - Language Picker View

struct LanguagePicker: View {
    @EnvironmentObject var languageManager: LanguageManager

    var body: some View {
        Picker(selection: Binding(
            get: { languageManager.currentLanguage },
            set: { languageManager.setLanguage($0) }
        )) {
            ForEach(AppLanguage.allCases) { language in
                Label(language.displayName, systemImage: language.icon)
                    .tag(language)
            }
        } label: {
            Label(L("Language"), systemImage: "globe")
        }
    }
}

// MARK: - Language Menu Items

struct LanguageMenuItems: View {
    @EnvironmentObject var languageManager: LanguageManager

    var body: some View {
        ForEach(AppLanguage.allCases) { language in
            Button {
                languageManager.setLanguage(language)
            } label: {
                HStack {
                    Text(language.displayName)
                    Spacer()
                    if languageManager.currentLanguage == language {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }
}
