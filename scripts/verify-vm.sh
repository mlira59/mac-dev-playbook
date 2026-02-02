#!/bin/bash
# Verify VM configuration matches expectations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
INVENTORY="$REPO_DIR/vm-test/inventory"
VAULT_FILE="$REPO_DIR/group_vars/all/vault.yml"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}=== VM Configuration Verification ===${NC}"
echo ""

# Temporarily move vault to avoid loading issues
if [ -f "$VAULT_FILE" ]; then
    mv "$VAULT_FILE" "$VAULT_FILE.bak"
    trap "mv '$VAULT_FILE.bak' '$VAULT_FILE' 2>/dev/null" EXIT
fi

run_on_vm() {
    ansible -i "$INVENTORY" all -m raw -a "$1" 2>/dev/null | tail -n +2 | grep -v "^$"
}

check() {
    local name="$1"
    local cmd="$2"
    local expected="$3"

    result=$(run_on_vm "$cmd" 2>/dev/null | tr -d '[:space:]')

    if [ "$expected" = "exists" ]; then
        if [ -n "$result" ] && [ "$result" != "0" ]; then
            echo -e "  ${GREEN}✓${NC} $name"
            return 0
        else
            echo -e "  ${RED}✗${NC} $name"
            return 1
        fi
    elif [ "$result" = "$expected" ]; then
        echo -e "  ${GREEN}✓${NC} $name"
        return 0
    else
        echo -e "  ${RED}✗${NC} $name (got: $result, expected: $expected)"
        return 1
    fi
}

echo -e "${CYAN}Homebrew:${NC}"
check "Homebrew installed" "test -x /opt/homebrew/bin/brew && echo yes" "yes"
formula_count=$(run_on_vm "/opt/homebrew/bin/brew list --formula | wc -l" | tr -d '[:space:]')
echo -e "  ${GREEN}✓${NC} $formula_count formulae installed"

echo ""
echo -e "${CYAN}Key Packages:${NC}"
for pkg in git gh starship tmux fzf zoxide; do
    check "$pkg" "/opt/homebrew/bin/brew list $pkg >/dev/null 2>&1 && echo yes" "yes"
done

echo ""
echo -e "${CYAN}Shell Configuration:${NC}"
check ".zshrc exists" "test -f ~/.zshrc && echo yes" "yes"
check "Homebrew in PATH" "grep -q 'brew shellenv' ~/.zshrc && echo yes" "yes"
check "Starship configured" "grep -q 'starship init' ~/.zshrc && echo yes" "yes"

echo ""
echo -e "${CYAN}Directories:${NC}"
check "~/.config exists" "test -d ~/.config && echo yes" "yes"
check "~/.ssh exists" "test -d ~/.ssh && echo yes" "yes"
check "starship.toml exists" "test -f ~/.config/starship.toml && echo yes" "yes"

echo ""
echo -e "${CYAN}Xcode CLI Tools:${NC}"
check "xcode-select" "xcode-select -p >/dev/null 2>&1 && echo yes" "yes"

echo ""
echo -e "${CYAN}=== Verification Complete ===${NC}"
echo ""
