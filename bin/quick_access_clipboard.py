#!/usr/bin/env python3
"""Clipboard history picker using fzf with preview panel.

Selecting an entry copies it to the clipboard and exits 0.
Escape exits 1 without copying.
"""

import json
import linecache
import os
import subprocess
import sys
import tempfile


# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #

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

def build_index(preview_path):
    """Build fzf input and write raw entries to preview file.

    Index format: search_key \\t display \\t line_number \\t action
    """
    result = subprocess.run(
        ["clipse", "-output-all", "raw"],
        text=True, capture_output=True,
    )
    lines = []
    with open(preview_path, "w") as pf:
        for line_number, raw_entry in enumerate(result.stdout.splitlines(), 1):
            if not raw_entry:
                continue
            # Flatten JSON-encoded entry to single line for display
            display = raw_entry
            if display.startswith('"') and display.endswith('"'):
                display = display[1:-1]
            display = display.replace("\\n", " ").replace("\\t", " ").replace('\\"', '"')

            pf.write(raw_entry + "\n")
            lines.append(f"{display}\t{display}\t{line_number}")
    return "\n".join(lines)


def decode_preview(preview_path, line_number):
    """Decode a JSON entry from the preview file and print it."""
    line = linecache.getline(preview_path, int(line_number))
    if line:
        sys.stdout.write(json.loads(line.strip()))


def pick_entry(index, preview_path):
    """Run fzf with preview and return selected line number, or None."""
    script = os.path.abspath(sys.argv[0])
    preview_cmd = f"{script} --preview {preview_path} {{3}}"
    fzf_args = FZF_ARGS + [
        "--preview", preview_cmd,
        "--preview-window=right:50%:wrap",
    ]
    result = subprocess.run(fzf_args, input=index, text=True, capture_output=True)
    if result.returncode != 0 or not result.stdout.strip():
        return None
    return result.stdout.strip().split("\t")[2]


def copy_entry(preview_path, line_number):
    """Decode the raw JSON entry and pipe it to clipse."""
    with open(preview_path) as f:
        for i, line in enumerate(f, 1):
            if i == int(line_number):
                decoded = json.loads(line.strip())
                subprocess.run(["clipse", "-c"], input=decoded, text=True)
                return


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #

def main():
    # Handle --preview callback from fzf
    if len(sys.argv) == 4 and sys.argv[1] == "--preview":
        decode_preview(sys.argv[2], sys.argv[3])
        return

    preview_file = tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False)
    preview_path = preview_file.name
    preview_file.close()

    try:
        index = build_index(preview_path)
        if not index:
            sys.exit(1)

        line_number = pick_entry(index, preview_path)
        if not line_number:
            sys.exit(1)

        copy_entry(preview_path, line_number)
    finally:
        os.unlink(preview_path)


if __name__ == "__main__":
    main()
