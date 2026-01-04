#!/bin/bash
# Release Preparation Script for KSAP Dismiss
# Validates environment and provides setup instructions for GitHub Actions release workflow

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "======================================"
echo "KSAP Dismiss - Release Preparation"
echo "======================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ "$1" = "ok" ]; then
        echo -e "${GREEN}✓${NC} $2"
    elif [ "$1" = "warning" ]; then
        echo -e "${YELLOW}⚠${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

# Function to print section
print_section() {
    echo ""
    echo "========================================="
    echo "$1"
    echo "========================================="
    echo ""
}

# 1. Check EdDSA Key Pair
print_section "1. EdDSA Key Pair Validation"

PUBLIC_KEY=$(/usr/libexec/PlistBuddy -c "Print :SUPublicEDKey" "$PROJECT_ROOT/KSAPDismiss/Info.plist" 2>/dev/null || echo "")
PRIVATE_KEY=$(security find-generic-password -a "ed25519" -s "https://sparkle-project.org" -w 2>/dev/null || echo "")

if [ -n "$PUBLIC_KEY" ] && [ -n "$PRIVATE_KEY" ]; then
    print_status "ok" "EdDSA key pair found"
    echo "   Public key: ${PUBLIC_KEY:0:20}..."
    echo "   Private key: ${PRIVATE_KEY:0:8}... (hidden)"

    # Validate key length
    PRIVATE_LENGTH=${#PRIVATE_KEY}
    if [ "$PRIVATE_LENGTH" -eq 44 ]; then
        print_status "ok" "Private key length valid (44 chars)"
    else
        print_status "error" "Private key length invalid (expected 44, got $PRIVATE_LENGTH)"
    fi
else
    print_status "error" "EdDSA key pair not found"
    echo ""
    echo "Please run Phase 1 setup first:"
    echo "  cd bin/"
    echo "  ./generate_keys"
    exit 1
fi

# 2. Check GitHub Secrets Setup
print_section "2. GitHub Secrets Configuration"

echo "To enable automated releases, configure GitHub repository secrets:"
echo ""
echo "Required secret:"
echo "  SPARKLE_PRIVATE_KEY"
echo ""
echo "Steps to add secret:"
echo "  1. Go to: https://github.com/xuandung38/ksap-dismiss/settings/secrets/actions"
echo "  2. Click 'New repository secret'"
echo "  3. Name: SPARKLE_PRIVATE_KEY"
echo "  4. Value: Copy the private key below"
echo ""
echo "===== PRIVATE KEY (copy this) ====="
echo "$PRIVATE_KEY"
echo "===================================="
echo ""

read -p "Have you added SPARKLE_PRIVATE_KEY to GitHub Secrets? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "warning" "Please add the secret before creating a release"
    echo ""
else
    print_status "ok" "GitHub Secrets configured"
    echo ""
fi

# 3. Check GitHub Pages Setup
print_section "3. GitHub Pages Validation"

echo "GitHub Pages must be enabled to serve appcast.xml"
echo ""
echo "Steps to enable:"
echo "  1. Go to: https://github.com/xuandung38/ksap-dismiss/settings/pages"
echo "  2. Source: Deploy from a branch"
echo "  3. Branch: gh-pages / (root)"
echo "  4. Click Save"
echo ""

read -p "Is GitHub Pages configured? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "ok" "GitHub Pages configured"

    # Test appcast.xml accessibility
    echo ""
    echo "Testing appcast.xml accessibility..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://xuandung38.github.io/ksap-dismiss/appcast.xml" 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "200" ]; then
        print_status "ok" "appcast.xml is accessible (HTTP 200)"
    elif [ "$HTTP_CODE" = "404" ]; then
        print_status "warning" "appcast.xml not found yet (will be created on first release)"
    else
        print_status "warning" "Cannot reach GitHub Pages (HTTP $HTTP_CODE)"
    fi
else
    print_status "warning" "Please enable GitHub Pages before creating a release"
fi

# 4. Check Version Consistency
print_section "4. Version Consistency Check"

