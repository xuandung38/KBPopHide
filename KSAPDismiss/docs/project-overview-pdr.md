# Project Overview & Product Development Requirements (PDR)

## Project Summary

**Project Name**: KSAP Dismiss
**Version**: 1.0.0 (Phase 4)
**Status**: Active Development
**Platform**: macOS
**Last Updated**: 2026-01-04

### Vision

Build a modern, user-friendly macOS menu bar utility that seamlessly prevents the "Keyboard Setup Assistant" (KSA) popup from appearing when users connect USB keyboards. The application leverages secure XPC-based privilege elevation to safely manage system keyboard configuration without requiring full app elevation.

### Project Goals

1. **Primary**: Suppress KSA popup for USB keyboard connections
2. **Secondary**: Provide intuitive UI for keyboard management
3. **Quality**: Robust error handling and user feedback
4. **Security**: Use principle of least privilege with XPC architecture
5. **Reliability**: Automatic keyboard detection and configuration
6. **User Experience**: Minimal user intervention required

## Phase Overview

### Phase 1: Foundation (Completed)
- Basic app structure with SwiftUI
- Menu bar integration
- USB keyboard detection via IOKit
- Authorization-based privilege elevation
- Settings window with UI framework
- Localization (English/Vietnamese)

### Phase 2: XPC Communication (Current - Completed)
- **Objective**: Implement secure inter-process communication for privileged operations
- **Deliverables**:
  - XPC protocol definition (HelperProtocol)
  - XPC client implementation (XPCClient)
  - Unit tests for XPC layer
  - System architecture documentation
  - Code standards documentation
- **Completion Date**: 2026-01-04
- **Status**: Completed

### Phase 3: Touch ID Integration (Current - Completed)
- **Objective**: Implement biometric authentication and secure operation execution
- **Deliverables**:
  - TouchIDAuthenticator for biometric authentication
  - SecureOperationExecutor for auth + XPC operations
  - Face ID entitlement configuration
  - Unit tests for authentication layer
  - Authentication implementation guide
- **Completion Date**: 2026-01-04
- **Status**: Completed

### Phase 4: SMJobBless Installation (Current - Completed)
- **Objective**: Implement automated privileged helper installation via SMJobBless
- **Deliverables**:
  - HelperInstaller class for installation management
  - SMJobBless integration via Security framework
  - Helper version checking and update detection
  - Launchd plist configuration
  - Helper entitlements configuration
  - Auto-install on first use
  - Comprehensive unit tests (13 tests)
- **Completion Date**: 2026-01-04
- **Status**: Completed

### Phase 5: Integration & Polish (Planned)
- Integrate XPC with KeyboardManager
- Remove Authorization Services dependency
- End-to-end testing
- Performance optimization
- User-facing error messages

### Phase 6: Distribution (Planned)
- App signing and notarization
- Helper tool code signing
- Installer creation
- Distribution channels
- Update mechanism (Sparkle)

## Product Requirements

### Functional Requirements

#### FR-1: Keyboard Setup Assistant Control
- **Description**: Users can enable/disable KSA popup
- **Implementation**: Modify keyboard preference plist via helper tool
- **Acceptance Criteria**:
  - KSA disabled when entries added to plist
  - KSA enabled when entries removed from plist
  - Status persists across app restart
  - Works with all USB keyboard types

#### FR-2: Automatic Mode
- **Description**: Automatically suppress KSA for newly connected keyboards
- **Implementation**: Monitor USB ports, auto-add entries for detected keyboards
- **Acceptance Criteria**:
  - Detects USB keyboard connection within 1 second
  - Automatically adds entries without user interaction
  - Works for keyboard hotplug while app is running

#### FR-3: Keyboard Detection
- **Description**: Identify connected USB keyboards
- **Implementation**: Use IOKit to enumerate USB devices
- **Acceptance Criteria**:
  - Detects standard USB keyboards
  - Captures vendor ID and product ID
  - Handles multiple simultaneous keyboards
  - Supports keyboard hotplug events

#### FR-4: Visual Status Indication
- **Description**: Display current KSA status via menu bar icon
- **Implementation**: Menu bar extra with enabled/disabled icon
- **Acceptance Criteria**:
  - Icon visible when app running
  - Distinguishes enabled vs disabled state
  - Tooltip shows current status
  - Updates immediately on state change

