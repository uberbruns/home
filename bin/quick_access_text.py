#!/usr/bin/env python3
"""Text casing picker using fzf.

Reads text from the clipboard, presents all casing variants via fzf,
and copies the selected variant to the clipboard. Exits 0 on selection,
1 on escape or empty clipboard.
"""

import subprocess
import sys


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


# --------------------------------------------------------------------------- #
# Implementation
# --------------------------------------------------------------------------- #

def read_clipboard():
    """Return the current clipboard contents as a string, or None if empty."""
    result = subprocess.run(["pbpaste"], text=True, capture_output=True)
    text = result.stdout.strip()
    return text if text else None


def format_row(variant, name):
    """Format a row with the variant left-aligned and casing name right-aligned in gray.

    Truncates the variant with an ellipsis if the combined length exceeds LINE_WIDTH.
    """
    MIN_PADDING = 4
    max_variant_len = LINE_WIDTH - len(name) - MIN_PADDING
    if len(variant) > max_variant_len:
        variant = variant[:max_variant_len - 1] + "…"
    padding = " " * max(MIN_PADDING, LINE_WIDTH - len(variant) - len(name))
    return f"{variant}{padding}\033[90m{name}\033[0m"


def build_index(text):
    """Build fzf input from casing variants of text.

    Index format: search_key \\t display \\t variant
    """
    result = subprocess.run(
        ["/bin/sh", "-c", f"transform-text list-casings {text!r}"],
        text=True, capture_output=True,
    )
    if result.returncode != 0:
        return ""

    lines = []
    for line in result.stdout.splitlines():
        if "\t" not in line:
            continue
        name, variant = line.split("\t", 1)
        display = format_row(variant, name)
        lines.append(f"{name} {variant}\t{display}\t{variant}")
    return "\n".join(lines)


def pick_variant(index):
    """Run fzf and return the selected casing variant, or None."""
    result = subprocess.run(FZF_ARGS, input=index, text=True, capture_output=True)
    if result.returncode != 0 or not result.stdout.strip():
        return None
    return result.stdout.strip().split("\t")[2]


def copy_to_clipboard(text):
    """Copy text to the system clipboard via pbcopy."""
    subprocess.run(["pbcopy"], input=text, text=True)


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #

def main():
    text = read_clipboard()
    if not text:
        sys.exit(1)

    index = build_index(text)
    if not index:
        sys.exit(1)

    variant = pick_variant(index)
    if not variant:
        sys.exit(1)

    copy_to_clipboard(variant)


if __name__ == "__main__":
    main()
