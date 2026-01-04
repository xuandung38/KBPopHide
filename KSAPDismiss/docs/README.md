# KSAP Dismiss Documentation

Welcome to the KSAP Dismiss documentation hub. This directory contains comprehensive documentation for the KSAP Dismiss project covering architecture, implementation, standards, and project planning.

## Quick Navigation

### For Project Managers & Decision Makers
Start here to understand project scope, goals, and progress:
- **[project-overview-pdr.md](./project-overview-pdr.md)** - Project vision, requirements, roadmap, and phase overview

### For Software Architects & Designers
Understand the system design and architecture:
- **[system-architecture.md](./system-architecture.md)** - System design, component overview, connection lifecycle, thread safety

### For Developers Implementing Phase 4+
Learn how to implement new features and integrate with existing code:
- **[authentication-guide.md](./authentication-guide.md)** - Biometric auth patterns, error handling, implementation guide
- **[xpc-communication.md](./xpc-communication.md)** - XPC layer implementation guide, patterns, troubleshooting
- **[helper-installation-guide.md](./helper-installation-guide.md)** - SMJobBless helper installation and management
- **[code-standards.md](./code-standards.md)** - Development standards, naming conventions, best practices
- **[codebase-summary.md](./codebase-summary.md)** - Project statistics, component descriptions, data flows

### For Release & Deployment
Learn how to release new versions and manage updates:
- **[deployment-guide.md](./deployment-guide.md)** - Release process, version management, CI/CD workflow
- **[release-workflow.md](./release-workflow.md)** - GitHub Actions workflow details, technical specifications
- **[sparkle-integration.md](./sparkle-integration.md)** - Auto-update framework setup, appcast configuration, troubleshooting

### For New Team Members
Onboarding path (in reading order):
1. Read **project-overview-pdr.md** - Understand project vision (10 min)
2. Read **codebase-summary.md** - Understand codebase structure (15 min)
3. Read **system-architecture.md** - Understand design patterns (20 min)
4. Read **code-standards.md** - Learn development standards (15 min)
5. Read **authentication-guide.md** - Learn biometric auth patterns (20 min)
6. Read **xpc-communication.md** - Deep dive into XPC feature (20 min)
7. Read **helper-installation-guide.md** - SMJobBless helper setup (15 min)
8. Read **deployment-guide.md** - Release and deployment process (15 min)

**Total Onboarding Time**: ~130 minutes

**Release Engineers**: Add **release-workflow.md** and **sparkle-integration.md** (~60 min additional)

## Document Overview

### 1. Project Overview & PDR
**File**: `project-overview-pdr.md` (1,347 lines)

**Purpose**: Strategic planning and requirements document

**Contains**:
- Project vision and goals
- Phase breakdown (1-5)
- Functional requirements (8 detailed)
- Non-functional requirements (6 detailed)
- Architecture decisions with rationale
- Technology stack overview
- Testing strategy
- Security requirements
- Deployment strategy
- Success metrics
- Risk assessment
- Roadmap and timeline

**Audience**: Project managers, stakeholders, technical leads

**Key Sections**:
- Phase 2 Status: COMPLETED ✓
- Phase 3 Status: COMPLETED ✓ (Touch ID Integration)
- Phase 4: Helper Tool Implementation (Next)
- Phase 5: Integration & Polish (Planned)
- Phase 6: Distribution (Planned)

### 2. Authentication & Secure Operations Guide
**File**: `authentication-guide.md` (NEW - Phase 3)

**Purpose**: Comprehensive guide for biometric authentication and secure operation patterns

**Contains**:
- Architecture overview of authentication layer
- Quick start guide with code examples
- TouchIDAuthenticator component details
- SecureOperationExecutor usage patterns
- Error handling patterns (8 error cases)
- Implementation patterns (3 common scenarios)
- Configuration requirements
- Testing strategies
- Troubleshooting guide
- Best practices and integration examples

**Audience**: Developers implementing Touch ID/Face ID authentication