#### FR-5: Settings Interface
- **Description**: Comprehensive settings window for configuration
- **Implementation**: SwiftUI multi-tab interface
- **Acceptance Criteria**:
  - General tab: enable/disable, auto mode toggle, language selection
  - Keyboards tab: list of detected/configured keyboards
  - About tab: version and attribution info
  - Settings persist across app restart

#### FR-6: Localization
- **Description**: Support multiple languages
- **Implementation**: Localized string resources
- **Acceptance Criteria**:
  - English (US) support
  - Vietnamese support
  - Easy language switching
  - All UI strings translated
  - RTL language ready (future)

#### FR-7: Login Item Integration
- **Description**: Optional auto-launch at login
- **Implementation**: SMAppService integration
- **Acceptance Criteria**:
  - Toggle available in settings
  - Setting persists across restart
  - Auto-launch works reliably
  - No performance impact when disabled

#### FR-8: XPC Communication
- **Description**: Secure inter-process communication with helper tool
- **Implementation**: NSXPCConnection to privileged helper
- **Acceptance Criteria**:
  - Connect/disconnect to helper
  - Version compatibility check
  - Operations complete within 5 seconds
  - Automatic reconnection on failure
  - Logs connection lifecycle

### Non-Functional Requirements

#### NFR-1: Security
- **Requirement**: Principle of least privilege
- **Implementation**:
  - Main app runs unprivileged
  - Only helper tool has elevated privileges
  - All inputs validated before system operations
  - No arbitrary command execution
  - Code signed and notarized
- **Acceptance Criteria**:
  - No security warnings from Xcode
  - Passes macOS code signing verification
  - No data stored unencrypted
  - No network communication

#### NFR-2: Performance
- **Requirement**: Minimal system resource usage
- **Implementation**:
  - Lightweight menu bar app
  - Efficient USB monitoring
  - On-demand plist operations
  - Connection pooling for XPC
- **Acceptance Criteria**:
  - <100 MB memory usage
  - <1% CPU when idle
  - Keyboard detection within 1 second
  - Helper startup within 500ms

#### NFR-3: Reliability
- **Requirement**: Robust error handling
- **Implementation**:
  - Retry logic with exponential backoff
  - Automatic reconnection
  - Graceful degradation on errors
  - User-friendly error messages
- **Acceptance Criteria**:
  - No unhandled exceptions
  - Recovery from network glitches
  - Recovery from helper crashes
  - Clear error messages to users

#### NFR-4: Compatibility
- **Requirement**: Support recent macOS versions
- **Implementation**:
  - Minimum: macOS 13.0 (Ventura)
  - MenuBarExtra requires macOS 13+
  - Test on Monterey compatibility (unsupported but graceful)
- **Acceptance Criteria**:
  - Works on Ventura, Sonoma, Sequoia
  - Graceful failure on older systems
  - No deprecated API usage

#### NFR-5: Maintainability
- **Requirement**: Clean, well-documented codebase
- **Implementation**:
  - Protocol-based architecture
  - Comprehensive unit tests
  - Detailed code documentation
  - Architecture documentation
- **Acceptance Criteria**:
  - >80% code test coverage
  - All public APIs documented
  - Architecture decisions recorded
  - Onboarding guide for new developers

#### NFR-6: Usability
- **Requirement**: Intuitive user experience
- **Implementation**:
  - Minimal user configuration
  - Clear status indicators
  - Quick access menu
  - Helpful error messages
- **Acceptance Criteria**:
  - First-time setup <30 seconds
  - Users understand current status
  - Common tasks require <2 clicks
  - All errors are actionable

## Architecture Decisions

### Decision 1: XPC-Based Privilege Elevation
**Date**: 2026-01-04
**Status**: Implemented (Phase 2)

**Rationale**:
- Safer than running entire app with sudo
- Uses macOS native security mechanisms
- Allows fine-grained permission control
- Future proof for App Store distribution

**Alternatives Considered**:
1. Run entire app with sudo - REJECTED (security risk)
2. AuthorizationServices callbacks - LEGACY (being phased out)
3. SMJobBless - CHOSEN (native XPC wrapper)

### Decision 2: SwiftUI + Async/Await
**Date**: Phase 1
**Status**: Active

**Rationale**:
- Modern concurrency model
- Reactive UI framework
- Reduces callback complexity
- Better developer experience

