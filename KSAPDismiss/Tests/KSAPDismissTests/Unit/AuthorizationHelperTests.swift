@testable import KSAPDismiss
import XCTest

/// Tests for AuthorizationHelper protocol behavior via MockAuthHelper
/// and AuthError enum properties
final class AuthorizationHelperTests: XCTestCase {
    var mockAuthHelper: MockAuthHelper!

    override func setUp() {
        super.setUp()
        mockAuthHelper = MockAuthHelper()
    }

    override func tearDown() {
        mockAuthHelper.reset()
        mockAuthHelper = nil
        super.tearDown()
    }

    // MARK: - Batch Command Tests

    func testExecuteBatchShellCommandRecordsCommand() throws {
        let command = "defaults write /Library/Preferences/com.apple.keyboardtype.plist keyboardtype -dict-add '1452-635-0' 40"

        try mockAuthHelper.executeBatchShellCommand(command)

        XCTAssertEqual(mockAuthHelper.batchCallCount, 1)
        XCTAssertEqual(mockAuthHelper.executedBatchCommands.count, 1)
        XCTAssertEqual(mockAuthHelper.executedBatchCommands.first, command)
    }

    func testExecutePrivilegedRecordsCommandAndArgs() throws {
        let command = "/usr/bin/defaults"
        let args = ["write", "/Library/Preferences/test.plist", "key", "value"]

        try mockAuthHelper.executePrivileged(command: command, args: args)

        XCTAssertEqual(mockAuthHelper.privilegedCallCount, 1)
        XCTAssertEqual(mockAuthHelper.executedPrivilegedCommands.count, 1)
        XCTAssertEqual(mockAuthHelper.executedPrivilegedCommands.first?.command, command)
        XCTAssertEqual(mockAuthHelper.executedPrivilegedCommands.first?.args, args)
    }

    func testMultipleSequentialCommands() throws {
        try mockAuthHelper.executeBatchShellCommand("cmd1")
        try mockAuthHelper.executeBatchShellCommand("cmd2")
        try mockAuthHelper.executePrivileged(command: "/bin/echo", args: ["hello"])
        try mockAuthHelper.executeBatchShellCommand("cmd3")

        XCTAssertEqual(mockAuthHelper.batchCallCount, 3)
        XCTAssertEqual(mockAuthHelper.privilegedCallCount, 1)
        XCTAssertEqual(mockAuthHelper.executedBatchCommands, ["cmd1", "cmd2", "cmd3"])
        XCTAssertEqual(mockAuthHelper.executedCommands.count, 4)
    }

    func testErrorSimulation() {
        mockAuthHelper.shouldThrowError = AuthError.authorizationDenied

        XCTAssertThrowsError(try mockAuthHelper.executeBatchShellCommand("test")) { error in
            XCTAssertTrue(error is AuthError)
            if case AuthError.authorizationDenied = error {
                // Expected
            } else {
                XCTFail("Expected authorizationDenied error")
            }
        }

        // Command should not be recorded when error thrown
        XCTAssertTrue(mockAuthHelper.executedBatchCommands.isEmpty)
        XCTAssertEqual(mockAuthHelper.batchCallCount, 1) // Call count still increments
    }

    func testReset() throws {
        // Setup state
        try mockAuthHelper.executeBatchShellCommand("cmd1")
        try mockAuthHelper.executePrivileged(command: "/bin/test", args: ["arg"])
        mockAuthHelper.shouldThrowError = AuthError.createFailed

        mockAuthHelper.reset()

        XCTAssertTrue(mockAuthHelper.executedCommands.isEmpty)
        XCTAssertTrue(mockAuthHelper.executedBatchCommands.isEmpty)
        XCTAssertTrue(mockAuthHelper.executedPrivilegedCommands.isEmpty)
        XCTAssertEqual(mockAuthHelper.batchCallCount, 0)
        XCTAssertEqual(mockAuthHelper.privilegedCallCount, 0)
        XCTAssertNil(mockAuthHelper.shouldThrowError)
    }

    // MARK: - AuthError Tests

    func testAuthErrorDescriptions() {
        // Each error case should have a description (except userCanceled)
        XCTAssertNotNil(AuthError.createFailed.errorDescription)
        XCTAssertNotNil(AuthError.rightSetFailed(-60005).errorDescription)
        XCTAssertNotNil(AuthError.authorizationDenied.errorDescription)
        XCTAssertNotNil(AuthError.executionFailed("test error").errorDescription)
        XCTAssertNotNil(AuthError.invalidCommand.errorDescription)

        // Verify specific content
        XCTAssertTrue(AuthError.createFailed.errorDescription!.contains("create"))
        XCTAssertTrue(AuthError.rightSetFailed(-60005).errorDescription!.contains("-60005"))
        XCTAssertTrue(AuthError.executionFailed("custom msg").errorDescription!.contains("custom msg"))
    }

    func testShouldShowAlertProperty() {
        // userCanceled should NOT show alert
        XCTAssertFalse(AuthError.userCanceled.shouldShowAlert)

        // All other errors SHOULD show alert
        XCTAssertTrue(AuthError.createFailed.shouldShowAlert)
        XCTAssertTrue(AuthError.rightSetFailed(-60005).shouldShowAlert)
        XCTAssertTrue(AuthError.authorizationDenied.shouldShowAlert)
        XCTAssertTrue(AuthError.executionFailed("test").shouldShowAlert)
        XCTAssertTrue(AuthError.invalidCommand.shouldShowAlert)
    }

    func testUserCanceledSilent() {
        // userCanceled should return nil description (silent error)
        XCTAssertNil(AuthError.userCanceled.errorDescription)
    }

    // MARK: - Protocol Conformance Tests

    func testProtocolConformance() throws {
        let helper: any AuthorizationProtocol = mockAuthHelper

        try helper.executeBatchShellCommand("test")
        try helper.executePrivileged(command: "/bin/test", args: [])

        XCTAssertEqual(mockAuthHelper.batchCallCount, 1)
        XCTAssertEqual(mockAuthHelper.privilegedCallCount, 1)
    }
}
