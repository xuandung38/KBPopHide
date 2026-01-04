import Foundation

/// Manages keyboard type plist modifications
/// Runs in helper context with root privileges
final class KeyboardPlistManager {

    private let plistPath = "/Library/Preferences/com.apple.keyboardtype.plist"
    private let fileManager = FileManager.default

    /// Add keyboard entries to plist
    func addKeyboardEntries(_ entries: [(identifier: String, type: Int)]) throws {
        var plist = loadPlist() ?? [:]
        var keyboardTypes = plist["keyboardtype"] as? [String: Int] ?? [:]

        for (identifier, type) in entries {
            keyboardTypes[identifier] = type
        }

        plist["keyboardtype"] = keyboardTypes
        try savePlist(plist)
    }

    /// Remove all keyboard entries
    func removeAllEntries() throws {
        if fileManager.fileExists(atPath: plistPath) {
            try fileManager.removeItem(atPath: plistPath)
        }
    }

    /// Get current status
    func getStatus() -> (hasEntries: Bool, keyboards: [String]?) {
        guard let plist = loadPlist(),
              let keyboardTypes = plist["keyboardtype"] as? [String: Int],
              !keyboardTypes.isEmpty else {
            return (false, nil)
        }
        return (true, Array(keyboardTypes.keys))
    }

    // MARK: - Private

    private func loadPlist() -> [String: Any]? {
        guard let data = fileManager.contents(atPath: plistPath) else {
            return nil
        }
        return try? PropertyListSerialization.propertyList(
            from: data, format: nil
        ) as? [String: Any]
    }

    private func savePlist(_ plist: [String: Any]) throws {
        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        try data.write(to: URL(fileURLWithPath: plistPath))

        // Set proper permissions (readable by all, writable by root)
        try fileManager.setAttributes(
            [.posixPermissions: 0o644],
            ofItemAtPath: plistPath
        )
    }
}
