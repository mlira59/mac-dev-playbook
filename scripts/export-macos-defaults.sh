#!/bin/bash
# Export macOS defaults that differ from stock installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
EXPORT_DIR="$REPO_DIR/files/exports"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

mkdir -p "$EXPORT_DIR/macos"

echo "Exporting macOS defaults..."

# Key domains to export
DOMAINS=(
    "com.apple.Terminal"
    "com.apple.finder"
    "com.apple.dock"
    "com.apple.Safari"
    "com.apple.screensaver"
    "com.apple.desktopservices"
    "com.apple.screencapture"
    "com.apple.AppleMultitouchTrackpad"
    "com.apple.driver.AppleBluetoothMultitouch.trackpad"
    "NSGlobalDomain"
)

# Export as readable text
cat > "$EXPORT_DIR/macos/defaults-summary.txt" << EOF
# macOS Defaults Export
# Generated: $(date +%Y-%m-%d)
#
# These are key system preferences. To apply them, use:
#   defaults write <domain> <key> <value>
#
# Or use the .osx script in your dotfiles repo.

EOF

for domain in "${DOMAINS[@]}"; do
    echo "  Exporting: $domain"
    echo "" >> "$EXPORT_DIR/macos/defaults-summary.txt"
    echo "=== $domain ===" >> "$EXPORT_DIR/macos/defaults-summary.txt"
    defaults read "$domain" 2>/dev/null >> "$EXPORT_DIR/macos/defaults-summary.txt" || echo "(empty or not found)" >> "$EXPORT_DIR/macos/defaults-summary.txt"
done

# Export full global domain as plist for programmatic use
echo "  Exporting full global domain as plist..."
defaults export NSGlobalDomain "$EXPORT_DIR/macos/NSGlobalDomain.plist" 2>/dev/null || true

# Export Dock plist
echo "  Exporting Dock settings..."
defaults export com.apple.dock "$EXPORT_DIR/macos/com.apple.dock.plist" 2>/dev/null || true

# Export Finder plist
echo "  Exporting Finder settings..."
defaults export com.apple.finder "$EXPORT_DIR/macos/com.apple.finder.plist" 2>/dev/null || true

# Create a summary of key settings people typically customize
cat > "$EXPORT_DIR/macos/key-settings.txt" << 'EOF'
# Key macOS Settings Quick Reference
# These are commonly customized settings

# Finder: Show hidden files
defaults read com.apple.finder AppleShowAllFiles 2>/dev/null || echo "false (default)"

# Finder: Show all filename extensions
defaults read NSGlobalDomain AppleShowAllExtensions 2>/dev/null || echo "false (default)"

# Dock: Auto-hide
defaults read com.apple.dock autohide 2>/dev/null || echo "false (default)"

# Dock: Icon size
defaults read com.apple.dock tilesize 2>/dev/null || echo "64 (default)"

# Trackpad: Tap to click
defaults read com.apple.AppleMultitouchTrackpad Clicking 2>/dev/null || echo "false (default)"

# Screenshots: Save location
defaults read com.apple.screencapture location 2>/dev/null || echo "~/Desktop (default)"

# Screenshots: Format
defaults read com.apple.screencapture type 2>/dev/null || echo "png (default)"
EOF

# Run the key settings check
echo "  Checking key settings..."
{
    echo ""
    echo "=== Current Values ==="
    echo ""
    echo "Finder - Show hidden files: $(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null || echo 'false')"
    echo "Finder - Show extensions: $(defaults read NSGlobalDomain AppleShowAllExtensions 2>/dev/null || echo 'false')"
    echo "Dock - Auto-hide: $(defaults read com.apple.dock autohide 2>/dev/null || echo 'false')"
    echo "Dock - Icon size: $(defaults read com.apple.dock tilesize 2>/dev/null || echo '64')"
    echo "Trackpad - Tap to click: $(defaults read com.apple.AppleMultitouchTrackpad Clicking 2>/dev/null || echo 'false')"
    echo "Screenshots - Location: $(defaults read com.apple.screencapture location 2>/dev/null || echo '~/Desktop')"
    echo "Screenshots - Format: $(defaults read com.apple.screencapture type 2>/dev/null || echo 'png')"
} >> "$EXPORT_DIR/macos/key-settings.txt"

echo ""
echo -e "${GREEN}macOS defaults export complete: $EXPORT_DIR/macos/${NC}"
echo "  - defaults-summary.txt"
echo "  - key-settings.txt"
echo "  - NSGlobalDomain.plist"
echo "  - com.apple.dock.plist"
echo "  - com.apple.finder.plist"
