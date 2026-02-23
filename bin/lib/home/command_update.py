"""Update command — pull changes, install configuration, and update packages."""

# ============================================================
# Imports
# ============================================================

import os
import subprocess
from pathlib import Path

from .command_install import execute_install
from .command_pull import execute_pull
from .config import Config
from .output import print_header, print_success, print_warning


# ============================================================
# Entry Point
# ============================================================

def execute_update(config: Config) -> None:
    """
    Full system update.

    Steps:
    1. Pull latest changes from remote
    2. Install dotfiles, tools, and reload services
    3. Update Homebrew packages
    """
    execute_pull(config)
    execute_install(config)
    update_homebrew_packages()


# ============================================================
# Homebrew
# ============================================================

def update_homebrew_packages() -> None:
    """Update Homebrew packages if the installation is owned by the current user."""
    print_header("Updating Homebrew")

    # Locate Homebrew installation directory
    homebrew_dir = find_homebrew_directory()
    if not homebrew_dir:
        return

    # Verify ownership before modifying packages
    try:
        current_user = os.getlogin()
        homebrew_owner = homebrew_dir.owner()
    except Exception:
        print_warning("Skipping Homebrew update")
        return

    if homebrew_owner != current_user:
        print_warning(f"Skipping Homebrew update (directory not owned by {current_user})")
        return

    # Update, upgrade, and clean up
    subprocess.run(['brew', 'update'], check=True)
    subprocess.run(['brew', 'upgrade'], check=True)
    subprocess.run(['brew', 'cleanup'], check=True)

    print_success("Homebrew update complete")


def find_homebrew_directory() -> Path | None:
    """Return the Homebrew installation path, or None if not found."""
    for candidate in [Path('/opt/homebrew'), Path('/usr/local/Homebrew')]:
        if candidate.exists():
            return candidate
    return None
