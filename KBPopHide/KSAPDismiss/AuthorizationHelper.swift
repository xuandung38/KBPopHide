import Foundation
import Security

// MARK: - Authorization Errors

enum AuthError: Error, LocalizedError {
    case createFailed
    case rightSetFailed(OSStatus)
    case authorizationDenied
    case userCanceled  // User clicked Cancel - not a real error
    case executionFailed(String)
    case invalidCommand

    var errorDescription: String? {
        switch self {
        case .createFailed:
            return "Failed to create authorization reference"
        case .rightSetFailed(let status):
            return "Failed to set authorization right (status: \(status))"
        case .authorizationDenied:
            return "Authorization was denied by user"
        case .userCanceled:
            return nil  // Silent - not shown to user
        case .executionFailed(let message):
            return "Command execution failed: \(message)"
        case .invalidCommand:
            return "Invalid command path"
        }
    }

    /// Returns true if this error should be shown to user
    var shouldShowAlert: Bool {
        switch self {
        case .userCanceled:
            return false
        default:
            return true
        }
    }
}

// MARK: - Authorization Helper

/// Manages macOS Authorization Services for privileged operations.
/// Uses custom authorization right with long timeout to minimize password prompts.
final class AuthorizationHelper: @unchecked Sendable {
    static let shared = AuthorizationHelper()
    static let rightName = "com.hxd.KSAPDismiss.admin"

    private var authRef: AuthorizationRef?
    private let lock = NSLock()

    private init() {}

    // MARK: - Public API

    /// Obtains authorization, prompting user if needed.
    /// Credentials are cached for the session (until logout/reboot).
    func authorize() throws -> AuthorizationRef {
        lock.lock()
        defer { lock.unlock() }

        // Return cached auth if still valid
        if let existing = authRef {
            return existing
        }

        // Create new authorization reference
        var ref: AuthorizationRef?
        var status = AuthorizationCreate(nil, nil, [], &ref)

        guard status == errAuthorizationSuccess, let newRef = ref else {
            throw AuthError.createFailed
        }

        // Setup custom right with long timeout (first time only)
        try setupCustomRight(authRef: newRef)

        // Request authorization for our custom right
        let rightNameCString = Self.rightName.withCString { strdup($0) }!
        defer { free(rightNameCString) }

        var item = AuthorizationItem(
            name: rightNameCString,
            valueLength: 0,
            value: nil,
            flags: 0
        )

        status = withUnsafeMutablePointer(to: &item) { itemPtr in
            var rights = AuthorizationRights(count: 1, items: itemPtr)
            return AuthorizationCopyRights(
                newRef,
                &rights,
                nil,
                [.interactionAllowed, .extendRights, .preAuthorize],
                nil
            )
        }

        guard status == errAuthorizationSuccess else {
            AuthorizationFree(newRef, [])
            throw AuthError.authorizationDenied
        }

        authRef = newRef
        return newRef
    }

    /// Executes a command with elevated privileges.
    /// Uses cached authorization if available.
    func executePrivileged(command: String, args: [String]) throws {
        _ = try authorize()

        // Use Process with sudo-like execution via osascript
        // This is more reliable than deprecated AuthorizationExecuteWithPrivileges
        let fullCommand = ([command] + args)
            .map { arg in
                // Escape single quotes for shell
                "'\(arg.replacingOccurrences(of: "'", with: "'\\''"))'"
            }
            .joined(separator: " ")

        let script = """
        do shell script "\(fullCommand)" with administrator privileges
        """

        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else {
            throw AuthError.invalidCommand
        }

        appleScript.executeAndReturnError(&error)

        if let error = error {
            let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
            // Detect user cancellation - not a real error
            if message.lowercased().contains("cancel") {
                throw AuthError.userCanceled
            }
            throw AuthError.executionFailed(message)
        }
    }

    /// Executes a batch shell command with single password prompt.
    /// Use this for multiple chained commands (e.g., "cmd1 && cmd2 && cmd3").
    func executeBatchShellCommand(_ shellCommand: String) throws {
        _ = try authorize()

        // Escape for AppleScript string
        let escapedCommand = shellCommand
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        do shell script "\(escapedCommand)" with administrator privileges
        """

        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else {
            throw AuthError.invalidCommand
        }

        appleScript.executeAndReturnError(&error)

        if let error = error {
            let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
            // Detect user cancellation - not a real error
            if message.lowercased().contains("cancel") {
                throw AuthError.userCanceled
            }
            throw AuthError.executionFailed(message)
        }
    }

    /// Invalidates cached authorization.
    /// Call this when app terminates or user logs out.
    func invalidate() {
        lock.lock()
        defer { lock.unlock() }

        if let ref = authRef {
            AuthorizationFree(ref, [.destroyRights])
            authRef = nil
        }
    }

    // MARK: - Private

    /// Creates custom authorization right with long timeout.
    /// Right is stored in /var/db/auth.db and persists across app launches.
    private func setupCustomRight(authRef: AuthorizationRef) throws {
        // Check if right already exists
        var existingRight: CFDictionary?
        let checkStatus = AuthorizationRightGet(Self.rightName, &existingRight)

        if checkStatus == errAuthorizationSuccess {
            // Right already exists, no need to recreate
            return
        }

        // Define custom right with session-long timeout
        let rightDefinition: [String: Any] = [
            "class": "user",
            "group": "admin",
            "timeout": 2147483647,  // Max int32 (~68 years, effectively session)
            "shared": true,
            "authenticate-user": true,
            "allow-root": true,
            "comment": "KSAP Dismiss keyboard settings modification"
        ]

        let status = AuthorizationRightSet(
            authRef,
            Self.rightName,
            rightDefinition as CFDictionary,
            "KSAP Dismiss needs admin access to modify keyboard settings." as CFString,
            nil,
            nil
        )

        // errAuthorizationDenied (-60005) means we need admin to set the right
        // In that case, we'll fall back to per-operation auth
        if status != errAuthorizationSuccess && status != errAuthorizationDenied {
            throw AuthError.rightSetFailed(status)
        }
    }
}
