#!/bin/bash
# Export Emacs package list from installed packages

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
EXPORT_DIR="$REPO_DIR/files/exports/emacs"
EMACS_DIR="$HOME/.emacs.d"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

mkdir -p "$EXPORT_DIR"

if [ ! -d "$EMACS_DIR" ]; then
    echo -e "${YELLOW}Emacs directory not found at $EMACS_DIR. Skipping.${NC}"
    exit 0
fi

echo "Exporting Emacs configuration..."

# Export list of installed packages from elpa/
if [ -d "$EMACS_DIR/elpa" ]; then
    echo "  Extracting installed packages from elpa/..."
    ls -1 "$EMACS_DIR/elpa" 2>/dev/null | \
        grep -v "archives" | \
        grep -v "gnupg" | \
        sed 's/-[0-9].*$//' | \
        sort -u > "$EXPORT_DIR/packages.txt"
fi

# Copy key config files if they exist
for file in init.el early-init.el custom.el; do
    if [ -f "$EMACS_DIR/$file" ]; then
        echo "  Copying $file..."
        cp "$EMACS_DIR/$file" "$EXPORT_DIR/"
    fi
done

# Check for use-package declarations in init files
if [ -f "$EMACS_DIR/init.el" ]; then
    echo "  Extracting use-package declarations..."
    (grep -h "use-package" "$EMACS_DIR/init.el" "$EMACS_DIR"/*.el 2>/dev/null || true) | \
        grep -oE '\(use-package [a-zA-Z0-9_-]+' | \
        sed 's/(use-package //' | \
        sort -u > "$EXPORT_DIR/use-packages.txt" 2>/dev/null || true
fi

# Create directory listing
echo "  Creating config inventory..."
find "$EMACS_DIR" -maxdepth 2 -type f -name "*.el" 2>/dev/null | sort > "$EXPORT_DIR/config-files.txt"

# Create summary
cat > "$EXPORT_DIR/README.md" << EOF
# Emacs Configuration Export

Generated: $(date +%Y-%m-%d)

## Files

- \`packages.txt\` - Installed packages from elpa directory
- \`use-packages.txt\` - Packages declared via use-package
- \`config-files.txt\` - List of .el configuration files
- \`init.el\` - Main init file (if present)
- \`early-init.el\` - Early init file (if present)

## Note

This is a simplified export. For full Emacs config replication, consider:
1. Using a dotfiles repo for your entire .emacs.d
2. Using Doom/Spacemacs which have built-in sync
3. Using straight.el with a lockfile
EOF

echo ""
echo -e "${GREEN}Emacs export complete: $EXPORT_DIR/${NC}"
[ -f "$EXPORT_DIR/packages.txt" ] && echo "  - packages.txt ($(wc -l < "$EXPORT_DIR/packages.txt" | tr -d ' ') packages)"
[ -f "$EXPORT_DIR/use-packages.txt" ] && [ -s "$EXPORT_DIR/use-packages.txt" ] && echo "  - use-packages.txt ($(wc -l < "$EXPORT_DIR/use-packages.txt" | tr -d ' ') declarations)"
[ -f "$EXPORT_DIR/init.el" ] && echo "  - init.el"
[ -f "$EXPORT_DIR/early-init.el" ] && echo "  - early-init.el"
