"""Install command — link dotfiles, install tools, and reload services."""

# ============================================================
# Imports
# ============================================================

import os
import shutil
import subprocess

from .command_link import execute_link
from .config import Config, load_toml
from .output import print_header, print_success


# ============================================================
# Entry Point
# ============================================================

def execute_install(config: Config) -> None:
    """
    Install the home configuration.

    Steps:
    1. Link dotfiles from home.toml
    2. Install mise-managed tools
    3. Install herdr plugins
    4. Reload fish shell
    """
    execute_link(config)
    install_mise_tools()
    install_herdr_plugins(config)
    install_home_scripts()
    reload_fish_shell()


def execute_install_without_reload(config: Config) -> None:
    """Run install steps without reloading the fish shell."""
    execute_link(config)
    install_mise_tools()
    install_herdr_plugins(config)
    install_home_scripts()


# ============================================================
# Tools
# ============================================================

def install_mise_tools() -> None:
    """Trust and install mise-managed tools."""
    print_header("Installing tools")

    subprocess.run(['mise', 'trust', '--yes', '--silent', '--all'], check=True)
    subprocess.run(['mise', 'install'], check=True)

    print_success("mise install complete")


def install_herdr_plugins(config: Config) -> None:
    """Install herdr plugins declared in config/herdr/plugins.toml."""
    plugins_file = config.repo_root / "config" / "herdr" / "plugins.toml"

    if not plugins_file.exists() or shutil.which("herdr") is None:
        return

    print_header("Installing herdr plugins")

    plugins_data = load_toml(plugins_file)
    for plugin in plugins_data.get("plugin", []):
        subprocess.run(["herdr", "plugin", "install", plugin["source"], "--yes"], check=True)

    print_success("herdr plugin install complete")


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
