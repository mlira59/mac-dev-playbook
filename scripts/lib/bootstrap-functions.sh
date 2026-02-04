#!/bin/bash
# Shared bootstrap functions for mac-dev-playbook.
# Source this file from bootstrap.sh and install.sh.
#
# Usage:
#   source "$(dirname "$0")/lib/bootstrap-functions.sh"

# Colors (exported for scripts that source this file)
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
# shellcheck disable=SC2034
RED='\033[0;31m'
NC='\033[0m'

# Ensure Xcode Command Line Tools are installed.
# Returns 0 if already installed or installation completed.
# Exits with message if user interaction is required (fresh install dialog).
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

# Ensure Homebrew is installed and available in PATH.
ensure_homebrew() {
    echo "Checking Homebrew..."
    if command -v brew &>/dev/null; then
        echo -e "${GREEN}Homebrew: OK${NC}"
        return 0
    fi

    echo -e "${YELLOW}Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    echo -e "${GREEN}Homebrew: OK${NC}"
}

# Ensure Python 3 and Ansible are installed via Homebrew.
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

# Clone or update the playbook repository.
# Arguments:
#   $1 - target directory (default: ~/Development/GitHub/mac-dev-playbook)
#   $2 - git remote URL (default: https://github.com/mlira59/mac-dev-playbook.git)
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

# Install Ansible Galaxy role dependencies.
# Arguments:
#   $1 - path to requirements.yml (default: ./requirements.yml)
install_role_deps() {
    local requirements="${1:-requirements.yml}"
    echo "Installing Ansible roles..."
    ansible-galaxy install -r "$requirements" --force
}
