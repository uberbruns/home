"""Install command implementation."""

# ============================================================
# Imports
# ============================================================

import subprocess

from .command_link import execute_link
from .config import Config
from .output import print_header, print_success, print_warning


# ============================================================
# Entry Point
# ============================================================

def execute_install(config: Config) -> None:
    """Link dotfiles, install mise tools, reload Hammerspoon, and reload shell."""
    execute_link(config)
    install_mise_tools()
    reload_hammerspoon()
    reload_fish_shell()


# ============================================================
# Hammerspoon Reload
# ============================================================

def reload_hammerspoon() -> None:
    """Reload Hammerspoon configuration."""
    print_header("Reloading Hammerspoon")

    try:
        subprocess.run(['hs', '-c', 'hs.reload()'], check=True)
        print_success("Hammerspoon reloaded")
    except FileNotFoundError:
        print_warning("Skipping Hammerspoon reload (hs not found)")
    except subprocess.CalledProcessError:
        print_warning("Skipping Hammerspoon reload (command failed)")


# ============================================================
# Mise Tools
# ============================================================

def install_mise_tools() -> None:
    """Install and update mise-managed tools."""
    print_header("Installing tools")

    # Trust mise configuration files
    subprocess.run(['mise', 'trust', '--yes', '--silent', '--all'], check=True)

    # Install tools defined in mise configuration
    subprocess.run(['mise', 'install'], check=True)

    print_success("mise install complete")


# ============================================================
# Shell Reload
# ============================================================

def reload_fish_shell() -> None:
    """Reload fish shell with login configuration."""
    print_header("Reloading fish shell")

    subprocess.run(['fish', '-l'], check=True)
