# Changelog

All notable changes to KSAP Dismiss will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2026-01-05

### Added
- Delta Updates: Binary patch generation for 60-90% bandwidth savings (Phase 4)
- Beta Channel Support: User-controlled early access to pre-release versions (Phase 4)
- Auto-Rollback Mechanism: Version launch tracking with manual rollback dialog (Phase 4)
- Analytics Integration: Privacy-first local JSON logging with opt-in (Phase 4)
- UpdaterDelegate for advanced Sparkle integration
- AnalyticsManager for privacy-respecting event tracking
- RollbackManager for version rollback capability
- Phase 4 test suite (19 new tests)

### Changed
- Enhanced SettingsView with Beta Channel and Analytics preference toggles
- UpdaterViewModel extended for delta updates and rollback support
- KSAPDismissApp integration with analytics and rollback pipeline
- GitHub Actions release.yml updated for delta generation (+195 lines)

### Fixed
- Sparkle integration now supports advanced features pipeline
- Version launch tracking prevents broken version persistence

## [1.1.2] - 2026-01-05

### Added
- Sparkle 2.8.1 auto-update framework integration
- Updates tab in Settings with automatic check toggle
- "Check for Updates..." menu item in menu bar
- UpdaterViewModel for managing update state
- EdDSA key pair for signing releases (Phase 1)
- Comprehensive unit tests for UpdaterViewModel (12 tests)
- EdDSA key validation script (`bin/validate_keys.sh`)

### Changed
- Info.plist configured with Sparkle SUFeedURL and SUPublicEDKey
- All tests now pass (90/90 tests, up from 78)

### Fixed
- Code review improvements: MARK comments, key validation

## [1.1.1] - 2026-01-05

### Added
- Touch ID/Face ID authentication for privileged operations
- XPC-based privileged helper architecture via SMJobBless
- SecureOperationExecutor combining Touch ID + XPC pipeline
- Fallback mode for SMJobBless helper installation
- XPC integration tests (13 tests)
- SecureOperationExecutor E2E tests (10 tests)

### Changed
- Replaced AppleScript-based authorization with LAContext
- Package restructured: library (KSAPDismiss) + executable (KSAPDismissApp)
- Tests compatible with both `swift test` and Xcode

### Removed
- AuthorizationHelper.swift (legacy AppleScript approach)
- AuthorizationProtocol.swift (no longer needed)

### Fixed
- Swift 6 strict concurrency errors in XPCClient closures
- Proper error handling for Touch ID cancellation (silent, no alert)

## [1.1.0] - 2026-01-05

### Added
- Settings window floats on top of all applications
- Window centers on screen where mouse cursor is located
- 23 unit tests with full Swift 6 concurrency compliance
- GitHub Actions CI/CD workflow for automated releases
- LazyView utility for deferred SwiftUI view loading

### Changed
- Project renamed from KBPopHide to KSAP Dismiss
- Repository moved to github.com/xuandung38/ksap-dismiss

### Fixed
- Swift 6 strict concurrency warnings in protocols and mocks
- XCTestCase actor isolation compatibility

## [1.0.0] - 2026-01-04

### Added
- Initial release
- Disable/enable Keyboard Setup Assistant popup
- Menu bar integration with visual status indicator
- Settings window (General, Keyboards, About tabs)
- Automatic mode: Real-time USB keyboard detection via IOKit
- Start at Login via SMAppService
- Authorization caching for session-based credentials
- English and Vietnamese localization
- Live language switching

[Unreleased]: https://github.com/xuandung38/ksap-dismiss/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/xuandung38/ksap-dismiss/compare/v1.1.2...v1.2.0
[1.1.2]: https://github.com/xuandung38/ksap-dismiss/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/xuandung38/ksap-dismiss/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/xuandung38/ksap-dismiss/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/xuandung38/ksap-dismiss/releases/tag/v1.0.0
