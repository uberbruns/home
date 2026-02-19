"""Domain models for home configuration management."""

# ============================================================
# Imports
# ============================================================

from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Any


# ============================================================
# Enums
# ============================================================

class SymlinkStatus(Enum):
    """Status of a symlink operation after execution."""

    ALREADY_EXISTS = "Exists"
    CREATED = "Created"
    CREATED_DRYRUN = "Created (Not executed)"
    SKIPPED_NOT_SYMLINK = "Skipped (not a symlink)"
    SKIPPED_SOURCE_NOT_FOUND = "Skipped (source not found)"
    REMOVED = "Removed"
    REMOVED_DRYRUN = "Removed (Not executed)"


# ============================================================
# Label Models
# ============================================================

@dataclass(frozen=True)
class LabelRequirement:
    """
    A label requirement for filtering configuration entries.

    Can be either:
    - A single label (must be present)
    - Multiple labels with OR logic (at least one must be present)
    """

    labels: tuple[str, ...]

    @classmethod
    def from_value(cls, value: str | list[str]) -> 'LabelRequirement':
        """
        Create a LabelRequirement from TOML value.

        Args:
            value: Either a string (single label) or list of strings (OR requirement)

        Returns:
            LabelRequirement instance
        """
        if isinstance(value, str):
            return cls(labels=(value,))
        elif isinstance(value, list):
            return cls(labels=tuple(value))
        else:
            raise ValueError(f"Invalid label requirement: {value}")

    def matches(self, config_labels: list[str]) -> bool:
        """
        Check if this requirement is satisfied by the provided labels.

        Args:
            config_labels: Labels from config.toml

        Returns:
            True if requirement is satisfied
        """
        # Single label requirement
        if len(self.labels) == 1:
            return self.labels[0] in config_labels

        # OR requirement: at least one label must match
        return any(label in config_labels for label in self.labels)

    def __repr__(self) -> str:
        if len(self.labels) == 1:
            return f"LabelRequirement({self.labels[0]})"
        else:
            return f"LabelRequirement(OR: {', '.join(self.labels)})"


# ============================================================
# Home Entry Models
# ============================================================

@dataclass(frozen=True)
class HomeEntry:
    """
    A configuration entry from home.toml.

    Attributes:
        table_name: Name of the TOML table this entry belongs to
        source: Path to source file/directory in repository (relative)
        target: Path to target location on system (absolute, may contain ~)
        requirements: Label requirements for this entry
    """

    table_name: str
    source: str
    target: str
    requirements: tuple[LabelRequirement, ...]

    @classmethod
    def from_toml(cls, table_name: str, entry_data: dict[str, Any]) -> 'HomeEntry':
        """
        Create a HomeEntry from TOML data.

        Args:
            table_name: Name of the TOML table
            entry_data: Dictionary from home.toml

        Returns:
            HomeEntry instance
        """
        # Extract source and target paths
        source = entry_data.get('source', f'config/{table_name}')
        target = entry_data['target']

        # Parse label requirements
        requirements = [
            LabelRequirement.from_value(req_value)
            for req_value in entry_data.get('labels', [])
        ]

        return cls(
            table_name=table_name,
            source=source,
            target=target,
            requirements=tuple(requirements)
        )

    def matches_labels(self, config_labels: list[str]) -> bool:
        """
        Check if this entry's requirements are satisfied by config labels.

        Uses AND logic: all requirements must be satisfied.

        Args:
            config_labels: Labels from config.toml

        Returns:
            True if all requirements are satisfied (or no requirements)
        """
        # Entries without requirements match all label configurations
        if not self.requirements:
            return True

        # All requirements must be satisfied (AND logic)
        return all(req.matches(config_labels) for req in self.requirements)

    def resolve_source_path(self, script_dir: Path) -> Path:
        """
        Resolve the source path relative to script directory.

        Args:
            script_dir: Root directory of the repository

        Returns:
            Absolute path to source
        """
        return script_dir / self.source

    def resolve_target_path(self) -> Path:
        """
        Resolve the target path, expanding user home directory.

        Returns:
            Absolute path to target
        """
        return Path(self.target).expanduser()


# ============================================================
# Symlink Operation Models
# ============================================================

@dataclass(frozen=True)
class SymlinkOperation:
    """
    A planned symlink operation with resolved paths.

    Describes what symlink should be created and where.

    Attributes:
        entry: The home entry configuration
        source_path: Resolved absolute source path
        target_path: Resolved absolute target path
    """

    entry: HomeEntry
    source_path: Path
    target_path: Path

    @property
    def table_name(self) -> str:
        """Get the table name from the entry."""
        return self.entry.table_name

    def __eq__(self, other: object) -> bool:
        """Operations are equal if they have the same target path."""
        if not isinstance(other, SymlinkOperation):
            return NotImplemented
        return self.target_path == other.target_path

    def __hash__(self) -> int:
        """Hash based on target path for set operations."""
        return hash(self.target_path)


@dataclass(frozen=True)
class SymlinkResult:
    """
    Result of executing a symlink operation.

    Attributes:
        operation: The operation that was executed
        status: Status after execution
    """

    operation: SymlinkOperation
    status: SymlinkStatus

    @property
    def table_name(self) -> str:
        """Get the table name from the operation."""
        return self.operation.table_name

    @property
    def target_path(self) -> Path:
        """Get the target path from the operation."""
        return self.operation.target_path

    def is_success(self) -> bool:
        """Check if operation was successful."""
        return self.status in (
            SymlinkStatus.ALREADY_EXISTS,
            SymlinkStatus.CREATED,
            SymlinkStatus.CREATED_DRYRUN,
        )
