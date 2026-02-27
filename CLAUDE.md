# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Ansible playbook for replicating a complete macOS development environment on a new machine. Fork of geerlingguy/mac-dev-playbook with added bidirectional config sync, VM testing infrastructure, weekly automation, and secrets management.

## Essential Commands

```bash
make setup                           # Run full playbook (prompts for sudo + vault)
make setup-check                     # Dry run (--check --diff)
make setup-tags TAGS="homebrew,dock" # Run specific tags only

make lint                            # yamllint + ansible-lint
make syntax-check                    # Ansible syntax validation

make export                          # Export current system state to files/exports/
make sync                            # Export + update config.yml + prompt to commit
make sync-auto                       # Same as sync, non-interactive

make test                            # Full VM cycle: create -> provision -> verify -> destroy
make vm-create                       # Start Parallels test VM via Vagrant
make vm-provision                    # Run vm-test.yml against test VM
make vm-ssh                          # SSH into test VM
make vm-destroy                      # Tear down test VM

make vault-create                    # Create ansible-vault encrypted secrets
make vault-edit                      # Edit encrypted secrets

make weekly-install                  # Install launchd job for Monday 9 AM auto-sync
make weekly-status                   # Check weekly sync job status and logs
```

## Architecture

### Configuration Cascade

Variables are loaded in this order (later wins):

1. `default.config.yml` — upstream defaults, committed to repo
2. `config.yml` — user overrides, committed to repo (loaded via `with_fileglob` so missing is OK)
3. `group_vars/all/vars.yml` — non-sensitive variable references (e.g., `ansible_become_password: "{{ vault_ansible_become_password | default(omit) }}"`)
4. `group_vars/all/vault.yml` — ansible-vault encrypted secrets (loaded via `with_fileglob` + `no_log`)

The `default(omit)` pattern in `vars.yml` allows the playbook to work without vault (for VM testing).

### Playbook Execution Order (main.yml)

Roles run first, then tasks:
1. `elliotweiser.osx-command-line-tools` → `geerlingguy.mac.homebrew` → `geerlingguy.dotfiles` → `geerlingguy.mac.mas` → `geerlingguy.mac.dock`
2. `tasks/sudoers.yml` → `terminal.yml` → `osx.yml` → `extra-packages.yml` → `sublime-text.yml` → `vscode.yml` → post-provision

Each role/task is gated by a `configure_*` boolean or `when:` condition. Tags: `homebrew`, `dotfiles`, `mas`, `dock`, `terminal`, `osx`, `extra-packages`, `sublime-text`, `sudoers`, `post`.

### Bidirectional Config Sync

The sync system captures current system state back into the repo:

- `scripts/export-*.sh` — individual exporters (Homebrew, VS Code, Conda, Emacs, macOS defaults) write to `files/exports/`
- `scripts/export-all.sh` — runs all exporters
- `scripts/update-config.py` — parses export files and patches `config.yml` in-place using `ruamel.yaml` (preserves comments/formatting). Supports `--dry-run`, `--auto`, `--section homebrew|vscode`
- `scripts/sync.sh` — orchestrates: export → update config.yml → show diff → prompt for commit. `--auto` flag skips prompts

### Weekly Automation

`scripts/weekly-sync.sh` runs via launchd (`files/launchd/com.mlira.mac-dev-playbook.sync.plist`):
- Commits to `sync/weekly` branch (never touches main working branch)
- Rebases sync branch onto current branch before syncing
- Logs to `/tmp/mac-dev-playbook-sync.{log,err}`

### VM Testing

Two playbooks exist:
- `main.yml` — production playbook for local machine
- `vm-test.yml` — simplified playbook for VM testing (skips MAS, overrides vault vars with empty defaults, bootstraps Xcode CLI tools via `raw:` module)

VM infrastructure uses Parallels + Vagrant (`vagrant/Vagrantfile`) with optional Packer builds (`packer/*.pkr.hcl`) for macOS VM images. During `make vm-provision`, the vault file is temporarily moved aside to avoid loading.

### External Roles

Defined in `requirements.yml`, installed via `make setup-deps` or `make update-roles`:
- `elliotweiser.osx-command-line-tools` — Xcode CLI tools
- `geerlingguy.dotfiles` — dotfile symlinks
- `geerlingguy.mac` (collection) — homebrew, mas, dock

## Linting

```bash
make lint   # Runs both yamllint and ansible-lint
```

- **yamllint**: Line length 180 (warning), config in `.yamllint`. Ignores `.github/workflows/stale.yml`
- **ansible-lint**: Skips `schema[meta]`, `role-name`, `experimental`, `fqcn`, `name[missing]`, `no-changed-when`, `risky-file-permissions` (see `.ansible-lint`)

## Key Variables

| Variable | Purpose |
|----------|---------|
| `configure_dotfiles/terminal/osx/dock/vscode/sublime/sudoers` | Boolean feature flags |
| `homebrew_installed_packages` / `homebrew_cask_apps` | Package lists |
| `dotfiles_repo` / `dotfiles_repo_version` | Dotfiles Git source (mlira59/dotfiles, branch `work`) |
| `post_provision_tasks` | Glob pattern for custom task files to run last |
| `vscode_extensions` / `vscode_copy_settings` | VS Code configuration |

## Secrets

Stored in `group_vars/all/vault.yml` (ansible-vault encrypted):
- `vault_ansible_become_password` — sudo password
- `vault_mas_email` / `vault_mas_password` — Mac App Store credentials
