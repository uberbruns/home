#!/usr/bin/env python3
"""Discover git repositories under a directory.

Walks the directory tree looking for .git markers. Stops descending
into subdirectories once a repository is found.
"""

import argparse
import os
import sys


# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #

def parse_args():
    parser = argparse.ArgumentParser(
        description="List git repositories under a directory",
    )
    parser.add_argument(
        "directory", nargs="?", default=".",
        help="root directory to search (default: current directory)",
    )
    parser.add_argument(
        "-a", "--absolute", action="store_true",
        help="print absolute paths instead of relative",
    )
    parser.add_argument(
        "-t", "--tab", action="store_true",
        help="tab-separate parent directory and repo name",
    )
    return parser.parse_args()


# --------------------------------------------------------------------------- #
# Implementation
# --------------------------------------------------------------------------- #

def find_repositories(root):
    """Yield paths sorted alphabetically, skipping hidden directories."""
    try:
        entries = sorted(os.scandir(root), key=lambda e: e.name)
    except PermissionError:
        return

    for entry in entries:
        if not entry.is_dir(follow_symlinks=False):
            continue
        if entry.name.startswith("."):
            continue

        if os.path.exists(os.path.join(entry.path, ".git")):
            yield entry.path
        else:
            yield from find_repositories(entry.path)


def format_path(path, tab_separated):
    """Format a path, optionally splitting parent and name with a tab."""
    if tab_separated:
        parent, name = os.path.split(path)
        return f"{name}\t{parent}"
    return path


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #

def main():
    """Discover and print git repositories under the given directory."""
    args = parse_args()
    root = os.path.realpath(args.directory)

    if not os.path.isdir(root):
        print(f"error: not a directory: {root}", file=sys.stderr)
        sys.exit(1)

    resolve_path = os.path.realpath if args.absolute else lambda p: os.path.relpath(p, root)

    for repo_path in find_repositories(root):
        print(format_path(resolve_path(repo_path), args.tab))


if __name__ == "__main__":
    main()
