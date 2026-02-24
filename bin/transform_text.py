"""Text transformation tool.

Provides subcommands for converting text between naming conventions.
"""

import argparse
import random
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


# ============================================================
# Commands
# ============================================================

def cmd_list_casings(args):
    """Print a tab-separated list of casing name and transformed string."""
    lines = [f"{name}\t{fn(args.text)}" for name, fn in CASINGS]
    print("\n".join(lines))


def cmd_shuffle(args):
    """Shuffle lines of text from stdin in random order."""
    lines = sys.stdin.read().splitlines()
    random.shuffle(lines)
    print("\n".join(lines))


def cmd_sort(args):
    """Sort lines of text from stdin."""
    lines = sys.stdin.read().splitlines()
    sorted_lines = sorted(lines, key=lambda l: l.lower() if args.ignore_case else l, reverse=args.reverse)
    print("\n".join(sorted_lines))


# ============================================================
# Entry Point
# ============================================================

def main():
    parser = argparse.ArgumentParser(description="Transform text between naming conventions.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    list_casings = subparsers.add_parser("list-casings", help="List all casing variants for a string.")
    list_casings.add_argument("text", help="Text to transform.")
    list_casings.set_defaults(func=cmd_list_casings)

    shuffle = subparsers.add_parser("shuffle", help="Shuffle lines of text from stdin.")
    shuffle.set_defaults(func=cmd_shuffle)

    sort = subparsers.add_parser("sort", help="Sort lines of text from stdin.")
    sort.add_argument("-r", "--reverse", action="store_true", help="Sort in descending order.")
    sort.add_argument("-i", "--ignore-case", action="store_true", help="Case-insensitive sort.")
    sort.set_defaults(func=cmd_sort)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