**Constraints**:
- Requires Swift 5.9+
- Requires macOS 13.0+

### Decision 3: Protocol-Based Architecture
**Date**: Phase 1
**Status**: Active

**Rationale**:
- Enables comprehensive testing with mocks
- Reduces coupling between components
- Easy to swap implementations
- Future abstraction flexibility

**Protocols**:
- AuthorizationProtocol (future removal)
- FileSystemProtocol (plist operations)
- USBMonitorProtocol (USB detection)
- HelperProtocol (XPC interface)

### Decision 4: Singleton Pattern for Shared Resources
**Date**: Phase 2
**Status**: Active

**Rationale**:
- XPCClient needs single connection to helper
- Centralized state management
- Convenient access across app

**Implementation**:
```swift
@MainActor final class XPCClient: ObservableObject {
    static let shared = XPCClient()
    private init() {}
}
```

## Technical Stack

### Language & Frameworks
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Concurrency**: Swift async/await
- **IPC**: XPC (NSXPCConnection)
- **Package Manager**: Swift Package Manager (SPM)

### System Frameworks
- `Foundation` - Core library
- `SwiftUI` - Modern UI
- `IOKit` - USB device enumeration
- `Security` - Authorization Services (legacy)
- `ServiceManagement` - Login item integration (SMAppService)
- `os.log` - System logging

### External Dependencies
**None** - Pure Swift/Foundation implementation

### Development Tools
- **IDE**: Xcode 15.0+
- **VCS**: Git with GitHub
- **CI/CD**: GitHub Actions
- **Build**: Swift Package Manager & xcodegen

## Testing Strategy

### Unit Testing
- **Framework**: XCTest
- **Coverage Goal**: >80% of business logic
- **Location**: `Tests/KSAPDismissTests/Unit/`
- **Approach**: Protocol-based mocking

**Test Suites**:
1. XPCClientTests (XPC layer)
2. KeyboardManagerTests (business logic)
3. AuthorizationHelperTests (legacy auth)
4. USBMonitorTests (USB detection)
5. LanguageManagerTests (localization)

**Mock Objects**:
- MockAuthHelper
- MockFileSystem
- MockUSBDetector
- MockUSBMonitor
- MockXPCConnection (future)

### Integration Testing
- **Scope**: Helper tool <-> client communication
- **Prerequisite**: Installed and signed helper tool
- **Status**: Planned for Phase 3

### UI Testing
- **Framework**: XCTest + SwiftUI testing APIs
- **Status**: Not yet implemented
- **Priority**: Medium

### Manual Testing
- **Devices**: Mac with USB keyboard
- **Scenarios**:
  - Connect/disconnect USB keyboard
  - Enable/disable popup
  - Switch languages
  - Toggle automatic mode
  - Check status persistence
  - Auto-launch at login

## Security Requirements

### Authentication
- **Type**: macOS system authentication
- **Method**: Authorization Services (Phase 1) → XPC with SMJobBless (Phase 3)
- **Credential Storage**: None (macOS keychain via system)
- **Session Cache**: Temporary in-memory only

### Authorization
- **Privilege Level**: Minimal - only plist modification
- **Scope**: Specific file: `/Library/Preferences/com.apple.keyboardtype.plist`
- **Access Control**: Helper process validates all operations

### Data Protection
- **Sensitive Data**: None stored locally
- **Network**: No network communication
- **Encryption**: Not applicable (local operations only)
- **Audit**: os.log records all operations

### Code Signing
- **App**: Developer certificate
- **Helper**: Same developer certificate
- **Notarization**: Planned for Phase 5
- **Entitlements**: XPC service entitlement for helper

## Deployment & Distribution

### Build Artifacts
- `KSAP Dismiss.app` - Main application bundle
- `com.hxd.ksapdismiss.helper` - Privileged helper tool
- Installation package (planned)

### Distribution Methods
1. **GitHub Releases** (Planned)
   - Direct download of signed DMG/ZIP
   - Manual installation

2. **Homebrew** (Planned)
   - `brew install ksap-dismiss`
   - Automatic updates via Homebrew

3. **App Store** (Future)
   - Requires sandboxing adjustments
   - Requires entitlements review
   - Native update mechanism

### Versioning
- **Format**: Semantic versioning (MAJOR.MINOR.PATCH)
- **Current**: 1.0.0
- **Baseline**: Set after Phase 2 completion

