"""Symlink installation and management."""

# ============================================================
# Imports
# ============================================================

from .config import Config, load_config_labels, load_toml
from .models import HomeEntry, SymlinkOperation, SymlinkResult, SymlinkStatus
from .output import Color, print_error, print_symlink_status


# ============================================================
# Operation Parsing
# ============================================================

def parse_all_operations(config: Config) -> list[SymlinkOperation]:
    """
    Parse all symlink operations from home.toml without filtering.

    Args:
        config: Configuration object

    Returns:
        List of all possible symlink operations
    """
    # Load home.toml configuration
    home_config = load_toml(config.home_toml)
    operations: list[SymlinkOperation] = []

    # Process each table in home.toml
    for table_name, table_entries in home_config.items():
        if isinstance(table_entries, dict):
            # Single table entry
            entry = HomeEntry.from_toml(table_name, table_entries)
            operation = SymlinkOperation(
                entry=entry,
                source_path=entry.resolve_source_path(config.script_dir),
                target_path=entry.resolve_target_path()
            )
            operations.append(operation)

        elif isinstance(table_entries, list):
            # Array of table entries
            for entry_data in table_entries:
                entry = HomeEntry.from_toml(table_name, entry_data)
                operation = SymlinkOperation(
                    entry=entry,
                    source_path=entry.resolve_source_path(config.script_dir),
                    target_path=entry.resolve_target_path()
                )
                operations.append(operation)

    return operations


# ============================================================
# Operation Filtering
# ============================================================

def filter_operations_by_labels(
    operations: list[SymlinkOperation],
    config_labels: list[str]
) -> list[SymlinkOperation]:
    """
    Filter operations to those matching the provided labels.

    Args:
        operations: All possible operations
        config_labels: Active labels from config.toml

    Returns:
        List of operations that match the label requirements
    """
    return [op for op in operations if op.entry.matches_labels(config_labels)]


def find_obsolete_operations(
    all_operations: list[SymlinkOperation],
    filtered_operations: list[SymlinkOperation]
) -> list[SymlinkOperation]:
    """
    Find operations that are obsolete (no longer match labels).

    Uses set subtraction based on target path equality.

    Args:
        all_operations: All possible operations
        filtered_operations: Operations matching current labels

    Returns:
        List of operations that should be removed
    """
    # Subtract filtered operations from all operations to find obsolete ones
    all_set = set(all_operations)
    filtered_set = set(filtered_operations)
    obsolete_set = all_set - filtered_set

    return list(obsolete_set)


# ============================================================
# Operation Execution
# ============================================================

def apply_install_operation(config: Config, operation: SymlinkOperation) -> SymlinkResult:
    """
    Apply a symlink installation operation.

    Args:
        config: Configuration object
        operation: Operation to apply

    Returns:
        Result with status after execution
    """
    # Validate source exists
    if not operation.source_path.exists():
        return SymlinkResult(
            operation=operation,
            status=SymlinkStatus.SKIPPED_SOURCE_NOT_FOUND
        )

    # Check if target already exists as symlink
    if operation.target_path.is_symlink():
        return SymlinkResult(
            operation=operation,
            status=SymlinkStatus.ALREADY_EXISTS
        )

    # Check if target exists but is not a symlink
    if operation.target_path.exists():
        return SymlinkResult(
            operation=operation,
            status=SymlinkStatus.SKIPPED_NOT_SYMLINK
        )

    # Create symlink
    if config.dryrun:
        status = SymlinkStatus.CREATED_DRYRUN
    else:
        # Create parent directories
        operation.target_path.parent.mkdir(parents=True, exist_ok=True)
        # Create symlink
        operation.target_path.symlink_to(operation.source_path)
        status = SymlinkStatus.CREATED

    return SymlinkResult(operation=operation, status=status)


def apply_removal_operation(config: Config, operation: SymlinkOperation) -> SymlinkResult | None:
    """
    Apply a symlink removal operation for obsolete entries.

    Removes stale symlinks that point to our source.

    Args:
        config: Configuration object
        operation: Operation to remove

    Returns:
        Result with status after execution, or None if target is not a matching symlink
    """
    # Skip non-symlink targets
    if not operation.target_path.is_symlink():
        return None

    try:
        # Verify symlink points to our source before removing
        resolved_target = operation.target_path.resolve()
        if resolved_target != operation.source_path.resolve():
            return None

        # Remove the stale symlink
        if config.dryrun:
            status = SymlinkStatus.REMOVED_DRYRUN
        else:
            operation.target_path.unlink()
            status = SymlinkStatus.REMOVED

        return SymlinkResult(operation=operation, status=status)

    except Exception:
        return None


# ============================================================
# Main Entry Point
# ============================================================

def install_symlinks(config: Config) -> list[SymlinkResult]:
    """
    Install symlinks based on home.toml and config.toml.

    Process:
    1. Parse all possible operations from home.toml
    2. Filter operations by current labels
    3. Find obsolete operations (all - filtered)
    4. Apply filtered operations (install/update)
    5. Apply obsolete operations (remove)

    Args:
        config: Configuration object

    Returns:
        List of results from all operations
    """
    # Validate config file exists
    if not config.config_toml.exists():
        print_error(f"config.toml not found at {config.config_toml}")
        raise SystemExit(1)

    # Load active labels
    config_labels = load_config_labels(config)

    # Parse all operations from home.toml
    all_operations = parse_all_operations(config)

    # Filter to operations matching current labels
    filtered_operations = filter_operations_by_labels(all_operations, config_labels)

    # Find obsolete operations that should be removed
    obsolete_operations = find_obsolete_operations(all_operations, filtered_operations)

    # Apply filtered operations (install/verify)
    results: list[SymlinkResult] = []
    for operation in filtered_operations:
        result = apply_install_operation(config, operation)
        results.append(result)

        # Print result based on status
        if result.status == SymlinkStatus.SKIPPED_SOURCE_NOT_FOUND:
            print_error(f"[{result.table_name}] Source not found -> {result.operation.source_path}")
        elif result.status == SymlinkStatus.ALREADY_EXISTS:
            print_symlink_status(result.table_name, result.status.value, Color.BLUE, str(result.target_path))
        elif result.status == SymlinkStatus.SKIPPED_NOT_SYMLINK:
            print_symlink_status(result.table_name, result.status.value, Color.YELLOW, str(result.target_path))
        elif result.status in (SymlinkStatus.CREATED, SymlinkStatus.CREATED_DRYRUN):
            print_symlink_status(result.table_name, result.status.value, Color.GREEN, str(result.target_path))

    # Apply obsolete operations (cleanup)
    for operation in obsolete_operations:
        result = apply_removal_operation(config, operation)
        if result:
            results.append(result)

            # Print result based on status
            if result.status in (SymlinkStatus.REMOVED, SymlinkStatus.REMOVED_DRYRUN):
                print_symlink_status(result.table_name, result.status.value, Color.YELLOW, str(result.target_path))

    return results
