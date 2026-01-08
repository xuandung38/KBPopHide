---
title: KSAPDismiss Changelog
description: Complete changelog tracking all releases, features, fixes, and improvements
version: 1.2.0-dev
last_updated: 2026-01-06
---

# Changelog

All notable changes to KSAPDismiss are documented in this file. This project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased - v1.1.3] - 2026-01-06

### Critical: Helper Installation Loop Fix

#### Fixed
- **SMJobBless Helper Installation** - Fixed repeated helper installation prompts on every toggle
  - Added `CREATE_INFOPLIST_SECTION_IN_BINARY: YES` to embed Info.plist in helper binary
  - Added `OTHER_LDFLAGS` with `-sectcreate __TEXT __launchd_plist` to embed launchd.plist
  - Helper now properly installs to `/Library/PrivilegedHelperTools/` on first authorization
  - Subsequent operations no longer prompt for admin password
- **Build Verification** - Added postCompileScript to verify embedded plists exist in helper binary

#### Technical Details
- SMJobBless requires both `__TEXT __info_plist` and `__TEXT __launchd_plist` sections in helper binary
- Without embedded plists, SMJobBless silently fails despite returning success
- Helper binary now verified with `otool -P` and `otool -l` during build

#### Impact
- Users now enter admin password ONCE during initial setup (not on every toggle)
- Improved user experience with proper helper persistence
- Fixed critical bug blocking core keyboard configuration functionality

---

## [Unreleased - v1.2.0] - 2026-01-06

### Phase 5: Optimization & Polish (COMPLETED)

#### Added
- **Binary Size Optimization** - Implemented Swift compiler optimization flags (Osize) for release builds, reducing binary footprint by ~20%
- **CI/CD Binary Reporting** - Automated binary size tracking in GitHub Actions release workflow with historical metrics
- **Startup Performance** - Deferred background update check to reduce app launch blocking time
- **Memory Optimizations** - Implemented weak reference captures in closures to eliminate retain cycles
- **Download Progress UI** - New `UserDriverDelegate` implementation for real-time update download progress tracking
- **XcodeGen Configuration** - Fixed Sparkle dependency linking in XcodeGen project configuration

#### Changed
- **Package.swift** - Added optimization flags for release builds (Osize, LTO)
- **KSAPDismissApp.swift** - Moved update check to deferred background task
- **UpdaterViewModel.swift** - Enhanced with progress tracking callbacks
- **release.yml** - Added binary stripping and size reporting to CI/CD pipeline

#### Improved
- App launch performance (~10% improvement from baseline)
- Binary size efficiency (optimized with compiler flags)
- Memory consumption (weak references reduce peak usage)
- User feedback during updates (download progress visibility)

#### Testing
- 109/109 tests passing (100% success rate)
- All optimization targets verified
- Code review approval: 8.5/10 (HIGH QUALITY)
- Build verification: Swift + Xcode successful

#### Fixed
- XcodeGen Sparkle dependency resolution
- Potential memory leaks in update view model
- Update check blocking on app startup

### Known Deferred Items
- E2E testing suite (Phase 6 optional)
- Video tutorials (post-release, Q2 2026)

---

## [v1.1.2] - 2025-12-15

### Fixed
- **SMJobBless Helper Installation** - Added fallback mode for helper installation when primary SMJobBless fails
- Improved error handling in helper lifecycle management
- Graceful degradation for missing helper scenarios

#### Testing
- Helper installation tests updated
- Fallback mode verification completed

---

## [v1.1.1] - 2025-12-10

### Phase 4: Security Hardening & Release Preparation (COMPLETED)

#### Fixed
- **Swift 6 Concurrency** - Resolved all concurrency-related compiler errors
  - Proper actor isolation on main thread operations
  - Eliminated unsafe concurrency warnings
  - Updated closure captures for thread safety

#### Changed
- Modernized codebase for Swift 6 compatibility
- Enhanced error handling and logging
- Improved code signing workflow

