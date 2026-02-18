#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bootstrap_macos() {
    if ! command -v brew &>/dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "Homebrew already installed"
    fi

    cat "$SCRIPT_DIR/brewfile-macos" | $SHELL -i -c "brew bundle --file=-"
}

bootstrap_linux() {
    echo "Linux bootstrap not yet implemented"
}

OS="$(uname)"

if [[ "$OS" == "Darwin" ]]; then
    bootstrap_macos
elif [[ "$OS" == "Linux" ]]; then
    bootstrap_linux
fi

mise settings experimental=true