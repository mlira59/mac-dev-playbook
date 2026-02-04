#!/usr/bin/env python3
"""Update config.yml with current system package state.

Uses ruamel.yaml to modify config.yml in-place while preserving
comments, formatting, and key order.

Usage:
    scripts/update-config.py                    # Interactive, all sections
    scripts/update-config.py --dry-run          # Preview changes only
    scripts/update-config.py --auto             # Apply without prompting
    scripts/update-config.py --section homebrew # Only homebrew packages
    scripts/update-config.py --section vscode   # Only VS Code extensions
"""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

try:
    from ruamel.yaml import YAML
except ImportError:
    print("ruamel.yaml not found. Installing...")
    subprocess.check_call(
        [sys.executable, "-m", "pip", "install", "--break-system-packages", "ruamel.yaml"],
        stdout=subprocess.DEVNULL,
    )
    from ruamel.yaml import YAML


def run_cmd(cmd: list[str]) -> list[str]:
    """Run a command and return sorted, non-empty output lines."""
    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, check=True, timeout=30
        )
        return sorted(
            line.strip() for line in result.stdout.splitlines() if line.strip()
        )
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        return []


def get_brew_formulae() -> list[str]:
    """Get installed Homebrew formulae using 'brew leaves'.

    Tapped packages already appear with full tap paths
    (e.g., 'code-hex/tap/neo-cowsay').
    """
    return run_cmd(["brew", "leaves"])


def get_brew_casks() -> list[str]:
    """Get installed Homebrew casks."""
    return run_cmd(["brew", "list", "--cask"])


def get_vscode_extensions() -> list[str]:
    """Get installed VS Code extensions."""
    return run_cmd(["code", "--list-extensions"])


def yaml_list_to_set(yaml_list) -> set[str]:
    """Convert a ruamel.yaml CommentedSeq to a Python set of strings."""
    if yaml_list is None:
        return set()
    return {str(item) for item in yaml_list}


def compute_diff(
    current_system: list[str],
    config_list,
    exclude_list=None,
) -> tuple[list[str], list[str]]:
    """Compute additions and removals between system state and config.

    Returns:
        (to_add, to_remove): packages to add/remove from config.
    """
    config_set = yaml_list_to_set(config_list)
    exclude_set = yaml_list_to_set(exclude_list)
    system_set = set(current_system)

    # Case-insensitive comparison for package names
    config_lower = {item.lower(): item for item in config_set}
    system_lower = {item.lower(): item for item in system_set}
    exclude_lower = {item.lower() for item in exclude_set}

    # Packages on system but not in config (and not excluded)
    to_add = sorted(
        system_lower[name]
        for name in system_lower
        if name not in config_lower and name not in exclude_lower
    )

    # Packages in config but not on system (and not excluded)
    to_remove = sorted(
        config_lower[name]
        for name in config_lower
        if name not in system_lower and name not in exclude_lower
    )

    return to_add, to_remove


def print_diff(section: str, to_add: list[str], to_remove: list[str]) -> None:
    """Print a human-readable diff for a config section."""
    if not to_add and not to_remove:
        print(f"  {section}: no changes")
        return

    print(f"  {section}:")
    for item in to_add:
        print(f"    + {item}")
    for item in to_remove:
        print(f"    - {item}")