**Key Content**:
- LocalAuthentication framework integration
- Error handling with `shouldFallbackToPassword` and `shouldShowAlert`
- Biometric availability checking
- Fallback to device passcode
- User-friendly error messages
- Testing without requiring biometric hardware

**Code Examples**: 30+ snippets covering:
- Basic authentication flow
- Error handling patterns
- Graceful degradation
- Integration with XPC operations

### 4. System Architecture
**File**: `system-architecture.md` (Updated for Phase 3)

**Purpose**: System design and component architecture documentation

**Contains**:
- Updated architecture diagram with auth layer
- 5 component overview with responsibilities
- SecureOperationExecutor orchestration pattern (NEW)
- TouchIDAuthenticator biometric handling (NEW)
- XPCClient specification
- HelperProtocol interface definition
- Error handling design (Touch ID + XPC)
- Connection lifecycle
- Auto-reconnection logic with retry
- Thread safety patterns
- Testing strategy
- Security considerations
- Version compatibility system
- Integration points with other components
- Logging infrastructure

**Audience**: Software architects, senior developers

**Key Content**:
- SecureOperationExecutor for auth + XPC orchestration
- TouchIDAuthenticator with LocalAuthentication framework
- Error handling for biometric authentication
- Fallback to device passcode
- Thread-safe singleton patterns
- MainActor isolation for UI updates

### 5. XPC Communication Implementation
**File**: `xpc-communication.md` (1,401 lines)

**Purpose**: Detailed implementation guide and reference for XPC layer

**Contains**:
- Phase 2 implementation status
- XPCClient complete implementation walkthrough
- HelperProtocol XPC interface details
- XPCError enum and error handling patterns
- Unit test documentation
- 3 real-world integration patterns
- Configuration and constants reference
- Troubleshooting guide (6 scenarios)
- Performance characteristics
- Security notes
- Next steps for Phase 3-5

**Audience**: Developers implementing XPC-based features

**Code Examples**: 20+ snippets showing:
- Connection management
- Helper operations (async/await)
- Error handling patterns
- Retry logic
- Auto-reconnect patterns
- Testing approaches

**Key Patterns**:
1. Simple operation with auto-reconnect
2. State-based UI operations
3. Graceful degradation on errors

### 6. Codebase Summary
**File**: `codebase-summary.md` (To be updated for Phase 3)

**Purpose**: Project overview and codebase reference

**Contains**:
- Project overview and technology stack
- Project statistics (token counts, file sizes)
- Complete directory structure
- 6 core components with detailed descriptions
- Data flow diagrams for key operations
- Key concepts and constants
- 4 major architecture patterns explained
- Complete lifecycle documentation
- Configuration file reference
- Build and test instructions
- Dependencies list (none external!)
- Performance characteristics
- Security model
- Known limitations
- Future enhancements

**Audience**: Developers, technical writers, new team members

**Key Info**:
- Top 5 files by complexity
- Complete protocol-based architecture overview
- No external dependencies (pure Swift/Foundation)
- Support for English/Vietnamese localization

### 6. Deployment & Release Guide
**File**: `deployment-guide.md` (NEW - Phase 3)

**Purpose**: Comprehensive guide for releasing new versions and managing the release process

**Contains**:
- Release process overview (6 phases)
- Step-by-step release procedures
- GitHub Actions workflow details
- EdDSA signing and verification
- GitHub Pages appcast deployment
- GitHub configuration (secrets, permissions)
- Installation instructions for users
- Auto-update feature documentation
- Troubleshooting guide (6 scenarios)
- Version management and semantic versioning
- Release checklist and rollback procedures
- Resource links and references

**Audience**: Release engineers, project leads, deployment managers

**Key Sections**:
- Release Process: 6-phase workflow from changelog to deployment
- GitHub Actions: Full build, sign, deploy automation
- EdDSA Signing: Security details and verification
- User Installation: Manual and auto-update flows

### 7. Release Workflow Technical Details
**File**: `release-workflow.md` (NEW - Phase 3)

