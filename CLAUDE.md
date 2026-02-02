# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Ansible playbook for replicating a complete macOS development environment on a new machine. Fork of geerlingguy/mac-dev-playbook with comprehensive automation for Homebrew, shell config, VS Code, Conda, and system preferences.

## Quick Start (New Mac)

```bash
# One-liner bootstrap
curl -fsSL https://raw.githubusercontent.com/mlira59/mac-dev-playbook/master/scripts/bootstrap.sh | bash

# Then:
cd ~/Development/GitHub/mac-dev-playbook
make vault-create   # Enter your passwords
make setup          # Full environment setup
```

## Essential Commands (Makefile)

```bash
make                 # Show help
make setup           # Run full playbook (prompts for sudo)
make setup-check     # Dry run to preview changes
make setup-tags TAGS="homebrew,dotfiles"  # Run specific tags

make export          # Export current config (Homebrew, VS Code, Conda, etc.)
make lint            # Run yamllint + ansible-lint

make test            # Full VM test cycle (create -> provision -> verify -> destroy)
make vm-create       # Start test VM
make vm-provision    # Run playbook on VM
make vm-ssh          # SSH into test VM

make vault-create    # Create encrypted secrets file
make vault-edit      # Edit secrets
```

## Architecture

### Configuration Cascade
`default.config.yml` → `config.yml` (user overrides) → `group_vars/all/vault.yml` (encrypted secrets)

### Playbook Execution Order (main.yml)
1. **Roles**: osx-command-line-tools → homebrew → dotfiles → mas → dock
2. **Tasks**: sudoers → terminal → osx → extra-packages → sublime-text → vscode → post-provision

### Key Directories
```
scripts/           # Export scripts (export-homebrew.sh, export-vscode.sh, etc.)
files/exports/     # Generated exports (Brewfile, VS Code extensions, Conda envs)
packer/            # macOS VM build with Parallels
vagrant/           # VM management for testing
group_vars/all/    # vars.yml (references) + vault.yml (encrypted secrets)
```

## Configuration Variables

| Variable | Purpose |
|----------|---------|
| `configure_*` | Boolean flags (dotfiles, terminal, osx, dock, vscode, sublime) |
| `homebrew_installed_packages` | CLI packages |
| `homebrew_cask_apps` | GUI applications |
| `vscode_extensions` | VS Code extensions to install |
| `post_provision_tasks` | Custom task files to run last |

## Secrets Management

Secrets are stored in `group_vars/all/vault.yml` (ansible-vault encrypted):
- `vault_ansible_become_password` - sudo password
- `vault_mas_email` / `vault_mas_password` - Mac App Store credentials

```bash
make vault-create   # Create and encrypt
make vault-edit     # Modify secrets
```

## Keeping Config in Sync

```bash
make export         # Capture current system config
git diff            # Review changes
git add . && git commit -m "Update config"
```

Exports captured:
- **Homebrew**: Brewfile + YAML snippet for config.yml
- **VS Code**: Extensions list + settings.json
- **Conda**: Environment YAML files
- **Emacs**: Package list from elpa/
- **macOS**: Key defaults (Finder, Dock, Trackpad)

## VM Testing (Parallels Pro)

```bash
make vm-build       # Build macOS VM with Packer (~30 min, one-time)
make test           # Full test cycle
```

The Packer template uses OCR-based boot automation to navigate macOS Setup Assistant.

## Tags

Available tags for `make setup-tags`:
- `homebrew`, `dotfiles`, `mas`, `dock`
- `terminal`, `osx`, `vscode`, `sublime-text`
- `extra-packages`, `sudoers`, `post`

## Linting

- **yamllint**: Line length 180 (warning), config in `.yamllint`
- **ansible-lint**: Skips `fqcn`, `name[missing]`, `no-changed-when` (see `.ansible-lint`)
