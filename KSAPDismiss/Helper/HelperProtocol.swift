import Foundation

/// XPC Protocol for privileged helper communication
/// Shared between helper and main app
@objc(HelperProtocol)
protocol HelperProtocol {

    /// Get helper version for compatibility check
    func getVersion(withReply reply: @escaping (String) -> Void)

    /// Add keyboard entries to plist
    /// - Parameters:
    ///   - entries: Array of dictionaries with "identifier" (String) and "type" (Int)
    ///   - reply: Success/error callback
    func addKeyboardEntries(
        _ entries: [[String: Any]],
        withReply reply: @escaping (Bool, String?) -> Void
    )

    /// Remove all keyboard entries (enable KSA)
    func removeAllKeyboardEntries(
        withReply reply: @escaping (Bool, String?) -> Void
    )

    /// Check if plist exists and has entries
    func getKeyboardStatus(
        withReply reply: @escaping (Bool, [String]?) -> Void
    )
}

/// Helper bundle identifier constant
let kHelperBundleID = "com.hxd.ksapdismiss.helper"

/// Helper version - update when protocol changes
let kHelperVersion = "1.0.0"
