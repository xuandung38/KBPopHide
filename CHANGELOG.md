# Changelog

All notable changes to KSAP Dismiss will be documented in this file.

## [1.1.1] - 2026-01-04

### Changed
- **Touch ID Authentication**: Replaced AppleScript-based password prompts with native Touch ID/Face ID
- **Privileged Helper Architecture**: New SMJobBless-based privileged helper tool for secure operations
- **XPC Communication**: Secure inter-process communication between app and helper

### Added
- **Touch ID Integration**
  - `TouchIDAuthenticator` - LAContext wrapper for biometric authentication
  - `SecureOperationExecutor` - Combined Touch ID + XPC execution pipeline
  - Fallback to password when biometrics unavailable

- **Privileged Helper Tool**
  - `HelperInstaller` - SMJobBless-based helper installation
  - `XPCClient` - XPC communication with retry logic
  - `HelperProtocol` - Shared protocol for app ↔ helper communication

- **E2E Testing Infrastructure** (23 new tests, 78 total)
  - `XPCIntegrationTests` - 13 tests for XPC client flows
  - `SecureOperationExecutorIntegrationTests` - 10 tests for auth+XPC
  - `MockXPCHelper`, `MockXPCClient`, `MockTouchIDAuthenticator`
  - `XPCClientProtocol` for dependency injection

- **Package Restructure**
  - Split into library (KSAPDismiss) + executable (KSAPDismissApp)
  - Tests work with both `swift test` and Xcode
  - CI/CD compatible with GitHub Actions

### Removed
- `AuthorizationHelper.swift` - Legacy AppleScript-based authorization
- `AuthorizationProtocol.swift` - No longer needed

### Fixed
- Swift 6 strict concurrency errors in XPCClient closures
- Proper error handling for Touch ID cancellation (silent, no alert)

## [1.1.0] - 2026-01-04

### Changed
- **Project Rebrand**: Renamed from KBPopHide to KSAP Dismiss
- Repository moved to `github.com/xuandung38/ksap-dismiss`
- Updated all internal references, bundle IDs, and documentation

### Added
- **Settings Window Improvements**
  - Window now floats on top of all other applications
  - Window centers on the screen where mouse cursor is located
  - Manual window management via `SettingsWindowController`

- **Unit Tests** (18 new tests, 23 total)
  - `USBMonitorTests` - 9 test cases for USB monitoring behavior
  - `AuthorizationHelperTests` - 9 test cases for privilege elevation
  - `USBMonitorProtocol` for dependency injection
  - `MockUSBMonitor` with test instrumentation
  - Enhanced `MockAuthHelper` with call counts and error simulation

- **Developer Experience**
  - `CLAUDE.md` for AI assistant configuration
  - `LazyView` utility for deferred SwiftUI view loading

### Fixed
- Resolved Swift 6 concurrency warnings in protocols and mocks
- Added `@preconcurrency` conformance where needed

## [1.0.0] - 2026-01-03

### Added
- **Core Features**
  - Menu bar integration with status indicator
  - Settings window with General, Keyboards, and About tabs
  - Enable/Disable Keyboard Setup Assistant popup

- **Automatic Mode**
  - Real-time USB keyboard detection via IOKit
  - Silent auto-suppress when new keyboards connected

- **System Integration**
  - Start at Login via SMAppService
  - Authorization caching for session-based credentials

- **Localization**
  - English and Vietnamese language support
  - Live language switching

### Technical
- Built with SwiftUI and Swift Concurrency
- Minimum macOS 13.0 (Ventura)
- Native Apple Silicon support
