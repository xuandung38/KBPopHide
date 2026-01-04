import XCTest
@testable import KSAPDismiss

final class HelperInstallerTests: XCTestCase {

    // MARK: - Singleton Tests

    @MainActor
    func testHelperInstallerSingleton() {
        let installer1 = HelperInstaller.shared
        let installer2 = HelperInstaller.shared
        XCTAssertTrue(installer1 === installer2)
    }

    // MARK: - Installation Status Tests

    @MainActor
    func testHelperPathConstant() {
        // Verify the expected helper path
        let expectedPath = "/Library/PrivilegedHelperTools/com.hxd.ksapdismiss.helper"
        XCTAssertEqual(expectedPath, "/Library/PrivilegedHelperTools/\(kHelperBundleID)")
    }

    @MainActor
    func testInitialStateNotInstalling() {
        let installer = HelperInstaller.shared
        XCTAssertFalse(installer.isInstalling)
    }

    // MARK: - Error Description Tests

    func testHelperInstallerErrorDescriptions() {
        let errorsWithDescriptions: [HelperInstallerError] = [
            .alreadyInstalling,
            .authorizationFailed,
            .authorizationDenied,
            .userCanceled,
            .blessFailed("test"),
            .blessFailed(nil),
            .uninstallFailed("test")
        ]

        for error in errorsWithDescriptions {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }

    func testAlreadyInstallingErrorDescription() {
        let error = HelperInstallerError.alreadyInstalling
        XCTAssertEqual(error.errorDescription, "Installation already in progress")
    }

    func testAuthorizationFailedErrorDescription() {
        let error = HelperInstallerError.authorizationFailed
        XCTAssertEqual(error.errorDescription, "Failed to create authorization")
    }

    func testAuthorizationDeniedErrorDescription() {
        let error = HelperInstallerError.authorizationDenied
        XCTAssertEqual(error.errorDescription, "Authorization denied. Administrator access required.")
    }

    func testUserCanceledErrorDescription() {
        let error = HelperInstallerError.userCanceled
        XCTAssertEqual(error.errorDescription, "Installation canceled")
    }

    func testBlessFailedWithMessageErrorDescription() {
        let error = HelperInstallerError.blessFailed("Custom error")
        XCTAssertEqual(error.errorDescription, "Helper installation failed: Custom error")
    }

    func testBlessFailedWithoutMessageErrorDescription() {
        let error = HelperInstallerError.blessFailed(nil)
        XCTAssertEqual(error.errorDescription, "Helper installation failed: unknown error")
    }

    func testUninstallFailedErrorDescription() {
        let error = HelperInstallerError.uninstallFailed("Permission denied")
        XCTAssertEqual(error.errorDescription, "Helper uninstall failed: Permission denied")
    }

    // MARK: - Error Conformance Tests

    func testHelperInstallerErrorConformsToLocalizedError() {
        let error: Error = HelperInstallerError.authorizationDenied
        XCTAssertTrue(error is LocalizedError)
    }

    // MARK: - NeedsUpdate Logic Tests

    @MainActor
    func testNeedsUpdateWhenNotInstalled() {
        // When not installed, needsUpdate should return true
        // Note: This test depends on actual installation state
        let installer = HelperInstaller.shared
        if !installer.isInstalled {
            XCTAssertTrue(installer.needsUpdate)
        }
    }
}