**Purpose**: Technical deep-dive into GitHub Actions release workflow

**Contains**:
- Workflow diagram and architecture
- 10-step detailed workflow breakdown:
  1. Trigger on version tags
  2. Checkout and setup
  3. Build universal binary
  4. Create DMG package
  5. Download Sparkle tools
  6. Sign with EdDSA
  7. Generate appcast.xml
  8. Deploy to GitHub Pages
  9. Create GitHub Release
- Technical specifications for each step
- Update flow from user perspective
- Signature verification flow
- GitHub Secrets configuration
- Workflow file reference (`.github/workflows/release.yml`)
- Monitoring and troubleshooting (5 scenarios)
- Rollback procedures
- Performance notes
- Security considerations

**Audience**: DevOps engineers, system architects, advanced developers

**Key Technical Content**:
- Workflow YAML structure and syntax
- Environment variables and outputs
- Build optimization details
- DMG creation process
- Sparkle tool usage
- GitHub Pages deployment
- Artifact management

### 8. Sparkle Auto-Update Integration
**File**: `sparkle-integration.md` (NEW - Phase 3)

**Purpose**: Complete guide for Sparkle framework setup and configuration

**Contains**:
- Sparkle overview and security properties
- Installation via Swift Package Manager
- EdDSA key pair generation and management
- Info.plist configuration:
  - SUFeedURL for appcast location
  - SUPublicEDKey for signature verification
- Entitlements configuration for network access
- Update checking mechanisms:
  - User-initiated manual checks
  - Automatic background checks
- Appcast.xml format specification
- EdDSA signature creation and verification details
- Update flow technical details
- Code implementation in UpdaterViewModel
- Settings UI integration patterns
- Error handling and troubleshooting (4 issues)
- Local testing strategies
- Performance impact analysis
- Version numbering strategy
- Best practices and recommendations

**Audience**: Developers implementing update features, release engineers

**Key Content**:
- XML appcast structure and elements
- Signature verification security model
- Update checking background process
- Error scenarios and solutions
- Testing without real releases
- Version format and compatibility

### 9. Code Standards & Guidelines
**File**: `code-standards.md` (1,089 lines)

**Purpose**: Development standards and best practices

**Contains**:
- Swift naming conventions (PascalCase, camelCase, k prefix)
- Concurrency model (async/await, @MainActor)
- Memory management (capture lists, weak self)
- Documentation requirements
- SwiftUI component organization
- Protocol design standards
- Testing structure and patterns
- Architecture patterns (Singleton, Observable, DI)
- XPC-specific patterns
- Logging standards
- File organization structure
- Performance optimization guidelines
- Code review checklist

**Audience**: All developers on the project

**Key Standards**:
- Max 120 character line length
- 4-space indentation (Swift convention)
- All public APIs must be documented
- Unit tests required for new features
- >80% code coverage goal
- Protocol-based abstraction for testability
- MainActor isolation for UI state

## How to Use This Documentation

### Reading Paths

**Path 1: Quick Start (30 minutes)**
1. project-overview-pdr.md - Read sections: Vision, Phase Overview
2. codebase-summary.md - Read sections: Project Overview, Core Components

**Path 2: Architecture Deep Dive (1 hour)**
1. system-architecture.md - Read entire document
2. xpc-communication.md - Read sections: Architecture, Component Overview

**Path 3: Implementation Start (2 hours)**
1. code-standards.md - Read entire document
2. xpc-communication.md - Read: Detailed Component, Integration Patterns
3. codebase-summary.md - Read: Building & Running

**Path 4: Full Onboarding (3 hours)**
1. project-overview-pdr.md - Read entire document
2. codebase-summary.md - Read entire document
3. system-architecture.md - Read entire document
4. xpc-communication.md - Read entire document
5. code-standards.md - Reference as needed

### Searching Documentation

