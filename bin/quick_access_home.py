#!/usr/bin/env python3
"""Quick-access launcher combining macOS apps and registered actions.

Presents a unified fzf index; selecting an item runs its action.
Escape exits; returning from a sub-picker loops back to home.
"""

import os
import shutil
import subprocess
import sys
import unicodedata

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "lib"))
from safari_bookmarks import extract_bookmarks, filter_bookmarks, load_plist


# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #

LINE_WIDTH = 84

FZF_ARGS = [
    "fzf", "--ansi", "--prompt=❯ ", "--no-hscroll",
    "--color=16",
    "--color=prompt:15,bg+:0,fg+:15:regular,hl:regular,hl+:regular,gutter:0,pointer:15",
    "--pointer=▌", "--no-scrollbar",
    "--delimiter=\t", "--nth=1", "--with-nth=2", "--ignore-case",
    "--bind", "enter:accept",
]

SUBCOMMANDS = [
    # (name, noun, description, command)
    ("Bookmarks", "bookmarks", "Open Safari bookmark in browser", "quick-access-bookmarks"),
    ("Clipboard History", "clipboard", "Paste from history via clipse", "quick-access-clipboard"),
    ("Emoji Picker", "emoji", "Search and copy emoji to clipboard", "quick-access-emojis"),
]

TEXT_TOOLS = [
    # (name, noun, description, command)
    ("Shuffle Lines", "shuffle lines text", "Shuffle selected lines", "transform-text --from hammerspoon --to hammerspoon shuffle"),
    ("Sort Lines", "sort lines text", "Sort selected lines", "transform-text --from hammerspoon --to hammerspoon sort"),
    ("Text Casings", "text casing transform", "Convert clipboard text to a casing variant", "quick-access-text"),
]

TOOLS = [
    # (name, noun, description, command)
    ("Astroterm", "sky stars", "Night sky over Hamburg", "astroterm --color --unicode --quit-on-any --city=Hamburg"),
    ("Calculator", "calculator", "Math expressions via qalc", "qalc"),
    ("Editor", "editor", "Terminal editor via fresh", "fresh"),
    ("File Browser", "files", "Navigate filesystem via yazi", "yazi"),
    ("Swift REPL", "repl", "Interactive Swift playground", "swift repl"),
]


# --------------------------------------------------------------------------- #
# Implementation
# --------------------------------------------------------------------------- #

def build_subcommand_index():
    """Build index rows from quick-access subcommands."""
    return _build_command_index(SUBCOMMANDS, "  ⮑  ", "35")


def build_text_tool_index():
    """Build index rows from text transformation tools."""
    return _build_command_index(TEXT_TOOLS, "[TXT]", "36")


def build_tool_index():
    """Build index rows from CLI tool invocations."""
    return _build_command_index(TOOLS, "[CLI]", "32")


def _build_command_index(entries, type_label, type_color):
    """Build index rows from a list of command entries."""
    lines = []
    for name, noun, description, command in entries:
        cmd_name = command.split()[0]
        if not shutil.which(cmd_name):
            continue

        display = format_row(type_label, type_color, name, description)
        search_key = f"{name} {noun} {description}"
        lines.append(f"{search_key}\t{display}\t{command}")
    return lines


def build_bookmark_index():
    """Build index rows from Safari BookmarksBar."""
    try:
        bookmarks = filter_bookmarks(
            extract_bookmarks(load_plist()),
            root="BookmarksBar",
        )
    except Exception:
        return []

    lines = []
    for folder, title, url in bookmarks:
        display_folder = folder.replace("/", " > ") if folder else ""
        display = format_row("[URL]", "34", title, display_folder)
        search_key = f"{title} {folder} {url}"
        lines.append(f"{search_key}\t{display}\topen '{url}'")
    return lines


def build_repository_index():
    """Build index rows from git repositories under ~/Development."""
    dev_dir = os.path.expanduser("~/Development")
    result = subprocess.run(
        ["list-repositories", "--tab", dev_dir],
        text=True, capture_output=True,
    )
    if result.returncode != 0:
        return []

    lines = []
    for line in result.stdout.splitlines():
        repo_name, relative_parent = line.split("\t", 1)
        absolute_path = os.path.join(dev_dir, relative_parent, repo_name)
        display = format_row("[Dev]", "33", repo_name, relative_parent)
        search_key = f"{repo_name} {relative_parent}"
        lines.append(f"{search_key}\t{display}\topen -a ghostty {absolute_path}")
    return lines


def build_app_index():
    """Build index rows from macOS apps found via Spotlight."""
    cache_path = os.path.expanduser("~/.home/cache/applications.txt")
    result = subprocess.run(
        ["list-applications", "--absolute", "--tab", "--cache", cache_path, "--async-update"],
        text=True, capture_output=True,
    )
    if result.returncode != 0:
        return []

    lines = []
    for line in result.stdout.splitlines():
        app_name, app_dir = line.split("\t", 1)
        app_path = f"{app_dir}/{app_name}.app"
        display = format_row("[App]", "35", app_name, app_dir)
        lines.append(f"{app_path}\t{display}\topen '{app_path}'")
    return lines


def build_index():
    """Aggregate all index sources."""
    return "\n".join(build_subcommand_index() + build_text_tool_index() + build_tool_index() + build_bookmark_index() + build_repository_index() + build_app_index())


# --------------------------------------------------------------------------- #
# Formatting
# --------------------------------------------------------------------------- #

def display_width(text):
    """Return terminal column count, treating wide characters as 2 columns."""
    return sum(2 if unicodedata.east_asian_width(c) in "WF" else 1 for c in text)


def format_row(type_label, type_color, title, details):
    """Format a row with colored type tag, title, and right-aligned details."""
    tag = f"\033[{type_color}m{type_label}\033[0m"
    tag_len = len(type_label)

    padding = " " * max(4, LINE_WIDTH - tag_len - 1 - display_width(title) - len(details))

    return f"{tag} {title}{padding}\033[90m{details}\033[0m"


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #

def main():
    os.chdir(os.path.expanduser("~"))

    while True:
        index = build_index()
        result = subprocess.run(FZF_ARGS, input=index, text=True, capture_output=True)
        if result.returncode != 0 or not result.stdout.strip():
            break

        action = result.stdout.strip().split("\t")[2]
        r = subprocess.run(["/bin/sh", "-c", action])
        if r.returncode == 0:
            break


if __name__ == "__main__":
    main()
