"""Configuration management."""

# ============================================================
# Imports
# ============================================================

import sys
from pathlib import Path
from typing import Any

# Require Python 3.11+ for tomllib
if sys.version_info < (3, 11):
    print("Error: Python 3.11 or higher is required", file=sys.stderr)
    sys.exit(1)

import tomllib


# ============================================================
# Configuration
# ============================================================

class Config:
    """Configuration paths and global state."""

    def __init__(self):
        # Resolve repository root directory
        self.repo_root = Path(__file__).parent.parent.parent.parent.resolve()

        # Validate repository is a git directory
        if not (self.repo_root / ".git").exists():
            print(f"Error: Not a git repository: {self.repo_root}", file=sys.stderr)
            sys.exit(1)

        # Configuration file paths
        self.home_toml = self.repo_root / "home.toml"
        self.config_toml = self.repo_root / "config.toml"

        # Runtime flags
        self.dryrun = False


# ============================================================
# TOML Loading
# ============================================================

def load_toml(path: Path) -> dict[str, Any]:
    """Load and parse a TOML file."""
    with open(path, 'rb') as f:
        return tomllib.load(f)


def load_config_labels(config: Config) -> list[str]:
    """
    Extract labels from config.toml.

    Returns empty list when file is missing or unreadable.
    """
    try:
        config_data = load_toml(config.config_toml)
        return config_data.get('labels', [])
    except Exception:
        return []
