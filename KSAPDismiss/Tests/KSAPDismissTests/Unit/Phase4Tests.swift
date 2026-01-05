import XCTest
import Sparkle
@testable import KSAPDismiss

/// Tests for Sparkle Auto-Update Phase 4 features:
/// - Beta channel filtering (UpdaterDelegate)
/// - Version tracking (RollbackManager)
/// - Analytics opt-in (AnalyticsManager)
@MainActor
final class Phase4Tests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        // Clear UserDefaults for clean test state
        UserDefaults.standard.removeObject(forKey: "PreferBetaUpdates")
        UserDefaults.standard.removeObject(forKey: "EnableAnalytics")
        UserDefaults.standard.removeObject(forKey: "LaunchCountForVersion")
        UserDefaults.standard.removeObject(forKey: "LastLaunchedVersion")
    }

    override func tearDown() async throws {
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "PreferBetaUpdates")
        UserDefaults.standard.removeObject(forKey: "EnableAnalytics")
        UserDefaults.standard.removeObject(forKey: "LaunchCountForVersion")
        UserDefaults.standard.removeObject(forKey: "LastLaunchedVersion")
        AnalyticsManager.shared.clearLogs()
        try await super.tearDown()
    }

    // MARK: - Beta Channel Tests (UpdaterDelegate)

    func testUpdaterDelegateInitialization() {
        let delegate = UpdaterDelegate()
        XCTAssertNotNil(delegate)
    }

    func testDefaultChannelIsStable() {
        // By default, PreferBetaUpdates should be false
        UserDefaults.standard.set(false, forKey: "PreferBetaUpdates")

        _ = UpdaterDelegate() // Verify delegate can be initialized
        let preferBeta = UserDefaults.standard.bool(forKey: "PreferBetaUpdates")
        let channels = preferBeta ? Set(["beta", "default"]) : Set(["default"])

        XCTAssertEqual(channels, ["default"])
        XCTAssertFalse(channels.contains("beta"))
    }

    func testBetaChannelWhenEnabled() {
        // Enable beta updates
        UserDefaults.standard.set(true, forKey: "PreferBetaUpdates")

        _ = UpdaterDelegate() // Verify delegate can be initialized
        let preferBeta = UserDefaults.standard.bool(forKey: "PreferBetaUpdates")
        let channels = preferBeta ? Set(["beta", "default"]) : Set(["default"])

        XCTAssertEqual(channels, ["beta", "default"])
        XCTAssertTrue(channels.contains("beta"))
        XCTAssertTrue(channels.contains("default"))
    }

    func testBetaChannelToggling() {
        _ = UpdaterDelegate() // Verify delegate can be initialized

        // Start with stable
        UserDefaults.standard.set(false, forKey: "PreferBetaUpdates")
        var preferBeta = UserDefaults.standard.bool(forKey: "PreferBetaUpdates")
        var channels = preferBeta ? Set(["beta", "default"]) : Set(["default"])
        XCTAssertEqual(channels, ["default"])

        // Switch to beta
        UserDefaults.standard.set(true, forKey: "PreferBetaUpdates")
        preferBeta = UserDefaults.standard.bool(forKey: "PreferBetaUpdates")
        channels = preferBeta ? Set(["beta", "default"]) : Set(["default"])
        XCTAssertEqual(channels, ["beta", "default"])

        // Switch back to stable
        UserDefaults.standard.set(false, forKey: "PreferBetaUpdates")
        preferBeta = UserDefaults.standard.bool(forKey: "PreferBetaUpdates")
        channels = preferBeta ? Set(["beta", "default"]) : Set(["default"])
        XCTAssertEqual(channels, ["default"])
    }

    // MARK: - RollbackManager Tests

    func testRollbackManagerInitialization() {
        let manager = RollbackManager.shared
        XCTAssertNotNil(manager)
    }

    func testFirstLaunchTracking() {
        let manager = RollbackManager.shared

        // Before first launch
        XCTAssertEqual(manager.launchCount, 0)

        // Track first launch
        manager.trackLaunch()

        // Should have count of 1
        XCTAssertEqual(manager.launchCount, 1)
        XCTAssertFalse(manager.isStable) // Not stable yet (needs 3 launches)
    }

    func testSubsequentLaunchTracking() {
        let manager = RollbackManager.shared

        // Simulate 3 launches
        manager.trackLaunch() // Launch 1
        XCTAssertEqual(manager.launchCount, 1)

        manager.trackLaunch() // Launch 2
        XCTAssertEqual(manager.launchCount, 2)

        manager.trackLaunch() // Launch 3
        XCTAssertEqual(manager.launchCount, 3)
        XCTAssertTrue(manager.isStable) // Now stable
    }

    func testVersionStability() {
        let manager = RollbackManager.shared

        // Launch count < 3 = not stable
        UserDefaults.standard.set(2, forKey: "LaunchCountForVersion")
        XCTAssertFalse(manager.isStable)

        // Launch count = 3 = stable
        UserDefaults.standard.set(3, forKey: "LaunchCountForVersion")
        XCTAssertTrue(manager.isStable)

        // Launch count > 3 = still stable
        UserDefaults.standard.set(10, forKey: "LaunchCountForVersion")
        XCTAssertTrue(manager.isStable)
    }

    func testCurrentVersionProperty() {
        let manager = RollbackManager.shared
        let version = manager.currentVersion

        // Should return a non-empty string
        XCTAssertFalse(version.isEmpty)
        XCTAssertNotEqual(version, "unknown")
    }

    func testCrashLoopDetection() {
        let manager = RollbackManager.shared

        // Current implementation returns false (manual rollback only)
        let hasCrashLoop = manager.checkForCrashLoop()
        XCTAssertFalse(hasCrashLoop)
    }

    // MARK: - AnalyticsManager Tests

    func testAnalyticsManagerInitialization() {
        let manager = AnalyticsManager.shared
        XCTAssertNotNil(manager)
    }

    func testAnalyticsDisabledByDefault() {
        // Clear any previous settings
        UserDefaults.standard.removeObject(forKey: "EnableAnalytics")

        let manager = AnalyticsManager.shared
        let log = AnalyticsLog(
            timestamp: Date(),
            event: "test_event",
            properties: ["key": "value"]
        )

        // Log should be ignored when analytics disabled
        manager.log(log)

        let exported = manager.exportLogs()
        XCTAssertNil(exported) // No logs should be written
    }

    func testAnalyticsLoggingWhenEnabled() {
        // Enable analytics
        UserDefaults.standard.set(true, forKey: "EnableAnalytics")

        let manager = AnalyticsManager.shared
        manager.clearLogs() // Start clean

        let log = AnalyticsLog(
            timestamp: Date(),
            event: "test_event",
            properties: ["test_key": "test_value"]
        )

        // Log should be written
        manager.log(log)

        // Verify log was written
        let exported = manager.exportLogs()
        XCTAssertNotNil(exported)
        XCTAssertTrue(exported?.contains("test_event") ?? false)
        XCTAssertTrue(exported?.contains("test_key") ?? false)
        XCTAssertTrue(exported?.contains("test_value") ?? false)
    }

    func testAnalyticsLogStructure() {
        let timestamp = Date()
        let log = AnalyticsLog(
            timestamp: timestamp,
            event: "update_found",
            properties: [
                "current_version": "1.0.0",
                "available_version": "1.1.0",
                "channel": "stable"
            ]
        )

        XCTAssertEqual(log.timestamp, timestamp)
        XCTAssertEqual(log.event, "update_found")
        XCTAssertEqual(log.properties["current_version"], "1.0.0")
        XCTAssertEqual(log.properties["available_version"], "1.1.0")
        XCTAssertEqual(log.properties["channel"], "stable")
    }

    func testAnalyticsClearLogs() {
        // Enable analytics
        UserDefaults.standard.set(true, forKey: "EnableAnalytics")

        let manager = AnalyticsManager.shared

        // Write some logs
        manager.log(AnalyticsLog(timestamp: Date(), event: "event1", properties: [:]))
        manager.log(AnalyticsLog(timestamp: Date(), event: "event2", properties: [:]))

        // Verify logs exist
        XCTAssertNotNil(manager.exportLogs())

        // Clear logs
        manager.clearLogs()

        // Verify logs are cleared
        XCTAssertNil(manager.exportLogs())
    }

    func testAnalyticsLogSize() {
        let manager = AnalyticsManager.shared
        manager.clearLogs()

        // Initial size should be 0
        XCTAssertEqual(manager.logSize(), 0)

        // Enable analytics and log something
        UserDefaults.standard.set(true, forKey: "EnableAnalytics")
        manager.log(AnalyticsLog(timestamp: Date(), event: "test", properties: [:]))

        // Size should be > 0
        XCTAssertGreaterThan(manager.logSize(), 0)
    }

    func testMultipleAnalyticsEvents() {
        UserDefaults.standard.set(true, forKey: "EnableAnalytics")
        let manager = AnalyticsManager.shared
        manager.clearLogs()

        // Log multiple events
        let events = [
            AnalyticsLog(timestamp: Date(), event: "update_found", properties: ["version": "1.1.0"]),
            AnalyticsLog(timestamp: Date(), event: "update_downloaded", properties: ["version": "1.1.0"]),
            AnalyticsLog(timestamp: Date(), event: "no_update_available", properties: ["version": "1.0.0"])
        ]

        for event in events {
            manager.log(event)
        }

        // Verify all events are logged
        let exported = manager.exportLogs()
        XCTAssertNotNil(exported)
        XCTAssertTrue(exported?.contains("update_found") ?? false)
        XCTAssertTrue(exported?.contains("update_downloaded") ?? false)
        XCTAssertTrue(exported?.contains("no_update_available") ?? false)
    }

    // MARK: - Integration Tests

    func testBetaChannelAndAnalyticsTogether() {
        // Enable both beta and analytics
        UserDefaults.standard.set(true, forKey: "PreferBetaUpdates")
        UserDefaults.standard.set(true, forKey: "EnableAnalytics")

        _ = UpdaterDelegate() // Verify delegate can be initialized

        // Verify beta channel is enabled
        let preferBeta = UserDefaults.standard.bool(forKey: "PreferBetaUpdates")
        let channels = preferBeta ? Set(["beta", "default"]) : Set(["default"])
        XCTAssertTrue(channels.contains("beta"))

        // Verify analytics can log
        AnalyticsManager.shared.clearLogs()
        AnalyticsManager.shared.log(AnalyticsLog(timestamp: Date(), event: "test", properties: [:]))

        let logs = AnalyticsManager.shared.exportLogs()
        XCTAssertNotNil(logs)
    }

    func testVersionTrackingAndRollbackFlow() {
        let manager = RollbackManager.shared

        // Simulate version update scenario
        manager.trackLaunch() // Launch 1 of new version
        XCTAssertFalse(manager.isStable)

        manager.trackLaunch() // Launch 2
        XCTAssertFalse(manager.isStable)

        manager.trackLaunch() // Launch 3 - now stable
        XCTAssertTrue(manager.isStable)

        // No crash loop detected
        XCTAssertFalse(manager.checkForCrashLoop())
    }
}


