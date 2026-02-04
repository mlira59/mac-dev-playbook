#!/bin/bash
# Sync current system state into config.yml and export files.
#
# Flow: export -> update config.yml -> show diff -> prompt for commit
#
# Usage:
#   scripts/sync.sh           # Interactive sync
#   scripts/sync.sh --auto    # Non-interactive (for automation)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

AUTO_MODE=false
UPDATE_ARGS=()

for arg in "$@"; do
    case "$arg" in
        --auto)
            AUTO_MODE=true
            UPDATE_ARGS+=("--auto")
            ;;
    esac
done

echo ""
echo -e "${CYAN}=== Configuration Sync ===${NC}"
echo ""

# Step 1: Export current system state to files/exports/
echo -e "${GREEN}[1/4]${NC} Exporting current system configuration..."
chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true
"$SCRIPT_DIR/export-all.sh"

# Step 2: Update config.yml in-place
echo ""
echo -e "${GREEN}[2/4]${NC} Updating config.yml with system state..."
python3 "$SCRIPT_DIR/update-config.py" "${UPDATE_ARGS[@]}"

# Step 3: Show git diff
echo ""
echo -e "${GREEN}[3/4]${NC} Changes summary:"
cd "$REPO_DIR"
if git diff --quiet && git diff --cached --quiet; then
    echo "  No changes detected."
    echo ""
    echo -e "${CYAN}=== Sync Complete (nothing to do) ===${NC}"
    exit 0
fi

echo ""
git diff --stat
echo ""

# Step 4: Prompt for commit
if [ "$AUTO_MODE" = true ]; then
    echo -e "${GREEN}[4/4]${NC} Auto mode: skipping commit prompt."
    echo ""
    echo -e "${CYAN}=== Sync Complete ===${NC}"
    exit 0
fi

echo -e "${GREEN}[4/4]${NC} Commit changes?"
echo ""
echo "  Review full diff with: git diff"
echo ""
read -r -p "Commit these changes? [y/N] " response
if [[ "$response" =~ ^[Yy] ]]; then
    cd "$REPO_DIR"
    git add -A
    git commit -m "chore: sync configuration with current system state

Exported from: $(hostname)
Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""
    echo -e "${GREEN}Changes committed.${NC}"
else
    echo "Skipped. You can commit manually later."
fi

echo ""
echo -e "${CYAN}=== Sync Complete ===${NC}"