def apply_changes(yaml_list, to_add: list[str], to_remove: list[str]) -> None:
    """Apply additions and removals to a ruamel.yaml CommentedSeq in-place."""
    # Remove items (case-insensitive match)
    remove_lower = {item.lower() for item in to_remove}
    indices_to_remove = [
        i for i, item in enumerate(yaml_list) if str(item).lower() in remove_lower
    ]
    for i in reversed(indices_to_remove):
        del yaml_list[i]

    # Add new items at the end, sorted
    for item in sorted(to_add):
        yaml_list.append(item)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Update config.yml with current system package state."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would change without modifying files.",
    )
    parser.add_argument(
        "--auto",
        action="store_true",
        help="Apply changes without prompting for confirmation.",
    )
    parser.add_argument(
        "--section",
        choices=["homebrew", "vscode", "all"],
        default="all",
        help="Which section(s) to update (default: all).",
    )
    parser.add_argument(
        "--config-path",
        type=Path,
        default=None,
        help="Path to config.yml (default: auto-detect relative to script).",
    )
    args = parser.parse_args()

    # Resolve config path
    if args.config_path:
        config_path = args.config_path.resolve()
    else:
        script_dir = Path(__file__).resolve().parent
        config_path = script_dir.parent / "config.yml"

    if not config_path.exists():
        print(f"Error: config file not found: {config_path}")
        return 1

    # Load config with ruamel.yaml (preserves comments and formatting)
    yaml = YAML()
    yaml.preserve_quotes = True
    yaml.width = 4096  # Prevent line wrapping
    config = yaml.load(config_path)

    has_changes = False

    # --- Homebrew formulae ---
    if args.section in ("homebrew", "all"):
        print("Scanning Homebrew formulae...")
        system_formulae = get_brew_formulae()
        if not system_formulae:
            print("  Warning: could not retrieve brew formulae (is brew installed?)")
        else:
            formula_add, formula_remove = compute_diff(
                system_formulae,
                config.get("homebrew_installed_packages"),
                config.get("homebrew_uninstalled_packages"),
            )
            print_diff("homebrew_installed_packages", formula_add, formula_remove)
            if formula_add or formula_remove:
                has_changes = True

        print("Scanning Homebrew casks...")
        system_casks = get_brew_casks()
        if not system_casks:
            print("  Warning: could not retrieve brew casks (is brew installed?)")
        else:
            cask_add, cask_remove = compute_diff(
                system_casks,
                config.get("homebrew_cask_apps"),
            )
            print_diff("homebrew_cask_apps", cask_add, cask_remove)
            if cask_add or cask_remove:
                has_changes = True

    # --- VS Code extensions ---
    if args.section in ("vscode", "all"):
        print("Scanning VS Code extensions...")
        system_extensions = get_vscode_extensions()
        if not system_extensions:
            print("  Warning: could not retrieve VS Code extensions (is code installed?)")
        else:
            ext_config = config.get("vscode_extensions")
            if ext_config is None:
                print("  vscode_extensions: not defined in config.yml, skipping")
            else:
                ext_add, ext_remove = compute_diff(
                    system_extensions,
                    ext_config,
                )
                print_diff("vscode_extensions", ext_add, ext_remove)
                if ext_add or ext_remove:
                    has_changes = True

    if not has_changes:
        print("\nNo changes detected.")
        return 0

    if args.dry_run:
        print("\n--dry-run: no files modified.")
        return 0

    # Prompt for confirmation unless --auto
    if not args.auto:
        try:
            response = input("\nApply these changes to config.yml? [y/N] ")
        except EOFError:
            response = "n"
        if response.lower() not in ("y", "yes"):
            print("Aborted.")
            return 0

    # Create backup
    backup_path = config_path.with_suffix(".yml.bak")
    shutil.copy2(config_path, backup_path)
    print(f"Backup created: {backup_path}")

    # Apply changes
    if args.section in ("homebrew", "all") and system_formulae:
        if formula_add or formula_remove:
            apply_changes(
                config["homebrew_installed_packages"], formula_add, formula_remove
            )
    if args.section in ("homebrew", "all") and system_casks:
        if cask_add or cask_remove:
            apply_changes(config["homebrew_cask_apps"], cask_add, cask_remove)
    if args.section in ("vscode", "all") and system_extensions:
        ext_config = config.get("vscode_extensions")
        if ext_config is not None and (ext_add or ext_remove):
            apply_changes(config["vscode_extensions"], ext_add, ext_remove)

    # Write back
    yaml.dump(config, config_path)
    print(f"Updated: {config_path}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