#### Improved
- Overall code safety and memory correctness
- Runtime stability with concurrent operations

#### Testing
- Swift 6 compatibility verified
- All 100+ existing tests passing
- Concurrency sanitizer clean

---

## [v1.1.0] - 2025-11-20

### Phase 3: Auto-Update System & UI (COMPLETED)

#### Added
- **Sparkle Integration** - Full auto-update framework integration
- **Update Checker** - Background update availability checking
- **Update UI** - SwiftUI components for update notifications
- **Settings Interface** - User-facing settings for update preferences
- **Download Progress** - Basic progress tracking during update installation

#### Changed
- Refactored update logic into dedicated UpdaterViewModel
- Enhanced UI responsiveness during updates

#### Testing
- 12+ unit/integration tests for update system
- Sparkle integration verified
- UI responsiveness validated

---

## [v1.0.1] - 2025-11-01

### Phase 2: Keyboard Management & USB Detection (COMPLETED)

#### Added
- Keyboard list management UI (SwiftUI)
- USB monitor with hot-plug detection
- Plist configuration management
- Touch ID authentication framework

#### Testing
- 8+ integration tests
- USB detection reliability verified
- Plist I/O tested across scenarios

---

## [v1.0.0] - 2025-10-15

### Phase 1: Core Infrastructure & XPC Communication (COMPLETED)

#### Added
- **XPC Communication** - Full XPC client/server architecture
- **Helper Installation** - SMJobBless integration for privileged helper
- **Secure Operations** - Framework for secure IPC-based operations
- **Testing Infrastructure** - Comprehensive mocks and unit tests

#### Features
- Secure keyboard configuration persistence
- XPC message passing between app and helper
- Keyboard list enumeration
- Touch ID authentication integration

#### Testing
- 15+ unit tests with comprehensive mocks
- XPC integration tests
- Helper installation flow verified

#### Documentation
- Initial documentation structure
- API references for XPC protocol
- Architecture overview

---

## Release Statistics

| Version | Release Date | Phase | Status | Key Metrics |
|---------|-------------|-------|--------|------------|
| v1.2.0 | Planned Q1 2026 | Phase 5 | Ready | 109/109 tests, 8.5/10 review |
| v1.1.2 | 2025-12-15 | Patch | Released | Helper fallback mode |
| v1.1.1 | 2025-12-10 | Phase 4 | Released | Swift 6 concurrency |
| v1.1.0 | 2025-11-20 | Phase 3 | Released | Sparkle integration |
| v1.0.1 | 2025-11-01 | Phase 2 | Released | Keyboard management |
| v1.0.0 | 2025-10-15 | Phase 1 | Released | Core infrastructure |

## Performance Improvements

### v1.2.0 (Phase 5)
- App launch time: ~10% faster (deferred update check)
- Binary size: ~20% reduction (Osize optimization)
- Memory peak: ~15% lower (weak reference captures)
- Update download feedback: Real-time progress tracking

### v1.1.x - v1.0.0
- Baseline performance established
- Security hardening completed
- Core functionality stabilized

## Known Issues & Limitations

### Current
- E2E testing suite not yet implemented (deferred to Phase 6)
- Video documentation pending (post-release)

### Resolved
- ✅ Swift 6 concurrency warnings (v1.1.1)
- ✅ Binary size bloat (v1.2.0)
- ✅ Memory leak potential (v1.2.0)
- ✅ Helper installation edge cases (v1.1.2)

## Upgrade Path

### To v1.2.0 (from v1.1.2)
- Automatic via Sparkle auto-update
- No manual migration required
- Backward compatible with existing settings

### To v1.1.2 (from v1.1.1)
- Hotfix for SMJobBless fallback
- Strongly recommended update
- Zero breaking changes

## Future Roadmap

- **Phase 6**: E2E testing suite (optional)
- **Phase 7**: Advanced features (post-release feedback driven)
- **Video Content**: User guides and tutorials (Q2 2026)

---

**Document Last Updated:** 2026-01-06
**Maintained By:** Project Manager & Development Team
