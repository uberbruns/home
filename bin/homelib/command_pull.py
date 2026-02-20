"""Pull command implementation."""

# ============================================================
# Imports
# ============================================================

import os
import subprocess

from .config import Config
from .output import print_error, print_header, print_success


# ============================================================
# Entry Point
# ============================================================

def execute_pull(config: Config) -> None:
    """Fetch and pull latest changes from remote."""
    # Navigate to repository root
    os.chdir(config.repo_root)

    # Verify working tree is clean
    if check_has_uncommitted_changes():
        print_error("Uncommitted changes detected. Run 'home push' to commit them first.")
        raise SystemExit(1)

    print_header("Pulling changes")

    # Fetch, pull, and update submodules
    fetch_commits_from_remote()
    pull_commits_from_remote()
    update_git_submodules()

    print_success("Repository is up to date")


# ============================================================
# Git Operations
# ============================================================

def check_has_uncommitted_changes() -> bool:
    """Check if repository has uncommitted changes."""
    # Query git status
    result = subprocess.run(
        ['git', 'status', '--porcelain'],
        capture_output=True,
        text=True,
        check=True
    )

    # Return true if output is not empty
    return bool(result.stdout.strip())


def fetch_commits_from_remote() -> None:
    """Fetch latest commits from remote repository."""
    # Execute git fetch
    subprocess.run(['git', 'fetch'], check=True)


def pull_commits_from_remote() -> None:
    """Pull latest commits from remote repository."""
    # Execute git pull
    subprocess.run(['git', 'pull'], check=True)


def update_git_submodules() -> None:
    """Update and initialize git submodules recursively."""
    # Execute git submodule update
    subprocess.run(['git', 'submodule', 'update', '--init', '--recursive'], check=True)
