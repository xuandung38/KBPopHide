import Foundation

/// Privileged Helper Tool entry point
/// Runs as LaunchDaemon (root) and listens for XPC connections
class HelperTool: NSObject, NSXPCListenerDelegate, HelperProtocol {

    private let listener: NSXPCListener
    private let plistManager = KeyboardPlistManager()

    override init() {
        // Create XPC listener with Mach service name
        listener = NSXPCListener(machServiceName: kHelperBundleID)
        super.init()
        listener.delegate = self
    }

    func run() {
        listener.resume()
        RunLoop.current.run()
    }

    // MARK: - NSXPCListenerDelegate

    func listener(
        _ listener: NSXPCListener,
        shouldAcceptNewConnection connection: NSXPCConnection
    ) -> Bool {
        // Verify caller is our main app (by code signing requirement)
        guard verifyCallerCodeSignature(connection) else {
            return false
        }

        connection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        connection.exportedObject = self
        connection.resume()
        return true
    }

    private func verifyCallerCodeSignature(_ connection: NSXPCConnection) -> Bool {
        // Get caller's audit token and verify code signature
        // In production, check for specific team ID or app identifier
        // For now, accept all connections (will be secured in Phase 4)
        // TODO: Implement proper code signature verification
        return true
    }

    // MARK: - HelperProtocol

    func getVersion(withReply reply: @escaping (String) -> Void) {
        reply(kHelperVersion)
    }

    func addKeyboardEntries(
        _ entries: [[String: Any]],
        withReply reply: @escaping (Bool, String?) -> Void
    ) {
        do {
            let parsed = try entries.map { entry -> (String, Int) in
                guard let id = entry["identifier"] as? String,
                      let type = entry["type"] as? Int else {
                    throw HelperError.invalidEntry
                }
                return (id, type)
            }
            try plistManager.addKeyboardEntries(parsed)
            reply(true, nil)
        } catch {
            reply(false, error.localizedDescription)
        }
    }

    func removeAllKeyboardEntries(
        withReply reply: @escaping (Bool, String?) -> Void
    ) {
        do {
            try plistManager.removeAllEntries()
            reply(true, nil)
        } catch {
            reply(false, error.localizedDescription)
        }
    }

    func getKeyboardStatus(
        withReply reply: @escaping (Bool, [String]?) -> Void
    ) {
        let (hasEntries, keyboards) = plistManager.getStatus()
        reply(hasEntries, keyboards)
    }
}

// MARK: - Errors

enum HelperError: LocalizedError {
    case invalidEntry

    var errorDescription: String? {
        switch self {
        case .invalidEntry:
            return "Invalid keyboard entry format"
        }
    }
}

// MARK: - Entry Point

let helper = HelperTool()
helper.run()