### Update Strategy
- **Mechanism**: TBD (Sparkle or App Store)
- **Frequency**: Minor updates quarterly, patch as needed
- **Notification**: User prompt before auto-update

## Success Metrics

### Adoption Metrics
- Number of GitHub stars/forks
- Download count
- User feedback sentiment
- Bug report rate

### Quality Metrics
- Test coverage: >80%
- Build success rate: 100%
- Crash-free sessions: >99%
- Helper connection success rate: >95%

### Performance Metrics
- App startup time: <1 second
- Memory usage: <100 MB
- CPU usage (idle): <0.1%
- Keyboard detection latency: <1 second

### User Satisfaction
- GitHub issue resolution time: <1 week
- User feedback: 4.0+ stars (if rated)
- No major security issues

## Roadmap

### Short Term (Phase 5, Next 2-3 weeks)
- [ ] Complete XPC integration with KeyboardManager
- [ ] Write integration tests for helper installation
- [ ] Remove Authorization Services dependency (legacy)
- [ ] Add UI feedback for installation progress
- [ ] Test auto-install flow end-to-end
- [ ] Performance testing and optimization

### Medium Term (Phase 5, 2-3 months)
- [ ] Code signing and notarization
- [ ] Installer creation
- [ ] GitHub releases setup
- [ ] Homebrew formula
- [ ] Documentation site

### Long Term (Phase 6+, 3-6 months)
- [ ] Bluetooth keyboard support
- [ ] Custom keyboard profiles
- [ ] Configuration import/export
- [ ] App Store distribution
- [ ] Automatic updates (Sparkle)
- [ ] Additional language support

## Risk Assessment

### Technical Risks

**Risk 1**: XPC communication failures
- **Impact**: High (core functionality)
- **Probability**: Medium
- **Mitigation**: Retry logic, auto-reconnect, comprehensive logging

**Risk 2**: Helper tool installation issues
- **Impact**: High (prevents privileged operations)
- **Probability**: Medium
- **Mitigation**: SMJobBless framework, clear error messages, installation guide

**Risk 3**: macOS version compatibility
- **Impact**: Medium (only affects older systems)
- **Probability**: Low
- **Mitigation**: Minimum version 13.0, graceful degradation

### Organizational Risks

**Risk 1**: Maintenance burden
- **Impact**: Medium
- **Probability**: Low
- **Mitigation**: Comprehensive documentation, automated testing, clear code

**Risk 2**: Security vulnerabilities
- **Impact**: High
- **Probability**: Low
- **Mitigation**: Code review, security focus, responsible disclosure policy

## Stakeholders

- **Author/Owner**: Xuan Dung, Ho (me@hxd.vn)
- **Contributors**: Open source community (future)
- **Users**: Mac users with multiple USB keyboards
- **Reviewers**: Code reviewers for PR validation

## Documentation

### Available Documentation
- `/docs/system-architecture.md` - System design and components
- `/docs/xpc-communication.md` - XPC layer implementation details
- `/docs/code-standards.md` - Development standards and guidelines
- `/docs/codebase-summary.md` - Project overview and statistics
- `/README.md` - User-facing documentation

### To Be Created
- Installation guide
- API documentation
- Helper tool development guide
- Deployment guide
- Contributing guide

## Contact & Support

**Author**: Xuan Dung, Ho
**Email**: me@hxd.vn
**Website**: https://hxd.vn
**GitHub**: https://github.com/xuandung38/ksap-dismiss
**Issues**: https://github.com/xuandung38/ksap-dismiss/issues

## Appendix

### Glossary
- **KSA**: Keyboard Setup Assistant - macOS system dialog
- **XPC**: XPC Services - macOS inter-process communication framework
- **IOKit**: Apple's low-level kernel I/O framework
- **plist**: macOS property list file format
- **SMJobBless**: Framework for installing privileged helper tools
- **Mach IPC**: Kernel-level inter-process communication

### References
- [Apple XPC Documentation](https://developer.apple.com/documentation/xpc/)
- [SMJobBless Framework](https://developer.apple.com/documentation/servicemanagement)
- [Swift Concurrency Guide](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)

---

**Document Metadata**:
- **Created**: 2026-01-04
- **Last Updated**: 2026-01-04
- **Version**: 1.0
- **Status**: Active - Phase 2 Complete
- **Next Review**: 2026-02-01
