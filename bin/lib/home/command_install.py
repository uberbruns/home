"""Install command implementation."""

# ============================================================
# Imports
# ============================================================

from .config import Config, load_config_labels, load_toml
from .models import HomeEntry, SymlinkOperation, SymlinkResult, SymlinkStatus
from .output import Color, print_error, print_symlink_status


# ============================================================
# Entry Point
# ============================================================

def execute_install(config: Config) -> list[SymlinkResult]:
    """
    Install symlinks based on home.toml and config.toml.

    Process:
    1. Parse all possible operations from home.toml
    2. Filter operations by current labels
    3. Find discarded operations (all - filtered)
    4. Apply filtered operations (install/update)
    5. Apply discarded operations (remove)

    Args:
        config: Configuration object

    Returns:
        List of results from all operations
    """
    # Validate configuration file
    if not config.config_toml.exists():
        print_error(f"config.toml not found at {config.config_toml}")
        raise SystemExit(1)

    # Parse symlink operations from configuration
    labels = load_config_labels(config)
    all_operations = parse_symlink_operations(config)

    # Filter operations by labels
    matching_operations = [op for op in all_operations if op.entry.matches_labels(labels)]
    discarded_operations = list(set(all_operations) - set(matching_operations))

    # Execute operations and collect results
    results = execute_matching_operations(config, matching_operations)
    execute_discarded_operations(config, discarded_operations, results)

    return results


# ============================================================
# Operations
# ============================================================

def execute_matching_operations(config: Config, operations: list[SymlinkOperation]) -> list[SymlinkResult]:
    """Execute and print results for symlink operations matching current labels."""
    results: list[SymlinkResult] = []

    # Process each operation
    for operation in operations:
        result = apply_install_operation(config, operation)
        results.append(result)
        print_symlink_result(result)

    return results


def execute_discarded_operations(config: Config, operations: list[SymlinkOperation], results: list[SymlinkResult]) -> None:
    """Execute and print results for discarded symlink operations."""
    # Process each discarded operation
    for operation in operations:
        result = apply_removal_operation(config, operation)

        # Add result if symlink was removed
        if result:
            results.append(result)
            if result.status in (SymlinkStatus.REMOVED, SymlinkStatus.REMOVED_DRYRUN):
                print_symlink_status(result.table_name, result.status.value, Color.YELLOW, str(result.target_path))


def parse_symlink_operations(config: Config) -> list[SymlinkOperation]:
    """Parse all symlink operations from home.toml without filtering."""
    # Load home.toml configuration
    home_config = load_toml(config.home_toml)
    operations: list[SymlinkOperation] = []

    # Build operations from each table
    for table_name, table_data in home_config.items():
        # Normalize single dict entries into a list
        entry_dicts = [table_data] if isinstance(table_data, dict) else table_data if isinstance(table_data, list) else []

        for entry_dict in entry_dicts:
            entry = HomeEntry.from_toml(table_name, entry_dict)
            operations.append(SymlinkOperation(
                entry=entry,
                source_path=entry.resolve_source_path(config.repo_root),
                target_path=entry.resolve_target_path(),
            ))

    return operations


# ============================================================
# Symlinks
# ============================================================

def apply_install_operation(config: Config, operation: SymlinkOperation) -> SymlinkResult:
    """Apply a symlink installation operation."""
    # Validate source file exists
    if not operation.source_path.exists():
        return SymlinkResult(
            operation=operation,
            status=SymlinkStatus.SKIPPED_SOURCE_NOT_FOUND,
        )

    # Evaluate existing symlink
    if operation.target_path.is_symlink():
        return evaluate_existing_symlink(config, operation)

    # Handle existing non-symlink file
    if operation.target_path.exists():
        return SymlinkResult(
            operation=operation,
            status=SymlinkStatus.SKIPPED_NOT_SYMLINK,
        )

    # Create new symlink
    return create_symlink(config, operation)


def apply_removal_operation(config: Config, operation: SymlinkOperation) -> SymlinkResult | None:
    """Apply a symlink removal operation for discarded entries."""
    # Verify target is a symlink
    if not operation.target_path.is_symlink():
        return None

    try:
        # Verify symlink points to our source
        resolved_target = operation.target_path.resolve()
        if resolved_target != operation.source_path.resolve():
            return None

        # Remove symlink based on mode
        if config.dryrun:
            status = SymlinkStatus.REMOVED_DRYRUN
        else:
            operation.target_path.unlink()
            status = SymlinkStatus.REMOVED

        return SymlinkResult(operation=operation, status=status)

    except Exception:
        return None


def create_symlink(config: Config, operation: SymlinkOperation) -> SymlinkResult:
    """Create a new symlink."""
    # Select status based on mode
    if config.dryrun:
        status = SymlinkStatus.CREATED_DRYRUN
    else:
        # Create parent directories and symlink
        operation.target_path.parent.mkdir(parents=True, exist_ok=True)
        operation.target_path.symlink_to(operation.source_path)
        status = SymlinkStatus.CREATED

    return SymlinkResult(operation=operation, status=status)


def evaluate_existing_symlink(config: Config, operation: SymlinkOperation) -> SymlinkResult:
    """Evaluate existing symlink and decide whether to keep, skip, or override."""
    try:
        # Resolve existing symlink target
        existing_target = operation.target_path.resolve()

        # Check if symlink already points to correct source
        if existing_target == operation.source_path.resolve():
            return SymlinkResult(
                operation=operation,
                status=SymlinkStatus.ALREADY_EXISTS,
            )

        # Override if symlink points into .home directory
        if existing_target.is_relative_to(config.repo_root):
            return override_symlink(config, operation)

        # Skip if symlink points outside .home directory
        return SymlinkResult(
            operation=operation,
            status=SymlinkStatus.ALREADY_EXISTS,
        )
    except Exception:
        # Skip if symlink cannot be resolved
        return SymlinkResult(
            operation=operation,
            status=SymlinkStatus.ALREADY_EXISTS,
        )


def override_symlink(config: Config, operation: SymlinkOperation) -> SymlinkResult:
    """Override existing symlink with new target."""
    # Select status based on mode
    if config.dryrun:
        status = SymlinkStatus.OVERRIDDEN_DRYRUN
    else:
        # Remove old symlink and create new one
        operation.target_path.unlink()
        operation.target_path.symlink_to(operation.source_path)
        status = SymlinkStatus.OVERRIDDEN

    return SymlinkResult(operation=operation, status=status)


# ============================================================
# Supporting Code
# ============================================================

def print_symlink_result(result: SymlinkResult) -> None:
    """Print formatted result for a symlink operation."""
    # Select output format based on status
    if result.status == SymlinkStatus.SKIPPED_SOURCE_NOT_FOUND:
        print_error(f"[{result.table_name}] Source not found -> {result.operation.source_path}")
    elif result.status == SymlinkStatus.ALREADY_EXISTS:
        print_symlink_status(result.table_name, result.status.value, Color.GRAY, str(result.target_path), monochrome=True)
    elif result.status == SymlinkStatus.SKIPPED_NOT_SYMLINK:
        print_symlink_status(result.table_name, result.status.value, Color.YELLOW, str(result.target_path))
    elif result.status in (SymlinkStatus.CREATED, SymlinkStatus.CREATED_DRYRUN, SymlinkStatus.OVERRIDDEN, SymlinkStatus.OVERRIDDEN_DRYRUN):
        print_symlink_status(result.table_name, result.status.value, Color.GREEN, str(result.target_path))
