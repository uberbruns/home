#!/usr/bin/env python3
"""Home configuration management tool.

Manages dotfiles with declarative symlinks and label-based filtering.
"""

import argparse
import os
import subprocess
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "lib"))
from home import (
    Config,
    execute_discard,
    execute_install,
    execute_link,
    execute_pull,
    execute_push,
    execute_update,
)
from home.output import print_error, print_info


# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #

COMMANDS = {
    "discard": execute_discard,
    "install": execute_install,
    "link":    execute_link,
    "pull":    execute_pull,
    "push":    execute_push,
    "update":  execute_update,
}


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #

def main():
    """Parse arguments and dispatch the requested command.

    Commands:
      install  - Link dotfiles, install mise tools, and reload Hammerspoon
      link     - Create symlinks from home.toml (filtered by labels in config.toml)
      push     - Commit and push all changes with AI-generated commit message
      pull     - Fetch and pull latest changes (requires clean working tree)
      discard  - Discard all local changes and untracked files
      update   - Pull, run mise install, and reload fish shell
    """
    parser = argparse.ArgumentParser(description="Home configuration management tool")
    parser.add_argument("command", choices=COMMANDS, help="command to execute")
    parser.add_argument("--dry-run", action="store_true",
                        help="print actions without executing them")
    args = parser.parse_args()

    # Initialize configuration
    config = Config()
    config.dryrun = args.dry_run

    # Dispatch command
    try:
        COMMANDS[args.command](config)
    except subprocess.CalledProcessError as e:
        sys.exit(e.returncode)
    except KeyboardInterrupt:
        print_info("\nInterrupted")
        sys.exit(130)
    except Exception as e:
        print_error(str(e))
        sys.exit(1)


if __name__ == "__main__":
    main()
