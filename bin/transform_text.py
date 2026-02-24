"""Text transformation tool.

Provides subcommands for converting text between naming conventions,
sorting, and shuffling lines. Supports reading/writing via stdin/stdout,
the macOS clipboard, or Hammerspoon IPC.
"""

import argparse
import json
import random
import subprocess
import sys
import textcase


# ============================================================
# Configuration
# ============================================================

CASINGS = [
    ("camel",    textcase.camel),
    ("constant", textcase.constant),
    ("kebab",    textcase.kebab),
    ("lower",    textcase.lower),
    ("pascal",   textcase.pascal),
    ("sentence", textcase.sentence),
    ("snake",    textcase.snake),
    ("title",    textcase.title),
    ("upper",    textcase.upper),
]

IO_CHOICES = ["clipboard", "hammerspoon"]


# ============================================================
# IO
# ============================================================

def read_text(source):
    """Read text from the given source (None=stdin, clipboard, hammerspoon)."""
    if source is None:
        return sys.stdin.read()
    if source == "clipboard":
        result = subprocess.run(["pbpaste"], text=True, capture_output=True)
        return result.stdout
    if source == "hammerspoon":
        result = subprocess.run(
            ["hs", "-c", "return IpcGetCapturedSelection()"],
            text=True, capture_output=True,
        )
        for line in reversed(result.stdout.splitlines()):
            try:
                data = json.loads(line)
                return data[0] if isinstance(data, list) else data
            except (json.JSONDecodeError, IndexError, TypeError):
                continue
        return None


def write_text(text, dest):
    """Write text to the given destination (None=stdout, clipboard, hammerspoon)."""
    if dest is None:
        sys.stdout.write(text)
        return
    if dest == "clipboard":
        subprocess.run(["pbcopy"], input=text, text=True)
        return
    if dest == "hammerspoon":
        json_text = json.dumps([text])
        subprocess.run(
            ["hs", "-c", f"IpcQueueReplacement([==[{json_text}]==])"],
            capture_output=True,
        )


def show_alert(message):
    """Show a brief alert via Hammerspoon."""
    subprocess.run(["hs", "-c", f"hs.alert.show({message!r})"], capture_output=True)


# ============================================================
# Commands
# ============================================================

def cmd_list_casings(args):
    """Print a tab-separated list of casing name and transformed string."""
    text = args.text or read_text(args.source)
    if not text:
        if args.source == "hammerspoon":
            show_alert("No text selected")
        sys.exit(1)
    result = "\n".join(f"{name}\t{fn(text)}" for name, fn in CASINGS)
    write_text(result + "\n", args.dest)


def cmd_shuffle(args):
    """Shuffle lines in random order."""
    text = read_text(args.source)
    if not text:
        if args.source == "hammerspoon":
            show_alert("No text selected")
        sys.exit(1)
    trailing = "\n" if text.endswith("\n") else ""
    lines = text.splitlines()
    random.shuffle(lines)
    write_text("\n".join(lines) + trailing, args.dest)


def cmd_sort(args):
    """Sort lines of text."""
    text = read_text(args.source)
    if not text:
        if args.source == "hammerspoon":
            show_alert("No text selected")
        sys.exit(1)
    trailing = "\n" if text.endswith("\n") else ""
    key = str.lower if args.ignore_case else None
    sorted_lines = sorted(text.splitlines(), key=key, reverse=args.reverse)
    write_text("\n".join(sorted_lines) + trailing, args.dest)


# ============================================================
# Entry Point
# ============================================================

def main():
    parser = argparse.ArgumentParser(description="Transform text between naming conventions.")
    parser.add_argument("--from", dest="source", choices=IO_CHOICES, default=None,
                        help="Input source (default: stdin)")
    parser.add_argument("--to", dest="dest", choices=IO_CHOICES, default=None,
                        help="Output destination (default: stdout)")
    subparsers = parser.add_subparsers(dest="command", required=True)

    list_casings = subparsers.add_parser("list-casings", help="List all casing variants for a string.")
    list_casings.add_argument("text", nargs="?", default=None, help="Text to transform (default: read from --from).")
    list_casings.set_defaults(func=cmd_list_casings)

    shuffle = subparsers.add_parser("shuffle", help="Shuffle lines of text.")
    shuffle.set_defaults(func=cmd_shuffle)

    sort = subparsers.add_parser("sort", help="Sort lines of text.")
    sort.add_argument("-r", "--reverse", action="store_true", help="Sort in descending order.")
    sort.add_argument("-i", "--ignore-case", action="store_true", help="Case-insensitive sort.")
    sort.set_defaults(func=cmd_sort)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
