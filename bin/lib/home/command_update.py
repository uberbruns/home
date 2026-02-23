"""Update command implementation."""

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
    """Pull changes, install dotfiles and tools, and update Homebrew."""
    execute_pull(config)
    execute_install(config)
    update_homebrew_packages()


# ============================================================
# Homebrew Updates
# ============================================================

def update_homebrew_packages() -> None:
    """Update Homebrew packages if owned by current user."""
    print_header("Updating Homebrew")

    # Locate Homebrew installation directory
    homebrew_dir = None
    if Path('/opt/homebrew').exists():
        homebrew_dir = Path('/opt/homebrew')
    elif Path('/usr/local/Homebrew').exists():
        homebrew_dir = Path('/usr/local/Homebrew')

    if not homebrew_dir:
        return

    # Update Homebrew if owned by current user
    try:
        # Check directory ownership
        homebrew_owner = homebrew_dir.owner()
        current_user = os.getlogin()

        if homebrew_owner == current_user:
            # Execute Homebrew update commands
            subprocess.run(['brew', 'update'], check=True)
            subprocess.run(['brew', 'upgrade'], check=True)
            subprocess.run(['brew', 'cleanup'], check=True)

            # Print success message
            print_success("Homebrew update complete")
        else:
            # Print warning for non-owned directory
            print_warning(f"Skipping Homebrew update (directory not owned by {current_user})")
    except Exception:
        # Handle any errors during update
        print_warning("Skipping Homebrew update")

