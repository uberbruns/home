"""Install command — link dotfiles, install tools, and reload services."""

# ============================================================
# Imports
# ============================================================

import os
import shutil
import subprocess

from .command_link import execute_link
from .config import Config
from .output import print_header, print_success, print_warning


# ============================================================
# Entry Point
# ============================================================

def execute_install(config: Config) -> None:
    """
    Install the home configuration.

    Steps:
    1. Link dotfiles from home.toml
    2. Install mise-managed tools
    3. Reload Hammerspoon configuration
    4. Reload fish shell
    """
    execute_link(config)
    install_mise_tools()
    install_home_scripts()
    reload_hammerspoon()
    reload_fish_shell()


# ============================================================
# Tools
# ============================================================

def install_mise_tools() -> None:
    """Trust and install mise-managed tools."""
    print_header("Installing tools")

    subprocess.run(['mise', 'trust', '--yes', '--silent', '--all'], check=True)
    subprocess.run(['mise', 'install'], check=True)

    print_success("mise install complete")


def install_home_scripts() -> None:
    """Install home-bin scripts as uv tools."""
    print_header("Installing scripts")

    bin_dir = os.path.join(os.path.dirname(__file__), '..', '..')
    subprocess.run(['uv', 'tool', 'install', '--editable', bin_dir], check=True)

    print_success("uv tool install complete")


# ============================================================
# Service Reloads
# ============================================================

def reload_fish_shell() -> None:
    """Spawn a login fish shell to pick up configuration changes."""
    print_header("Reloading fish shell")
    subprocess.run(['fish', '-l'], check=True)


def reload_hammerspoon() -> None:
    """Reload Hammerspoon configuration via IPC."""
    if not shutil.which('hs'):
        print_warning("Skipping Hammerspoon reload (hs not found)")
        return

    print_header("Reloading Hammerspoon")

    try:
        subprocess.run(['hs', '-c', 'hs.reload()'], check=True)
        print_success("Hammerspoon reloaded")
    except subprocess.CalledProcessError:
        print_warning("Skipping Hammerspoon reload (command failed)")
