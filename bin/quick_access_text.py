#!/usr/bin/env python3
"""Text casing picker using fzf.

Reads the current text selection via Hammerspoon IPC, presents all casing
variants via fzf, and replaces the selection with the chosen variant.
Exits 0 on selection, 1 on escape or empty selection.
"""

import json
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

def show_alert(message):
    """Show a brief alert via Hammerspoon."""
    subprocess.run(["hs", "-c", f"hs.alert.show({message!r})"], capture_output=True)


def read_selection():
    """Return the selection captured by Hammerspoon at picker launch, or None."""
    result = subprocess.run(["hs", "-c", "return IpcGetCapturedSelection()"], text=True, capture_output=True)
    # hs CLI output may include extension-loading lines ("--").
    # Scan from the end to find the first line that parses as valid JSON.
    for line in reversed(result.stdout.splitlines()):
        try:
            data = json.loads(line)
            return data[0] if isinstance(data, list) else data
        except (json.JSONDecodeError, IndexError, TypeError):
            continue
    return None


def replace_selection(text):
    """Queue a replacement to be applied by Hammerspoon when the picker closes."""
    json_text = json.dumps([text])
    subprocess.run(["hs", "-c", f"IpcQueueReplacement([==[{json_text}]==])"], capture_output=True)


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


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #

def main():
    text = read_selection()
    if not text:
        show_alert("No text selected")
        sys.exit(1)

    index = build_index(text)
    if not index:
        sys.exit(1)

    variant = pick_variant(index)
    if not variant:
        sys.exit(1)

    replace_selection(variant)


if __name__ == "__main__":
    main()
