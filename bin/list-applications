#!/usr/bin/env python3
"""List macOS applications found via Spotlight.

Uses mdfind to discover application bundles, filtering out deeply nested
and embedded applications.
"""

import argparse
import os
import re
import subprocess
import sys
import time


# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #

CACHE_MAX_AGE = 2 * 60 * 60  # 2 hours in seconds


def parse_args():
    parser = argparse.ArgumentParser(
        description="List macOS applications via Spotlight",
    )
    subparsers = parser.add_subparsers(dest="command")

    # Update cache command
    update_parser = subparsers.add_parser(
        "update-cache",
        help="update cache without outputting applications",
    )
    update_parser.add_argument(
        "-c", "--cache", type=str, required=True,
        help="cache file path for mdfind results (required)",
    )

    # Default arguments (list mode)
    parser.add_argument(
        "-d", "--max-depth", type=int, default=5,
        help="maximum path depth to include (default: 5)",
    )
    parser.add_argument(
        "-a", "--absolute", action="store_true",
        help="print absolute paths instead of just app name and directory",
    )
    parser.add_argument(
        "-t", "--tab", action="store_true",
        help="tab-separate app name and directory",
    )
    parser.add_argument(
        "-c", "--cache", type=str,
        help="cache file path for mdfind results",
    )
    parser.add_argument(
        "--async-update", action="store_true",
        help="launch background cache update after listing (requires -c)",
    )

    return parser.parse_args()


# --------------------------------------------------------------------------- #
# Implementation
# --------------------------------------------------------------------------- #

# Cache Operations

def is_cache_fresh(cache_path):
    """Check if cache file exists and is younger than configured max age."""
    if not os.path.exists(cache_path):
        return False

    cache_age = time.time() - os.path.getmtime(cache_path)
    return cache_age < CACHE_MAX_AGE


def read_cache(cache_path):
    """Load cached mdfind output from file."""
    with open(cache_path, "r") as f:
        return f.read()


def write_cache(cache_path, content):
    """Save mdfind output to cache file, creating directories if needed."""
    cache_dir = os.path.dirname(cache_path)
    if cache_dir:
        os.makedirs(cache_dir, exist_ok=True)
    with open(cache_path, "w") as f:
        f.write(content)


# Application Discovery

def get_mdfind_output(cache_path=None, force_refresh=False):
    """
    Fetch application bundle paths from Spotlight.

    Returns cached results when available and fresh, otherwise queries mdfind
    and updates cache. Force refresh bypasses cache check.
    """
    # Use cached output if available and fresh
    if cache_path and not force_refresh and is_cache_fresh(cache_path):
        return read_cache(cache_path)

    # Query Spotlight for application bundles
    result = subprocess.run(
        ["mdfind", 'kMDItemContentType == "com.apple.application-bundle"'],
        text=True, capture_output=True,
    )
    output = result.stdout

    # Update cache with fresh results
    if cache_path:
        write_cache(cache_path, output)

    return output


def find_applications(max_depth, cache_path=None, force_refresh=False):
    """
    Yield application paths filtered by depth and nesting.

    Filters out deeply nested paths exceeding max_depth and applications
    embedded within other bundles.
    """
    output = get_mdfind_output(cache_path, force_refresh)

    # Build filter patterns
    depth_pattern = re.compile(r"^(/[^/]+){1," + str(max_depth) + r"}$")
    nested_pattern = re.compile(r"/[^/]*\.[^/]*/.*\.app$")

    # Filter and yield matching paths
    for app_path in sorted(output.splitlines()):
        if not depth_pattern.match(app_path):
            continue
        if nested_pattern.search(app_path):
            continue

        yield app_path


# Formatting

def format_path(app_path, is_absolute, is_tab_separated):
    """Format application path according to output style flags."""
    # Tab-separated output always provides name and directory components
    if is_tab_separated:
        app_dir, app_name_with_ext = app_path.rsplit("/", 1)
        app_name = app_name_with_ext.removesuffix(".app")
        return f"{app_name}\t{app_dir}"

    # Absolute path output provides full path
    if is_absolute:
        return app_path

    # Default output provides name and directory with space separator
    app_dir, app_name_with_ext = app_path.rsplit("/", 1)
    app_name = app_name_with_ext.removesuffix(".app")
    return f"{app_name}  {app_dir}"


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #

def main():
    """Discover and print macOS applications."""
    args = parse_args()

    # Handle cache update subcommand
    if args.command == "update-cache":
        get_mdfind_output(args.cache, force_refresh=True)
        return

    # List applications with formatting
    for app_path in find_applications(args.max_depth, args.cache):
        print(format_path(app_path, args.absolute, args.tab))

    # Spawn background cache refresh
    if args.async_update and args.cache:
        subprocess.Popen(
            [sys.argv[0], "update-cache", "-c", args.cache],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )


if __name__ == "__main__":
    main()
