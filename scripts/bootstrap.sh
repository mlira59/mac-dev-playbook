#!/bin/bash
# Bootstrap script for new Mac setup
# Run this first:
#   curl -fsSL https://raw.githubusercontent.com/mlira59/mac-dev-playbook/master/scripts/bootstrap.sh | bash

set -e

echo ""
echo "=== Mac Development Environment Bootstrap ==="
echo ""

# Source shared bootstrap functions
# When run via curl|bash, the lib may not exist yet — inline the essentials
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)" && pwd 2>/dev/null)" || SCRIPT_DIR=""

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/lib/bootstrap-functions.sh" ]; then
    # shellcheck source=lib/bootstrap-functions.sh
    source "$SCRIPT_DIR/lib/bootstrap-functions.sh"
else
    # Inline fallbacks for curl|bash execution (repo not yet cloned)
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    NC='\033[0m'

    ensure_xcode() {
        echo "Checking Xcode Command Line Tools..."
        if xcode-select -p &>/dev/null; then
            echo -e "${GREEN}Xcode Command Line Tools: OK${NC}"
            return 0
        fi
        echo -e "${YELLOW}Installing Xcode Command Line Tools...${NC}"
        xcode-select --install
        echo ""
        echo -e "${YELLOW}Please complete the installation dialog, then run this script again.${NC}"
        exit 0
    }

    ensure_homebrew() {
        echo "Checking Homebrew..."
        if command -v brew &>/dev/null; then
            echo -e "${GREEN}Homebrew: OK${NC}"
            return 0
        fi
        echo -e "${YELLOW}Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        echo -e "${GREEN}Homebrew: OK${NC}"
    }

    ensure_ansible() {
        echo "Checking Ansible..."
        if command -v ansible &>/dev/null; then
            echo -e "${GREEN}Ansible: OK${NC}"
            return 0
        fi
        echo -e "${YELLOW}Installing Ansible...${NC}"
        brew install python3 ansible
        echo -e "${GREEN}Ansible: OK${NC}"
    }

    ensure_repo() {
        local repo_dir="${1:-$HOME/Development/GitHub/mac-dev-playbook}"
        local repo_url="${2:-https://github.com/mlira59/mac-dev-playbook.git}"
        echo "Setting up playbook repository..."
        if [ ! -d "$repo_dir" ]; then
            echo "Cloning mac-dev-playbook..."
            mkdir -p "$(dirname "$repo_dir")"
            git clone "$repo_url" "$repo_dir"
        else
            echo "Repository already exists at $repo_dir"
            echo "Pulling latest changes..."
            cd "$repo_dir" && git pull
        fi
    }

    install_role_deps() {
        local requirements="${1:-requirements.yml}"
        echo "Installing Ansible roles..."
        ansible-galaxy install -r "$requirements" --force
    }
fi

# Run bootstrap steps
ensure_xcode
ensure_homebrew
ensure_ansible

REPO_DIR="$HOME/Development/GitHub/mac-dev-playbook"
echo ""
ensure_repo "$REPO_DIR"
cd "$REPO_DIR"

echo ""
install_role_deps

echo ""
echo -e "${GREEN}=== Bootstrap Complete ===${NC}"
echo ""
echo "Next steps:"
echo ""
echo "  1. cd $REPO_DIR"
echo ""
echo "  2. Create your encrypted secrets file:"
echo "     make vault-create"
echo ""
echo "  3. Run the playbook:"
echo "     make setup"
echo ""
echo "Or for a quick start with just Homebrew packages:"
echo "     make setup-tags TAGS='homebrew'"
echo ""
