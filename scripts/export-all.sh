#!/bin/bash
# Master export script - exports all current configurations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}=== Exporting Current Configuration ===${NC}"
echo ""

# Make all scripts executable
chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true

# Run each export script
echo -e "${GREEN}[1/5]${NC} Exporting Homebrew packages..."
"$SCRIPT_DIR/export-homebrew.sh"

echo ""
echo -e "${GREEN}[2/5]${NC} Exporting macOS defaults..."
"$SCRIPT_DIR/export-macos-defaults.sh"

echo ""
echo -e "${GREEN}[3/5]${NC} Exporting VS Code extensions..."
"$SCRIPT_DIR/export-vscode.sh"

echo ""
echo -e "${GREEN}[4/5]${NC} Exporting Conda environments..."
"$SCRIPT_DIR/export-conda.sh"

echo ""
echo -e "${GREEN}[5/5]${NC} Exporting Emacs packages..."
"$SCRIPT_DIR/export-emacs.sh"

echo ""
echo -e "${CYAN}=== Export Complete ===${NC}"
echo ""
echo "Exported files are in: $REPO_DIR/files/exports/"
echo ""
echo "Review changes:"
echo "  git status"
echo "  git diff"
echo ""
echo "To automatically update config.yml with new packages:"
echo "  make sync"
echo ""
