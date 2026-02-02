#!/bin/bash
# Bootstrap script for new Mac setup
# Run this first:
#   curl -fsSL https://raw.githubusercontent.com/mlira59/mac-dev-playbook/master/scripts/bootstrap.sh | bash

set -e

echo ""
echo "=== Mac Development Environment Bootstrap ==="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check for Command Line Tools
echo "Checking Xcode Command Line Tools..."
if ! xcode-select -p &> /dev/null; then
    echo -e "${YELLOW}Installing Xcode Command Line Tools...${NC}"
    xcode-select --install
    echo ""
    echo -e "${YELLOW}Please complete the installation dialog, then run this script again.${NC}"
    exit 0
fi
echo -e "${GREEN}Xcode Command Line Tools: OK${NC}"

# Check for Homebrew
echo "Checking Homebrew..."
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi
echo -e "${GREEN}Homebrew: OK${NC}"

# Install Python and Ansible
echo "Checking Ansible..."
if ! command -v ansible &> /dev/null; then
    echo -e "${YELLOW}Installing Ansible...${NC}"
    brew install python3 ansible
fi
echo -e "${GREEN}Ansible: OK${NC}"

# Clone the playbook repository
REPO_DIR="$HOME/Development/GitHub/mac-dev-playbook"
echo ""
echo "Setting up playbook repository..."

if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning mac-dev-playbook..."
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone https://github.com/mlira59/mac-dev-playbook.git "$REPO_DIR"
else
    echo "Repository already exists at $REPO_DIR"
    echo "Pulling latest changes..."
    cd "$REPO_DIR" && git pull
fi

cd "$REPO_DIR"

# Install Ansible dependencies
echo ""
echo "Installing Ansible roles..."
ansible-galaxy install -r requirements.yml

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
