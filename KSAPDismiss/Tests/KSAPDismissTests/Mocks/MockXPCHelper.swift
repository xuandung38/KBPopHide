import Foundation
import XCTest
@testable import KSAPDismiss

/// Mock XPC Helper for testing XPC communication
/// Uses anonymous XPC listener pattern for integration testing
final class MockXPCHelper: NSObject, HelperProtocol, NSXPCListenerDelegate, @unchecked Sendable {

    // MARK: - Call Tracking

    private(set) var getVersionCalled = false
    private(set) var addKeyboardEntriesCalled = false
    private(set) var removeAllEntriesCalled = false
    private(set) var getKeyboardStatusCalled = false

    private(set) var lastAddedEntries: [[String: Any]]?
    private(set) var callCount = 0

    // MARK: - Configurable Results

    var versionToReturn = kHelperVersion
    var addKeyboardResult: (success: Bool, error: String?) = (true, nil)
    var removeAllResult: (success: Bool, error: String?) = (true, nil)
    var keyboardStatusResult: (hasEntries: Bool, keyboards: [String]?) = (false, nil)

    // MARK: - Delays (for testing timeouts)

    var responseDelay: TimeInterval = 0

    // MARK: - HelperProtocol Implementation

    func getVersion(withReply reply: @escaping (String) -> Void) {
        getVersionCalled = true
        callCount += 1

        if responseDelay > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + responseDelay) {
                reply(self.versionToReturn)
            }
        } else {
            reply(versionToReturn)
        }
    }

    func addKeyboardEntries(_ entries: [[String: Any]], withReply reply: @escaping (Bool, String?) -> Void) {
        addKeyboardEntriesCalled = true
        lastAddedEntries = entries
        callCount += 1

        if responseDelay > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + responseDelay) {
                reply(self.addKeyboardResult.success, self.addKeyboardResult.error)
            }
        } else {
            reply(addKeyboardResult.success, addKeyboardResult.error)
        }
    }

    func removeAllKeyboardEntries(withReply reply: @escaping (Bool, String?) -> Void) {
        removeAllEntriesCalled = true
        callCount += 1

        if responseDelay > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + responseDelay) {
                reply(self.removeAllResult.success, self.removeAllResult.error)
            }
        } else {
            reply(removeAllResult.success, removeAllResult.error)
        }
    }

    func getKeyboardStatus(withReply reply: @escaping (Bool, [String]?) -> Void) {
        getKeyboardStatusCalled = true
        callCount += 1

        if responseDelay > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + responseDelay) {
                reply(self.keyboardStatusResult.hasEntries, self.keyboardStatusResult.keyboards)
            }
        } else {
            reply(keyboardStatusResult.hasEntries, keyboardStatusResult.keyboards)
        }
    }

    // MARK: - NSXPCListenerDelegate

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }

    // MARK: - Test Helpers

    func reset() {
        getVersionCalled = false
        addKeyboardEntriesCalled = false
        removeAllEntriesCalled = false
        getKeyboardStatusCalled = false
        lastAddedEntries = nil
        callCount = 0

        versionToReturn = kHelperVersion
        addKeyboardResult = (true, nil)
        removeAllResult = (true, nil)
        keyboardStatusResult = (false, nil)
        responseDelay = 0
    }
}
