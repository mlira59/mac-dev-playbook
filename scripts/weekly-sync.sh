#!/bin/bash
# Unattended weekly sync: export system state, update config.yml,
# auto-commit to sync/weekly branch.
#
# Designed to run via launchd (see files/launchd/).
# Safety: uses trap to clean up on exit, never touches main/master branch.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SYNC_BRANCH="sync/weekly"
LOG_PREFIX="[weekly-sync]"

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    RED='\033[0;31m'
    NC='\033[0m'
else
    GREEN=''
    YELLOW=''
    RED=''
    NC=''
fi

log() { echo -e "${GREEN}${LOG_PREFIX}${NC} $*"; }
warn() { echo -e "${YELLOW}${LOG_PREFIX}${NC} $*"; }
err() { echo -e "${RED}${LOG_PREFIX}${NC} $*" >&2; }

# Track the original branch to restore on exit
ORIGINAL_BRANCH=""

cleanup() {
    local exit_code=$?
    if [ -n "$ORIGINAL_BRANCH" ]; then
        log "Restoring original branch: $ORIGINAL_BRANCH"
        cd "$REPO_DIR"
        git checkout "$ORIGINAL_BRANCH" 2>/dev/null || true
    fi
    if [ $exit_code -ne 0 ]; then
        err "Weekly sync failed with exit code $exit_code"
    fi
}
trap cleanup EXIT

cd "$REPO_DIR"

log "Starting weekly sync at $(date)"

# Ensure repo is clean before switching branches
if ! git diff --quiet || ! git diff --cached --quiet; then
    err "Working directory has uncommitted changes. Aborting."
    exit 1
fi

# Save current branch
ORIGINAL_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Create or switch to sync branch
if git show-ref --verify --quiet "refs/heads/${SYNC_BRANCH}"; then
    git checkout "$SYNC_BRANCH"
    # Rebase onto current main working branch to stay up to date
    git rebase "$ORIGINAL_BRANCH" || {
        warn "Rebase failed, resetting sync branch to $ORIGINAL_BRANCH"
        git rebase --abort 2>/dev/null || true
        git reset --hard "$ORIGINAL_BRANCH"
    }
else
    log "Creating sync branch: $SYNC_BRANCH"
    git checkout -b "$SYNC_BRANCH"
fi

# Run export and update config.yml (non-interactive)
log "Exporting system configuration..."
chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true
"$SCRIPT_DIR/export-all.sh" 2>&1 || warn "Export had warnings (continuing)"

log "Updating config.yml..."
python3 "$SCRIPT_DIR/update-config.py" --auto 2>&1 || warn "Config update had warnings (continuing)"

# Check if there are changes to commit
if git diff --quiet && git diff --cached --quiet; then
    log "No changes detected. Nothing to commit."
    exit 0
fi

# Commit changes
git add -A
git commit -m "chore(weekly): sync configuration $(date +%Y-%m-%d)

Automated weekly sync from: $(hostname)
Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

log "Changes committed to branch: $SYNC_BRANCH"
log "Review with: git log --oneline ${ORIGINAL_BRANCH}..${SYNC_BRANCH}"
log "Merge with: git checkout ${ORIGINAL_BRANCH} && git merge ${SYNC_BRANCH}"
log "Weekly sync complete."