PLIST_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PROJECT_ROOT/KSAPDismiss/Info.plist")
CHANGELOG_VERSION=$(grep -m 1 "^\[" "$PROJECT_ROOT/CHANGELOG.md" | grep -v "Unreleased" | sed 's/\[//;s/\].*//' || echo "")

echo "Info.plist version: $PLIST_VERSION"
echo "Latest CHANGELOG version: $CHANGELOG_VERSION"
echo ""

if [ "$PLIST_VERSION" = "$CHANGELOG_VERSION" ]; then
    print_status "ok" "Versions match"
else
    print_status "warning" "Versions don't match - update CHANGELOG.md before release"
fi

# 5. Check Dependencies
print_section "5. Dependencies Check"

# Check for create-dmg
if command -v create-dmg &> /dev/null; then
    print_status "ok" "create-dmg installed"
else
    print_status "warning" "create-dmg not installed (GitHub Actions will install it)"
    echo "   To install locally: brew install create-dmg"
fi

# Check for swift
if command -v swift &> /dev/null; then
    SWIFT_VERSION=$(swift --version | head -1)
    print_status "ok" "Swift installed: $SWIFT_VERSION"
else
    print_status "error" "Swift not found"
fi

# 6. Build Test
print_section "6. Build Test"

echo "Testing release build..."
cd "$PROJECT_ROOT"

if swift build -c release &> /dev/null; then
    print_status "ok" "Release build successful"

    # Check binary size
    BINARY_PATH=".build/release/KSAPDismiss"
    if [ -f "$BINARY_PATH" ]; then
        BINARY_SIZE=$(ls -lh "$BINARY_PATH" | awk '{print $5}')
        echo "   Binary size: $BINARY_SIZE"
    fi
else
    print_status "error" "Release build failed"
    echo ""
    echo "Run 'swift build -c release' to see errors"
    exit 1
fi

# 7. Test Suite
print_section "7. Test Suite"

echo "Running tests..."
if swift test &> /dev/null; then
    TEST_COUNT=$(swift test 2>&1 | grep "Executed.*tests" | tail -1 | awk '{print $2}')
    print_status "ok" "All tests passed ($TEST_COUNT tests)"
else
    print_status "error" "Tests failed"
    echo ""
    echo "Run 'swift test' to see errors"
    exit 1
fi

# 8. Next Steps
print_section "8. Next Steps - Creating a Release"

echo "To create a release, follow these steps:"
echo ""
echo "1. Ensure all checks above passed"
echo ""
echo "2. Update CHANGELOG.md:"
echo "   - Move items from [Unreleased] to [X.Y.Z] section"
echo "   - Add release date"
echo ""
echo "3. Update version in Info.plist:"
echo "   /usr/libexec/PlistBuddy -c \"Set :CFBundleShortVersionString X.Y.Z\" KSAPDismiss/Info.plist"
echo ""
echo "4. Commit changes:"
echo "   git add ."
echo "   git commit -m \"chore: bump version to vX.Y.Z\""
echo ""
echo "5. Create and push tag:"
echo "   git tag -a vX.Y.Z -m \"Release vX.Y.Z\""
echo "   git push origin main"
echo "   git push origin vX.Y.Z"
echo ""
echo "6. GitHub Actions will automatically:"
echo "   - Build the app"
echo "   - Create DMG"
echo "   - Sign with EdDSA"
echo "   - Generate appcast.xml"
echo "   - Deploy to GitHub Pages"
echo "   - Create GitHub Release"
echo ""
echo "7. Monitor workflow:"
echo "   https://github.com/xuandung38/ksap-dismiss/actions"
echo ""

# Summary
print_section "Summary"

if [ -n "$PRIVATE_KEY" ] && [ "$PLIST_VERSION" = "$CHANGELOG_VERSION" ]; then
    print_status "ok" "All critical checks passed - ready for release!"
else
    print_status "warning" "Some checks require attention before release"
fi

echo ""
echo "======================================"
echo "Release Preparation Complete"
echo "======================================"
