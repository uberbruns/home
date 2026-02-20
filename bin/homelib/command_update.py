"""Update command implementation."""

# ============================================================
# Imports
# ============================================================

import os
import subprocess
from pathlib import Path

from .command_pull import execute_pull
from .config import Config
from .output import print_header, print_success, print_warning


# ============================================================
# Entry Point
# ============================================================

def execute_update(config: Config) -> None:
    """Pull changes, update development tools, and reload shell."""
    # Pull latest changes from remote
    execute_pull(config)

    # Update development tools
    install_mise_tools()
    update_homebrew_packages()

    # Reload shell
    reload_fish_shell()


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


# ============================================================
# Mise Updates
# ============================================================

def install_mise_tools() -> None:
    """Install and update mise-managed tools."""
    print_header("Installing tools")

    # Trust mise configuration files
    subprocess.run(['mise', 'trust', '--yes', '--silent', '--all'], check=True)

    # Install tools defined in mise configuration
    subprocess.run(['mise', 'install'], check=True)

    # Print success message
    print_success("mise install complete")


# ============================================================
# Shell Reload
# ============================================================

def reload_fish_shell() -> None:
    """Reload fish shell with login configuration."""
    print_header("Reloading fish shell")

    # Execute fish shell with login flag
    os.execvp('fish', ['fish', '-l'])
