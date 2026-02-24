#!/usr/bin/env python3
"""Bookmark picker using fzf.

Selecting a bookmark opens it in the default browser and exits 0.
Escape exits 1 without opening.
"""

import os
import subprocess
import sys
import unicodedata

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "lib"))
from safari_bookmarks import extract_bookmarks, filter_bookmarks, load_plist


# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #

LINE_WIDTH = 84
MAX_FOLDER_WIDTH = 40
FOLDER_DELIMITER = " > "

FZF_ARGS = [
    "fzf", "--ansi", "--prompt=❯ ", "--no-hscroll",
    "--color=16",
    "--color=prompt:15,bg+:0,fg+:15:regular,hl:regular,hl+:regular,gutter:0,pointer:15",
    "--pointer=▌", "--no-scrollbar",
    "--delimiter=\t", "--nth=1", "--with-nth=2", "--ignore-case",
    "--bind", "enter:accept",
]


# --------------------------------------------------------------------------- #
# Implementation
# --------------------------------------------------------------------------- #

def build_index(bookmarks):
    """Build fzf input: search_key \\t display \\t url per line."""
    lines = []
    for folder, title, url in bookmarks:
        # Format folder with output delimiter
        display_folder = folder.replace("/", FOLDER_DELIMITER) if folder else ""
        display_folder = truncate_wide(display_folder, MAX_FOLDER_WIDTH)

        # Format display: title left-aligned, folder right-aligned in dim
        padding = " " * max(1, LINE_WIDTH - display_width(title) - display_width(display_folder))
        display = f"{title}{padding}\033[90m{display_folder}\033[0m"

        search_key = f"{title} {folder} {url}"
        lines.append(f"{search_key}\t{display}\t{url}")
    return "\n".join(lines)


def pick_bookmark(index):
    """Run fzf and return the selected URL, or None on cancel."""
    result = subprocess.run(FZF_ARGS, input=index, text=True, capture_output=True)
    if result.returncode != 0 or not result.stdout.strip():
        return None
    return result.stdout.strip().split("\t")[2]


# --------------------------------------------------------------------------- #
# Formatting
# --------------------------------------------------------------------------- #

def display_width(text):
    """Return terminal column count, treating wide characters as 2 columns."""
    return sum(2 if unicodedata.east_asian_width(c) in "WF" else 1 for c in text)


def truncate_wide(text, max_width):
    """Shorten text to max_width display columns with trailing ellipsis."""
    if display_width(text) <= max_width:
        return text
    while display_width(text) > max_width - 1:
        text = text[:-1]
    return text + "…"


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #

def main():
    bookmarks = list(filter_bookmarks(
        extract_bookmarks(load_plist()),
        excludes=["com.apple.ReadingList/*"],
    ))
    if not bookmarks:
        sys.exit(1)

    index = build_index(bookmarks)
    url = pick_bookmark(index)
    if not url:
        sys.exit(1)

    subprocess.run(["open", url])


if __name__ == "__main__":
    main()
