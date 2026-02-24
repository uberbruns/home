#!/bin/bash
# Bootstrap a fresh machine: install the package manager, system packages,
# CLI scripts, and dotfile links.

set -euo pipefail  # -e: exit on error, -u: error on unset variables, -o pipefail: propagate pipe failures

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ===========================================================================
# Platform Packages
# ===========================================================================

install_packages_macos() {
    if ! command -v brew &>/dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    $SHELL -i -c "brew bundle --file=$SCRIPT_DIR/brewfile-macos"
}

install_packages_linux() {
    echo "Linux bootstrap not yet implemented"
}

# ===========================================================================
# Main
# ===========================================================================

case "$(uname)" in
    Darwin) install_packages_macos ;;
    Linux)  install_packages_linux ;;
esac

mkdir -p ~/.cache
mise trust --yes --silent --all
mise install
mise exec -- uv tool install --editable --force ~/.home/bin
~/.home/bin/home_cli.py update
