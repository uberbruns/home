"""Text transformation tool.

Provides subcommands for converting text between naming conventions.
"""

import argparse
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


# ============================================================
# Entry Point
# ============================================================

def main():
    parser = argparse.ArgumentParser(description="Transform text between naming conventions.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    list_casings = subparsers.add_parser("list-casings", help="List all casing variants for a string.")
    list_casings.add_argument("text", help="Text to transform.")
    list_casings.set_defaults(func=cmd_list_casings)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
