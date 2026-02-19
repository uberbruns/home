"""Formatted output utilities."""

# ============================================================
# Imports
# ============================================================

import sys


# ============================================================
# Configuration
# ============================================================

class Color:
    """ANSI color codes for terminal output."""

    RESET = '\033[0m'
    BOLD = '\033[1m'
    CYAN = '\033[36m'
    GREEN = '\033[32m'
    YELLOW = '\033[33m'
    BLUE = '\033[34m'


# ============================================================
# Output Functions
# ============================================================

def print_header(message: str) -> None:
    """Print a section header with bold cyan formatting."""
    print()
    print(f"{Color.BOLD}{Color.CYAN}# {message}{Color.RESET}")
    print()


def print_info(message: str) -> None:
    """Print an informational message."""
    print(message)


def print_error(message: str) -> None:
    """Print an error message to stderr with 'Error:' prefix."""
    print(f"Error: {message}", file=sys.stderr)


def print_success(message: str) -> None:
    """Print a success message in green."""
    print(f"{Color.GREEN}{message}{Color.RESET}")


def print_warning(message: str) -> None:
    """Print a warning message in yellow."""
    print(f"{Color.YELLOW}{message}{Color.RESET}")


def print_key_value(key: str, value: str) -> None:
    """Print a key-value pair with cyan-colored key."""
    print(f"{Color.CYAN}{key}:{Color.RESET} {value}")


def print_symlink_status(table_name: str, status: str, status_color: str, target_path: str) -> None:
    """
    Print a formatted symlink operation status line.

    Args:
        table_name: Name of the config table
        status: Status message (e.g., "Already exists", "Created")
        status_color: Color constant for the status (e.g., Color.BLUE, Color.GREEN)
        target_path: Path to the symlink target
    """
    print(f"[{Color.CYAN}{table_name}{Color.RESET}] {status_color}{status}{Color.RESET} -> {target_path}")
