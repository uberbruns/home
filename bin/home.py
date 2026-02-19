#!/usr/bin/env python3
"""
Home configuration management tool.
Manages dotfiles with declarative symlinks and label-based filtering.
"""

import argparse
import subprocess
import sys

from homelib import (
    Config,
    discard_changes,
    install_symlinks,
    pull_changes,
    push_changes,
    update_system,
)
from homelib.output import print_error, print_info


def main() -> None:
    """Parse arguments and execute requested command."""
    parser = argparse.ArgumentParser(
        description='Home configuration management tool',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Commands:
  install    Create symlinks from home.toml (filtered by labels in config.toml)
  push       Commit and push all changes with AI-generated commit message
  pull       Fetch and pull latest changes (requires clean working tree)
  discard    Discard all local changes and untracked files
  update     Pull, run mise install, and reload fish shell

Flags:
  --dryrun   Print actions without executing them
        """
    )

    parser.add_argument(
        'command',
        choices=['install', 'push', 'pull', 'discard', 'update'],
        help='Command to execute'
    )
    parser.add_argument(
        '--dryrun',
        action='store_true',
        help='Print actions without executing them'
    )

    args = parser.parse_args()

    # Initialize configuration
    config = Config()
    config.dryrun = args.dryrun

    # Execute requested command
    try:
        if args.command == 'install':
            install_symlinks(config)
        elif args.command == 'push':
            push_changes(config)
        elif args.command == 'pull':
            pull_changes(config)
        elif args.command == 'discard':
            discard_changes(config)
        elif args.command == 'update':
            update_system(config)
    except subprocess.CalledProcessError as e:
        sys.exit(e.returncode)
    except KeyboardInterrupt:
        print_info("\nInterrupted")
        sys.exit(130)
    except Exception as e:
        print_error(str(e))
        sys.exit(1)


if __name__ == '__main__':
    main()