**By Topic**:
| Topic | File | Section |
|-------|------|---------|
| XPC Connection | xpc-communication.md | Connection Management |
| Error Handling | xpc-communication.md | Error Handling |
| Retry Logic | system-architecture.md | Auto-Reconnection Logic |
| Testing | code-standards.md | Testing Standards |
| Naming | code-standards.md | Swift Language Standards |
| Async/Await | code-standards.md | Concurrency Model |
| Protocol Design | code-standards.md | Protocol & Abstraction Standards |
| Performance | codebase-summary.md | Performance Characteristics |
| Security | project-overview-pdr.md | Security Requirements |
| Troubleshooting | xpc-communication.md | Troubleshooting |

### By Development Phase

**Phase 1 - Foundation (COMPLETED)**
- [x] Menu bar integration
- [x] USB keyboard detection
- [x] Basic authorization
- [x] Settings UI with localization

**Phase 2 - XPC Communication (COMPLETED)**
- [x] System architecture documented
- [x] Implementation complete and documented
- [x] Unit tests documented
- [x] Code standards established
- [x] Project planning documented

**Phase 3 - Touch ID + SMJobBless (COMPLETED)**
- [x] Touch ID/Face ID authentication implemented
- [x] SMJobBless helper installation
- [x] Authentication guide documented
- [x] Helper installation guide documented

**Phase 4 - CI/CD Integration & First Release (CURRENT)**
- [x] GitHub Actions release workflow
- [x] EdDSA-signed DMG releases
- [x] Sparkle auto-update framework integrated
- [x] GitHub Pages appcast deployment
- [x] Deployment guide documented
- [x] Release workflow documented
- [x] Sparkle integration documented
- [x] Version 1.1.2 released

**Phase 5 - Integration & Polish (PLANNED)**
- [ ] Integrate XPC with KeyboardManager
- [ ] End-to-end testing
- [ ] Performance optimization
- [ ] User-facing error messages
- See: project-overview-pdr.md → Phase 5

**Phase 6 - Additional Features (PLANNED)**
- [ ] Advanced keyboard configuration
- [ ] Multi-profile support
- [ ] See: project-overview-pdr.md → Phase 6

## Key Information Quick Reference

### Bundle Identifiers
- **Main App**: `com.hxd.ksapdismiss`
- **Helper Tool**: `com.hxd.ksapdismiss.helper`
- **Subsystem**: `com.hxd.ksapdismiss` (for logging)

### Current Versions
- **Helper Protocol Version**: 1.0.0
- **Swift Minimum**: 5.9
- **macOS Minimum**: 13.0 (Ventura)

### File Paths
- **Target Plist**: `/Library/Preferences/com.apple.keyboardtype.plist`
- **Helper Install**: `/Library/PrivilegedHelperTools/com.hxd.ksapdismiss.helper`
- **LaunchDaemon**: `Resources/com.hxd.ksapdismiss.helper.plist`

### Key Concepts
- **Keyboard Entry**: `["identifier": "VendorID-ProductID-0", "type": 40]`
- **Type Codes**: 40=ANSI, 41=ISO, 42=JIS
- **XPC**: Inter-process communication using Mach IPC
- **MainActor**: Swift concurrency actor for UI updates

## Common Tasks

### I want to...

**...understand the overall project**
→ Start with `project-overview-pdr.md`

**...learn the system architecture**
→ Read `system-architecture.md`

**...implement a new feature**
→ Follow code in `code-standards.md`, reference `xpc-communication.md`

**...add a helper operation**
→ See `xpc-communication.md` → "Helper Operations" section

**...debug connection issues**
→ See `xpc-communication.md` → "Troubleshooting" section

**...understand the codebase**
→ Read `codebase-summary.md`

**...set up development environment**
→ See `codebase-summary.md` → "Building & Running"

**...write tests**
→ See `code-standards.md` → "Testing Standards"

**...understand design decisions**
→ See `project-overview-pdr.md` → "Architecture Decisions"

## Document Maintenance

### Update Frequency
- **Code Standards**: Updated as standards evolve (quarterly)
- **Architecture**: Updated when design changes (as needed)
- **Implementation Guide**: Updated with each phase (per phase)
- **Project Overview**: Updated quarterly (quarterly review)
- **Codebase Summary**: Updated after major changes (per phase)

