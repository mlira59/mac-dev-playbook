# Makefile for Mac Development Environment Playbook
# Orchestrates Ansible, Packer, and Vagrant for environment setup and testing

.PHONY: help setup setup-deps setup-quick setup-tags setup-check \
        export export-homebrew export-macos export-vscode export-conda export-emacs diff \
        lint syntax-check \
        test vm-init vm-build vm-create vm-destroy vm-provision vm-verify vm-ssh vm-status vm-halt vm-snapshot vm-restore \
        vault-create vault-edit vault-view vault-rekey \
        clean update-roles info

# Default target
.DEFAULT_GOAL := help

# Variables
ANSIBLE_PLAYBOOK := ansible-playbook
PACKER := packer
VAGRANT := vagrant
VAULT_FILE := group_vars/all/vault.yml
PACKER_DIR := packer
VAGRANT_DIR := vagrant
SCRIPTS_DIR := scripts

# Colors for output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

help: ## Show this help message
	@echo ""
	@echo "$(CYAN)Mac Development Playbook$(NC)"
	@echo "$(CYAN)========================$(NC)"
	@echo ""
	@echo "$(GREEN)Quick Start:$(NC)"
	@echo "  make setup      - Run full setup on current machine"
	@echo "  make export     - Export current configs to repo"
	@echo "  make test       - Run full VM test cycle"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  $(CYAN)%-18s$(NC) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""

# ============================================================================
# SETUP TARGETS
# ============================================================================

setup: setup-deps ## Run full playbook on current machine (prompts for sudo)
	@echo "$(GREEN)Running full development environment setup...$(NC)"
	@if [ -f $(VAULT_FILE) ]; then \
		$(ANSIBLE_PLAYBOOK) main.yml --ask-become-pass --ask-vault-pass; \
	else \
		$(ANSIBLE_PLAYBOOK) main.yml --ask-become-pass; \
	fi
	@echo "$(GREEN)Setup complete!$(NC)"

setup-deps: ## Install Ansible and role dependencies
	@echo "$(GREEN)Installing dependencies...$(NC)"
	@command -v ansible >/dev/null 2>&1 || { echo "Installing Ansible..."; pip3 install ansible; }
	ansible-galaxy install -r requirements.yml --force
	@echo "$(GREEN)Dependencies installed.$(NC)"

setup-quick: setup-deps ## Run setup without prompts (uses vault for sudo password)
	@if [ ! -f $(VAULT_FILE) ]; then \
		echo "$(YELLOW)Error: Vault file not found. Run 'make vault-create' first.$(NC)"; \
		exit 1; \
	fi
	$(ANSIBLE_PLAYBOOK) main.yml --ask-vault-pass

setup-tags: setup-deps ## Run specific tags (use TAGS="tag1,tag2")
	@if [ -z "$(TAGS)" ]; then \
		echo "$(YELLOW)Usage: make setup-tags TAGS='homebrew,dotfiles'$(NC)"; \
		echo ""; \
		echo "Available tags:"; \
		echo "  homebrew, dotfiles, mas, dock, terminal, osx,"; \
		echo "  extra-packages, sublime-text, sudoers, post"; \
		exit 1; \
	fi
	$(ANSIBLE_PLAYBOOK) main.yml --ask-become-pass --tags "$(TAGS)"

setup-check: setup-deps ## Dry run to preview changes
	@echo "$(GREEN)Running dry-run (check mode)...$(NC)"
	$(ANSIBLE_PLAYBOOK) main.yml --ask-become-pass --check --diff

# ============================================================================
# EXPORT TARGETS
# ============================================================================

export: ## Export all current configs to repository
	@echo "$(GREEN)Exporting current configuration...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/*.sh 2>/dev/null || true
	./$(SCRIPTS_DIR)/export-all.sh
	@echo ""
	@echo "$(GREEN)Export complete.$(NC) Review changes with: git diff"

export-homebrew: ## Export Homebrew packages only
	@chmod +x $(SCRIPTS_DIR)/export-homebrew.sh
	./$(SCRIPTS_DIR)/export-homebrew.sh

