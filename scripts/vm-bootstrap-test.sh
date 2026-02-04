#!/bin/bash
# Test the full bootstrap flow on a test VM.
#
# Copies the repo to the VM via rsync, then runs 'make install-noninteractive'
# over SSH. Requires:
#   - Test VM running (make vm-create)
#   - sshpass installed (brew install sshpass or hudochenkov/sshpass/sshpass)
#
# Usage:
#   scripts/vm-bootstrap-test.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# VM connection details (match vagrant/inventory)
VM_HOST="10.211.55.26"
VM_USER="testuser"
VM_PASS="testpass"
VM_REPO_DIR="/Users/${VM_USER}/Development/GitHub/mac-dev-playbook"

SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)

echo ""
echo -e "${CYAN}=== VM Bootstrap Test ===${NC}"
echo ""

# Check prerequisites
if ! command -v sshpass &>/dev/null; then
    echo -e "${RED}Error: sshpass is required but not installed.${NC}"
    echo "Install with: brew install hudochenkov/sshpass/sshpass"
    exit 1
fi

# Verify VM is reachable
echo "Checking VM connectivity..."
if ! sshpass -p "$VM_PASS" ssh "${SSH_OPTS[@]}" "${VM_USER}@${VM_HOST}" "echo ok" &>/dev/null; then
    echo -e "${RED}Error: Cannot connect to VM at ${VM_HOST}.${NC}"
    echo "Start the VM with: make vm-create"
    exit 1
fi
echo -e "${GREEN}VM is reachable.${NC}"

# Create target directory on VM
echo "Preparing VM directory..."
sshpass -p "$VM_PASS" ssh "${SSH_OPTS[@]}" "${VM_USER}@${VM_HOST}" \
    "mkdir -p '$VM_REPO_DIR'"

# Sync repo to VM (exclude .git, .vagrant, packer output, etc.)
echo "Syncing repository to VM..."
sshpass -p "$VM_PASS" rsync -az --delete \
    --exclude '.git/' \
    --exclude '.vagrant/' \
    --exclude 'packer/output-*' \
    --exclude '*.retry' \
    --exclude 'config.yml.bak' \
    --exclude 'group_vars/all/vault.yml' \
    -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR" \
    "$REPO_DIR/" "${VM_USER}@${VM_HOST}:${VM_REPO_DIR}/"

echo -e "${GREEN}Sync complete.${NC}"

# Run install on VM
echo ""
echo -e "${CYAN}Running bootstrap install on VM...${NC}"
echo ""

sshpass -p "$VM_PASS" ssh "${SSH_OPTS[@]}" "${VM_USER}@${VM_HOST}" \
    "cd '$VM_REPO_DIR' && make install-noninteractive"

echo ""
echo -e "${GREEN}=== VM Bootstrap Test Complete ===${NC}"
