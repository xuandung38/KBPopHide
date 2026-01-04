# Changelog

All notable changes to KSAP Dismiss will be documented in this file.

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