export-macos: ## Export macOS defaults only
	@chmod +x $(SCRIPTS_DIR)/export-macos-defaults.sh
	./$(SCRIPTS_DIR)/export-macos-defaults.sh

export-vscode: ## Export VS Code extensions and settings
	@chmod +x $(SCRIPTS_DIR)/export-vscode.sh
	./$(SCRIPTS_DIR)/export-vscode.sh

export-conda: ## Export Conda environments
	@chmod +x $(SCRIPTS_DIR)/export-conda.sh
	./$(SCRIPTS_DIR)/export-conda.sh

export-emacs: ## Export Emacs packages
	@chmod +x $(SCRIPTS_DIR)/export-emacs.sh
	./$(SCRIPTS_DIR)/export-emacs.sh

diff: ## Show configuration drift between system and repo
	@echo "$(GREEN)Checking for configuration drift...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/diff-config.sh 2>/dev/null && ./$(SCRIPTS_DIR)/diff-config.sh || \
		echo "$(YELLOW)diff-config.sh not found. Run 'make export' first to establish baseline.$(NC)"

# ============================================================================
# LINTING AND TESTING
# ============================================================================

lint: ## Run yamllint and ansible-lint
	@echo "$(GREEN)Running linters...$(NC)"
	yamllint .
	ansible-lint
	@echo "$(GREEN)Linting passed.$(NC)"

syntax-check: ## Check playbook syntax
	$(ANSIBLE_PLAYBOOK) main.yml --syntax-check

# ============================================================================
# VM TESTING (Parallels Pro)
# ============================================================================

test: vm-create vm-provision vm-verify vm-destroy ## Full test cycle: create -> provision -> verify -> destroy
	@echo "$(GREEN)Full test cycle completed successfully!$(NC)"

vm-init: ## Initialize Packer plugins
	@echo "$(GREEN)Initializing Packer plugins...$(NC)"
	@if [ ! -d $(PACKER_DIR) ]; then \
		echo "$(YELLOW)Packer directory not found. Creating...$(NC)"; \
		mkdir -p $(PACKER_DIR); \
	fi
	cd $(PACKER_DIR) && $(PACKER) init .
	@echo "$(GREEN)Packer plugins initialized.$(NC)"

vm-build: vm-init ## Build macOS test VM with Packer (takes ~30 min)
	@echo "$(GREEN)Building macOS test VM...$(NC)"
	@echo "$(YELLOW)This will take approximately 30 minutes.$(NC)"
	cd $(PACKER_DIR) && $(PACKER) build .
	@echo "$(GREEN)VM build complete.$(NC)"

vm-create: ## Create/start test VM from built image
	@echo "$(GREEN)Creating test VM...$(NC)"
	@if [ ! -d $(VAGRANT_DIR) ]; then \
		echo "$(YELLOW)Error: Vagrant directory not found.$(NC)"; \
		exit 1; \
	fi
	cd $(VAGRANT_DIR) && $(VAGRANT) up --provider parallels
	@echo "$(GREEN)Test VM created.$(NC)"

vm-destroy: ## Destroy test VM
	@echo "$(GREEN)Destroying test VM...$(NC)"
	cd $(VAGRANT_DIR) && $(VAGRANT) destroy -f 2>/dev/null || true
	@echo "$(GREEN)Test VM destroyed.$(NC)"

vm-provision: ## Run playbook on test VM
	@echo "$(GREEN)Provisioning test VM...$(NC)"
	@# Temporarily move vault to avoid auto-loading
	@if [ -f $(VAULT_FILE) ]; then mv $(VAULT_FILE) $(VAULT_FILE).bak; fi
	$(ANSIBLE_PLAYBOOK) vm-test.yml -i vm-test/inventory || (mv $(VAULT_FILE).bak $(VAULT_FILE) 2>/dev/null; exit 1)
	@if [ -f $(VAULT_FILE).bak ]; then mv $(VAULT_FILE).bak $(VAULT_FILE); fi
	@echo "$(GREEN)Provisioning complete.$(NC)"

