
import XCTest
@testable import KSAPDismiss

final class SecureOperationExecutorTests: XCTestCase {

    // MARK: - Singleton Tests

    @MainActor
    func testSecureOperationExecutorSingleton() {
        let executor1 = SecureOperationExecutor.shared
        let executor2 = SecureOperationExecutor.shared
        XCTAssertTrue(executor1 === executor2)
    }

    // MARK: - Integration with Dependencies

    @MainActor
    func testExecutorDependenciesExist() {
        // Verify that the executor can access its dependencies
        let executor = SecureOperationExecutor.shared

        // Touch ID authenticator should exist
        let touchID = TouchIDAuthenticator.shared
        XCTAssertNotNil(touchID)

        // XPC client should exist
        let xpc = XPCClient.shared
        XCTAssertNotNil(xpc)

        // Executor should exist
        XCTAssertNotNil(executor)
    }

    // MARK: - Error Type Tests

    func testTouchIDErrorConformsToLocalizedError() {
        let error: Error = TouchIDError.failed
        XCTAssertTrue(error is LocalizedError)
    }

    func testXPCErrorConformsToLocalizedError() {
        let error: Error = XPCError.notConnected
        XCTAssertTrue(error is LocalizedError)
    }
}
