#!/bin/bash
# Full from-scratch install: bootstrap + role deps + playbook run.
#
# Usage:
#   scripts/install.sh                    # Interactive (prompts for passwords)
#   scripts/install.sh --noninteractive   # For VMs/CI (uses vault file or env vars)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Source shared bootstrap functions
# shellcheck source=lib/bootstrap-functions.sh
source "$SCRIPT_DIR/lib/bootstrap-functions.sh"

NONINTERACTIVE=false
for arg in "$@"; do
    case "$arg" in
        --noninteractive)
            NONINTERACTIVE=true
            ;;
    esac
done

echo ""
echo "=== Mac Development Environment Full Install ==="
echo ""

# Step 1: Bootstrap prerequisites
ensure_xcode
ensure_homebrew
ensure_ansible

# Step 2: Install role dependencies
cd "$REPO_DIR"
echo ""
install_role_deps "$REPO_DIR/requirements.yml"

# Step 3: Run the playbook
echo ""
echo -e "${GREEN}Running playbook...${NC}"
cd "$REPO_DIR"

VAULT_FILE="$REPO_DIR/group_vars/all/vault.yml"

if [ "$NONINTERACTIVE" = true ]; then
    # Non-interactive: expect ansible_become_password via inventory or env
    if [ -f "$VAULT_FILE" ]; then
        ansible-playbook main.yml --ask-vault-pass
    else
        ansible-playbook main.yml
    fi
else
    # Interactive: prompt for sudo and vault passwords
    if [ -f "$VAULT_FILE" ]; then
        ansible-playbook main.yml --ask-become-pass --ask-vault-pass
    else
        ansible-playbook main.yml --ask-become-pass
    fi
fi

echo ""
echo -e "${GREEN}=== Install Complete ===${NC}"
echo ""
