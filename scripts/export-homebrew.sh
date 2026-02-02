#!/bin/bash
# Export Homebrew packages to Brewfile and generate config lists

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
EXPORT_DIR="$REPO_DIR/files/exports"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

mkdir -p "$EXPORT_DIR"

echo "Generating Brewfile..."
brew bundle dump --file="$EXPORT_DIR/Brewfile" --force --describe

echo "Extracting package lists..."

# Extract formulae
echo "# Homebrew Formulae ($(date +%Y-%m-%d))" > "$EXPORT_DIR/homebrew-packages.txt"
brew list --formula >> "$EXPORT_DIR/homebrew-packages.txt"

# Extract casks
echo "# Homebrew Casks ($(date +%Y-%m-%d))" > "$EXPORT_DIR/homebrew-casks.txt"
brew list --cask >> "$EXPORT_DIR/homebrew-casks.txt"

# Extract taps
echo "# Homebrew Taps ($(date +%Y-%m-%d))" > "$EXPORT_DIR/homebrew-taps.txt"
brew tap >> "$EXPORT_DIR/homebrew-taps.txt"

# Generate YAML snippet for config.yml
echo "Generating YAML config snippet..."
cat > "$EXPORT_DIR/homebrew-config-snippet.yml" << 'HEADER'
# Generated from current Homebrew installation
# Copy relevant sections to config.yml

homebrew_installed_packages:
HEADER

brew list --formula | sort | sed 's/^/  - /' >> "$EXPORT_DIR/homebrew-config-snippet.yml"

echo "" >> "$EXPORT_DIR/homebrew-config-snippet.yml"
echo "homebrew_cask_apps:" >> "$EXPORT_DIR/homebrew-config-snippet.yml"
brew list --cask | sort | sed 's/^/  - /' >> "$EXPORT_DIR/homebrew-config-snippet.yml"

echo ""
echo -e "${GREEN}Homebrew export complete: $EXPORT_DIR/${NC}"
echo "  - Brewfile"
echo "  - homebrew-packages.txt ($(wc -l < "$EXPORT_DIR/homebrew-packages.txt" | tr -d ' ') lines)"
echo "  - homebrew-casks.txt ($(wc -l < "$EXPORT_DIR/homebrew-casks.txt" | tr -d ' ') lines)"
echo "  - homebrew-taps.txt"
echo "  - homebrew-config-snippet.yml"
