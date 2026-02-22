"""Push command implementation."""

# ============================================================
# Imports
# ============================================================

import os
import shutil
import subprocess

from .config import Config
from .output import (
    print_error,
    print_header,
    print_info,
    print_key_value,
    print_success,
)


# ============================================================
# Entry Point
# ============================================================

def execute_push(config: Config) -> None:
    """Stage, commit, and push all changes."""
    # Navigate to repository root
    os.chdir(config.repo_root)

    # Check for uncommitted changes
    if not check_has_uncommitted_changes():
        print_info("No changes to commit")
        return

    print_header("Pushing changes")

    # Stage all changes
    stage_all_changes()

    # Generate and display commit message
    commit_message = generate_commit_message()
    print_key_value("Commit message", commit_message)

    # Create commit and push to remote
    create_commit(commit_message)
    push_commits_to_remote()


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


def create_commit(message: str) -> None:
    """Create a commit with the given message."""
    # Execute git commit
    subprocess.run(['git', 'commit', '-m', message], check=True)

    # Print success message
    print_success("Changes committed")


def get_staged_diff() -> str:
    """Get diff of staged changes."""
    # Query git diff for staged changes
    result = subprocess.run(
        ['git', 'diff', '--cached'],
        capture_output=True,
        text=True,
        check=True
    )

    # Return diff output
    return result.stdout


def push_commits_to_remote() -> None:
    """Push commits to remote repository."""
    # Execute git push
    subprocess.run(['git', 'push'], check=True)

    # Print success message
    print_success("Changes pushed to remote")


def stage_all_changes() -> None:
    """Stage all changes in the repository."""
    # Execute git add
    subprocess.run(['git', 'add', '-A'], check=True)

    # Print success message
    print_success("Staged all changes")


# ============================================================
# Commit Message Generation
# ============================================================

def generate_commit_message() -> str:
    """Generate commit message using Claude if available, otherwise use default."""
    # Check if Claude CLI is available
    if not shutil.which('claude'):
        return "Update configuration"

    # Attempt to generate message with Claude
    print_info("Generating commit message with Claude...")

    try:
        # Get staged diff and construct prompt
        staged_diff = get_staged_diff()
        claude_prompt = (
            "Based on the following git diff, generate a concise commit message\n"
            "(50 characters or less) that describes the changes. Return only the\n"
            "commit message, nothing else, without any quotation marks.\n\n"
            f"{staged_diff}"
        )

        # Call Claude CLI
        result = subprocess.run(
            ['claude', '-p'],
            input=claude_prompt,
            capture_output=True,
            text=True,
            check=True
        )

        # Extract and return commit message
        commit_message = result.stdout.strip().split('\n')[0]
        return commit_message if commit_message else "Update configuration"

    except subprocess.CalledProcessError as e:
        # Handle Claude CLI error
        if e.stderr:
            print_error(f"Claude error: {e.stderr}")
        return "Update configuration"