### Maintenance Responsibility
- **Project Overview**: Project lead/manager
- **Architecture**: Senior architect/technical lead
- **Implementation Guide**: Feature lead/implementer
- **Code Standards**: Team consensus/tech lead
- **Codebase Summary**: Documentation team

### How to Suggest Changes
1. Open issue on GitHub describing the documentation gap
2. Reference specific file and section
3. Explain the improvement needed
4. Submit PR with changes following the markdown format

## Related Documents

### Main Repository
- **README.md** - User-facing documentation
- **CLAUDE.md** - Development workflow and constraints
- **Package.swift** - Package definition and dependencies

### Workflow Documentation (`.claude/workflows/`)
- **primary-workflow.md** - Main development workflow
- **development-rules.md** - Development guidelines
- **documentation-management.md** - Doc management policy

## FAQ

**Q: Where do I start as a new developer?**
A: Follow the "New Team Members" reading path above (~85 minutes).

**Q: How is the project organized?**
A: See `codebase-summary.md` → "Directory Structure"

**Q: What's the current development phase?**
A: Phase 4 (CI/CD Integration & First Release) - IN PROGRESS
Completed: Phases 1-3
Next: Phase 5 (Integration & Polish)

**Q: How do I implement a new feature?**
A: See `code-standards.md` for standards, reference `xpc-communication.md` for patterns.

**Q: What are the testing requirements?**
A: See `code-standards.md` → "Testing Standards" section.

**Q: How do I debug XPC issues?**
A: See `xpc-communication.md` → "Troubleshooting" section.

**Q: Where are the API specifications?**
A: See `xpc-communication.md` → "HelperProtocol" section.

**Q: What are the performance targets?**
A: See `codebase-summary.md` → "Performance Characteristics"

**Q: What security considerations exist?**
A: See `project-overview-pdr.md` → "Security Requirements"

**Q: How do I release a new version?**
A: See `deployment-guide.md` → "Release Process" (6-phase workflow)

**Q: How does the GitHub Actions release workflow work?**
A: See `release-workflow.md` → "Workflow Details" (10-step technical guide)

**Q: How do auto-updates work?**
A: See `sparkle-integration.md` → "Update Checking" and "Update Flow"

**Q: How is the release signed?**
A: See `release-workflow.md` → "Step 7: Sign DMG with EdDSA" for workflow details
And `sparkle-integration.md` → "EdDSA Signature Details" for security details

**Q: What if a release has critical issues?**
A: See `deployment-guide.md` → "Rollback Procedure" for detailed steps

## Statistics

| Metric | Value |
|--------|-------|
| Total Documentation Files | 11 |
| Total Lines of Documentation | ~15,000+ |
| Total Size | ~350 KB |
| Code Examples | 50+ |
| Diagrams | 5+ |
| Sections | 120+ |
| Cross-references | 60+ |
| Phase 3 Additions | 3 new guides |
| Release Process Documentation | Complete |

## Contact & Support

**Questions about documentation?**
- Open issue on GitHub: https://github.com/xuandung38/ksap-dismiss/issues
- Email: me@hxd.vn

**Want to contribute?**
- See CONTRIBUTING.md (create if needed)
- Follow code-standards.md guidelines
- Submit PR with documentation improvements

## Document Metadata

- **Created**: 2026-01-04
- **Last Updated**: 2026-01-05
- **Version**: 2.0 (Phase 4 additions)
- **Status**: Complete (Phase 4 CI/CD)
- **Next Review**: 2026-02-05
- **Maintainer**: docs-manager
- **Archives**:
  - `/plans/reports/docs-manager-260104-1908-xpc-phase2.md` (Phase 2)
  - `/plans/reports/docs-manager-260105-0440-phase3-cicd.md` (Phase 3)

---

**Happy developing!** For detailed information on any topic, refer to the appropriate document using the Quick Navigation above.
