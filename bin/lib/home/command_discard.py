"""Discard command implementation."""

# ============================================================
# Imports
# ============================================================

import os
import subprocess

from .config import Config
from .output import print_header, print_info, print_success


# ============================================================
# Entry Point
# ============================================================

def execute_discard(config: Config) -> None:
    """Discard all local changes and untracked files."""
    # Navigate to repository root
    os.chdir(config.repo_root)

    # Check for changes to discard
    if not check_has_changes_to_discard():
        print_info("No changes to discard")
        return

    print_header("Discarding changes")

    # Show changes before discarding
    show_git_status()

    # Discard changes
    reset_tracked_files_to_head()
    remove_untracked_files()


# ============================================================
# Git Operations
# ============================================================

def check_has_changes_to_discard() -> bool:
    """Check if repository has changes to discard."""
    # Query git status
    result = subprocess.run(
        ['git', 'status', '--porcelain'],
        capture_output=True,
        text=True,
        check=True
    )

    # Return true if output is not empty
    return bool(result.stdout.strip())


def remove_untracked_files() -> None:
    """Remove untracked files and directories."""
    # Execute git clean
    subprocess.run(['git', 'clean', '-fd'], check=True)

    # Print success message
    print_success("Untracked files removed")


def reset_tracked_files_to_head() -> None:
    """Reset tracked files to HEAD."""
    # Execute git reset
    subprocess.run(['git', 'reset', '--hard'], check=True)

    # Print success message
    print_success("Tracked files reset")


def show_git_status() -> None:
    """Display current repository status in short format."""
    # Execute git status with short format
    subprocess.run(['git', 'status', '--short'], check=True)