vm-verify: ## Run verification tests on VM
	@echo "$(GREEN)Running verification tests...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/verify-vm.sh
	./$(SCRIPTS_DIR)/verify-vm.sh
	@echo "$(GREEN)Verification complete.$(NC)"

vm-ssh: ## SSH into test VM
	cd $(VAGRANT_DIR) && $(VAGRANT) ssh

vm-status: ## Show test VM status
	cd $(VAGRANT_DIR) && $(VAGRANT) status

vm-halt: ## Stop test VM (keep data)
	cd $(VAGRANT_DIR) && $(VAGRANT) halt

vm-snapshot: ## Create VM snapshot
	cd $(VAGRANT_DIR) && $(VAGRANT) snapshot save pre-provision

vm-restore: ## Restore VM snapshot
	cd $(VAGRANT_DIR) && $(VAGRANT) snapshot restore pre-provision

# ============================================================================
# SECRETS MANAGEMENT
# ============================================================================

vault-create: ## Create new encrypted secrets file
	@if [ -f $(VAULT_FILE) ]; then \
		echo "$(YELLOW)Vault file already exists. Use 'make vault-edit' to modify.$(NC)"; \
		echo "$(YELLOW)To start over: rm $(VAULT_FILE)$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Creating encrypted secrets file...$(NC)"
	@mkdir -p group_vars/all
	@echo ""
	@echo "You will be prompted to:"
	@echo "  1. Enter a vault password (remember this!)"
	@echo "  2. Edit the file to add your actual secrets"
	@echo ""
	ansible-vault create $(VAULT_FILE)
	@echo ""
	@echo "$(GREEN)Vault created successfully!$(NC)"
	@echo "Edit later with: make vault-edit"

vault-edit: ## Edit encrypted secrets file
	@if [ ! -f $(VAULT_FILE) ]; then \
		echo "$(YELLOW)Vault file not found. Run 'make vault-create' first.$(NC)"; \
		exit 1; \
	fi
	ansible-vault edit $(VAULT_FILE)

vault-view: ## View encrypted secrets file
	@if [ ! -f $(VAULT_FILE) ]; then \
		echo "$(YELLOW)Vault file not found.$(NC)"; \
		exit 1; \
	fi
	ansible-vault view $(VAULT_FILE)

vault-rekey: ## Change vault password
	@if [ ! -f $(VAULT_FILE) ]; then \
		echo "$(YELLOW)Vault file not found.$(NC)"; \
		exit 1; \
	fi
	ansible-vault rekey $(VAULT_FILE)

# ============================================================================
# MAINTENANCE
# ============================================================================

clean: ## Clean temporary files
	@echo "$(GREEN)Cleaning up...$(NC)"
	rm -rf *.retry
	rm -rf .vagrant
	rm -rf $(PACKER_DIR)/output-*
	rm -rf $(PACKER_DIR)/crash.log
	rm -rf $(VAGRANT_DIR)/.vagrant
	@echo "$(GREEN)Cleanup complete.$(NC)"

update-roles: ## Update Ansible roles to latest versions
	ansible-galaxy install -r requirements.yml --force

info: ## Show environment information
	@echo ""
	@echo "$(CYAN)Mac Development Playbook Info$(NC)"
	@echo "$(CYAN)==============================$(NC)"
	@echo ""
	@echo "Ansible version: $$(ansible --version 2>/dev/null | head -1 || echo 'Not installed')"
	@echo "Python version:  $$(python3 --version 2>/dev/null || echo 'Not installed')"
	@echo "Packer version:  $$(packer --version 2>/dev/null || echo 'Not installed')"
	@echo "Vagrant version: $$(vagrant --version 2>/dev/null || echo 'Not installed')"
	@echo ""
	@echo "$(GREEN)Configuration:$(NC)"
	@echo "  Vault file:  $(VAULT_FILE) $$(test -f $(VAULT_FILE) && echo '(exists)' || echo '(not created)')"
	@echo "  Config file: $$(test -f config.yml && echo 'config.yml (custom)' || echo 'default.config.yml')"
	@echo ""
