# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Bidirectional Config Sync**: `scripts/update-config.py` uses ruamel.yaml to update `config.yml`
  in-place from system state (`brew leaves`, `brew list --cask`, `code --list-extensions`) while
  preserving comments and formatting. Supports `--dry-run`, `--auto`, `--section`, `--config-path`
- **Sync Workflow**: `scripts/sync.sh` orchestrates export -> config update -> diff -> commit prompt.
  Makefile targets: `sync` (interactive) and `sync-auto` (non-interactive)
- **Self-Bootstrapping Install**: `scripts/install.sh` provides full from-scratch setup (bootstrap
  prerequisites + role deps + playbook run). Makefile targets: `install` and `install-noninteractive`
- **Shared Bootstrap Library**: `scripts/lib/bootstrap-functions.sh` extracts reusable functions
  (`ensure_xcode`, `ensure_homebrew`, `ensure_ansible`, `ensure_repo`, `install_role_deps`)
- **VM Bootstrap Testing**: `scripts/vm-bootstrap-test.sh` copies repo to VM via rsync and runs
  full install over SSH. Makefile targets: `vm-provision-bootstrap`, `test-bootstrap`
- **Sync + Test Pipeline**: `sync-test` Makefile target chains sync -> VM destroy -> create ->
  provision -> verify for end-to-end validation
- **Weekly Automation**: `scripts/weekly-sync.sh` runs unattended sync to `sync/weekly` branch with
  safety trap. `files/launchd/com.mlira.mac-dev-playbook.sync.plist` schedules Mondays at 9 AM.
  Makefile targets: `weekly-install`, `weekly-uninstall`, `weekly-status`

### Changed
- Refactored `scripts/bootstrap.sh` to source shared `lib/bootstrap-functions.sh` with inline
  fallbacks for `curl|bash` execution (when lib hasn't been cloned yet)
- Updated `scripts/export-all.sh` to point to `make sync` instead of manual copy-paste instructions

- **VM Testing Infrastructure**: Complete Packer and Vagrant setup for automated testing
  - `packer/` directory with macOS VM build configuration using Parallels
  - `vagrant/` directory for VM management
  - `vm-test/` directory with test inventory and configuration
  - `vm-test.yml` playbook for testing on fresh macOS VMs
  - `Makefile` with targets: `vm-create`, `vm-provision`, `vm-verify`, `vm-destroy`, `test`
- **Additional Configuration Task Files**:
  - `starship.yml` - Starship prompt configuration with Homebrew PATH setup
  - `zshrc.yml` - Base zsh configuration
  - `zshrc_ansible.yml` - Ansible virtual environment activation (with existence check)
  - `zsh_plugins.yml` - Zsh plugin management
  - `ssh.yml` - SSH directory and configuration setup
  - `systemsetup.yml` - macOS system preferences
  - `root_user.yml` - Root user configuration
  - `miniconda.yml` - Miniconda/Miniforge installation and environment setup
  - `anaconda.yml` - Anaconda configuration (optional)
  - `spyder.yml` - Spyder IDE setup (optional)
  - `python39.yml` - Python 3.9 maintenance
  - `assorted_tasks.yml` - Miscellaneous macOS configuration tasks
  - `tmux.yml` - Tmux configuration
  - `vagrant.yml` - Vagrant user setup for VMs
- **VS Code Support**: Added `tasks/vscode.yml` and `configure_vscode` option
- **Scripts Directory**:
  - `scripts/bootstrap.sh` - One-liner bootstrap for new Macs
  - `scripts/verify-vm.sh` - Automated VM verification script
  - `scripts/export-*.sh` - Configuration export scripts
- **Documentation**: Added `CLAUDE.md` with comprehensive project documentation
- **Vault Support**: Group variables structure with `group_vars/all/vars.yml` and vault integration
- **Secrets Example**: `secrets.yml.example` template for vault configuration

### Changed
- Updated `.gitignore` to exclude vault files, Packer output, Vagrant state, and exports
- Enhanced `.yamllint` with additional rules for comments, braces, and octal values
- Updated `ansible.cfg` to use default stdout callback (yaml callback incompatible with Python 3.14)
- Changed `dotfiles_repo_version` from `work` to `master` in `default.config.yml`
- Updated `main.yml` to include group variables and vault secrets

### Fixed
- Fixed `zshrc_ansible.yml` to check if ansible venv exists before sourcing
- Fixed `starship.yml` to add Homebrew PATH before starship initialization
- Fixed `vagrant.yml` conditional to handle NoneType from regex_search
- Fixed various yamllint errors (trailing spaces, missing newlines, octal values)
