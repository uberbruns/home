"""Command implementations."""

import os
import shutil
import subprocess
from pathlib import Path

from .config import Config
from .output import (
    print_error,
    print_header,
    print_info,
    print_key_value,
    print_success,
    print_warning,
)
from .symlinks import install_symlinks as _install_symlinks


# Re-export install_symlinks from symlinks module
install_symlinks = _install_symlinks


def push_changes(config: Config) -> None:
    """Stage, commit, and push all changes."""
    # Navigate to repository root
    os.chdir(config.script_dir)

    # Check if there are uncommitted changes
    git_status = subprocess.run(
        ['git', 'status', '--porcelain'],
        capture_output=True,
        text=True,
        check=True
    )

    if not git_status.stdout.strip():
        print_info("No changes to commit")
        return

    print_header("Pushing changes")

    # Stage all changes
    subprocess.run(['git', 'add', '-A'], check=True)
    print_success("Staged all changes")

    # Get diff for commit message generation
    git_diff = subprocess.run(
        ['git', 'diff', '--cached'],
        capture_output=True,
        text=True,
        check=True
    ).stdout

    # Generate commit message with Claude if available
    if shutil.which('claude'):
        print_info("Generating commit message with Claude...")

        try:
            prompt = (
                "Based on the following git diff, generate a concise commit message\n"
                "(50 characters or less) that describes the changes. Return only the\n"
                "commit message, nothing else, without any quotation marks.\n\n"
                f"{git_diff}"
            )

            result = subprocess.run(
                ['claude', '-p'],
                input=prompt,
                capture_output=True,
                text=True,
                check=True
            )

            commit_message = result.stdout.strip().split('\n')[0]
            if not commit_message:
                commit_message = "Update configuration"
        except subprocess.CalledProcessError as e:
            if e.stderr:
                print_error(f"Claude error: {e.stderr}")
            commit_message = "Update configuration"
    else:
        commit_message = "Update configuration"

    print_key_value("Commit message", commit_message)

    # Create commit
    subprocess.run(['git', 'commit', '-m', commit_message], check=True)
    print_success("Changes committed")

    # Push to remote
    subprocess.run(['git', 'push'], check=True)
    print_success("Changes pushed to remote")


def pull_changes(config: Config) -> None:
    """Fetch and pull latest changes from remote."""
    # Navigate to repository root
    os.chdir(config.script_dir)

    # Verify working tree is clean
    git_status = subprocess.run(
        ['git', 'status', '--porcelain'],
        capture_output=True,
        text=True,
        check=True
    )

    if git_status.stdout.strip():
        print_error("Uncommitted changes detected. Run 'home push' to commit them first.")
        raise SystemExit(1)

    print_header("Pulling changes")

    # Fetch and pull changes
    subprocess.run(['git', 'fetch'], check=True)
    subprocess.run(['git', 'pull'], check=True)
    subprocess.run(['git', 'submodule', 'update', '--init', '--recursive'], check=True)

    print_success("Repository is up to date")


def discard_changes(config: Config) -> None:
    """Discard all local changes and untracked files."""
    # Navigate to repository root
    os.chdir(config.script_dir)

    # Check if there are any changes to discard
    git_status = subprocess.run(
        ['git', 'status', '--porcelain'],
        capture_output=True,
        text=True,
        check=True
    )

    if not git_status.stdout.strip():
        print_info("No changes to discard")
        return

    print_header("Discarding changes")

    # Show what will be discarded
    subprocess.run(['git', 'status', '--short'], check=True)

    # Reset tracked files to HEAD
    subprocess.run(['git', 'reset', '--hard'], check=True)
    print_success("Tracked files reset")

    # Remove untracked files and directories
    subprocess.run(['git', 'clean', '-fd'], check=True)
    print_success("Untracked files removed")


def update_system(config: Config) -> None:
    """Pull changes, update development tools, and reload shell."""
    # Pull latest changes from remote
    pull_changes(config)

    # Install mise-managed tools
    print_header("Installing tools")
    subprocess.run(['mise', 'trust', '--yes', '--silent', '--all'], check=True)
    subprocess.run(['mise', 'install'], check=True)
    print_success("mise install complete")

    # Update Homebrew if owned by current user
    print_header("Updating Homebrew")

    homebrew_dir = None
    if Path('/opt/homebrew').exists():
        homebrew_dir = Path('/opt/homebrew')
    elif Path('/usr/local/Homebrew').exists():
        homebrew_dir = Path('/usr/local/Homebrew')

    if homebrew_dir:
        try:
            owner = homebrew_dir.owner()
            current_user = os.getlogin()

            if owner == current_user:
                subprocess.run(['brew', 'update'], check=True)
                subprocess.run(['brew', 'upgrade'], check=True)
                subprocess.run(['brew', 'cleanup'], check=True)
                print_success("Homebrew update complete")
            else:
                print_warning(f"Skipping Homebrew update (directory not owned by {current_user})")
        except Exception:
            print_warning("Skipping Homebrew update")

    # Reload fish shell
    print_header("Reloading fish shell")
    os.execvp('fish', ['fish', '-l'])
