#!/usr/bin/env python3
"""Single-shot line transformation via Hammerspoon IPC.

Reads the selection captured at picker launch, applies a transformation,
and queues the result for replacement when the picker closes.
"""

import argparse
import json
import random
import subprocess
import sys


# --------------------------------------------------------------------------- #
# IPC
# --------------------------------------------------------------------------- #

def show_alert(message):
    """Show a brief alert via Hammerspoon."""
    subprocess.run(["hs", "-c", f"hs.alert.show({message!r})"], capture_output=True)


def read_captured_selection():
    """Return the selection stored by Hammerspoon before the picker opened, or None."""
    result = subprocess.run(["hs", "-c", "return ipcGetCapturedSelection()"], text=True, capture_output=True)
    # hs CLI output may include extension-loading lines ("--").
    # Scan from the end to find the first line that parses as valid JSON.
    for line in reversed(result.stdout.splitlines()):
        try:
            data = json.loads(line)
            return data[0] if isinstance(data, list) else data
        except (json.JSONDecodeError, IndexError, TypeError):
            continue
    return None


def queue_replacement(text):
    """Queue text to be inserted by Hammerspoon when the picker closes."""
    json_text = json.dumps([text])
    subprocess.run(["hs", "-c", f"ipcQueueReplacement([==[{json_text}]==])"], capture_output=True)


# --------------------------------------------------------------------------- #
# Transforms
# --------------------------------------------------------------------------- #

def sort_lines(text):
    """Sort lines case-insensitively."""
    trailing = "\n" if text.endswith("\n") else ""
    return "\n".join(sorted(text.splitlines(), key=str.lower)) + trailing


def shuffle_lines(text):
    """Shuffle lines in random order."""
    trailing = "\n" if text.endswith("\n") else ""
    lines = text.splitlines()
    random.shuffle(lines)
    return "\n".join(lines) + trailing


# --------------------------------------------------------------------------- #
# Entry Point
# --------------------------------------------------------------------------- #

TRANSFORMS = {
    "sort": sort_lines,
    "shuffle": shuffle_lines,
}


def main():
    parser = argparse.ArgumentParser(description="Transform lines of the captured selection.")
    parser.add_argument("transform", choices=TRANSFORMS.keys())
    args = parser.parse_args()

    text = read_captured_selection()
    if not text:
        show_alert("No text selected")
        sys.exit(1)

    result = TRANSFORMS[args.transform](text)
    queue_replacement(result)


if __name__ == "__main__":
    main()
