#!/bin/bash
set -euo pipefail

#==================================================
# Configuration
#==================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_TOML="$SCRIPT_DIR/home.toml"
CONFIG_TOML="$SCRIPT_DIR/config.toml"
DRYRUN=false

# ANSI color codes
COLOR_RESET='\033[0m'
COLOR_BOLD='\033[1m'
COLOR_CYAN='\033[36m'
COLOR_GREEN='\033[32m'
COLOR_YELLOW='\033[33m'
COLOR_BLUE='\033[34m'

#==================================================
# Output Helpers
#==================================================

echo_h1() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}# $1${COLOR_RESET}"
    echo ""
}

echo_kv() {
    local key="$1"
    local value="$2"
    echo -e "${COLOR_CYAN}${key}:${COLOR_RESET} ${value}"
}

#==================================================
# TOML Parsing Helpers
#==================================================

dasel_query() {
    local file="$1"
    local selector="$2"
    shift 2
    dasel query "$selector" -i toml "$@" < "$file"
}

get_tables() {
    # Extract all table names from home.toml
    grep -E '^\[+.+\]+$' "$HOME_TOML" | tr -d '[]' | sort -u
}

is_array_table() {
    local table="$1"
    # Check if table is defined as array of tables [[table]]
    grep -qE "^\[\[$table\]\]" "$HOME_TOML"
}

get_config_labels() {
    # Extract labels from config.toml
    dasel_query "$CONFIG_TOML" "labels" -o json 2>/dev/null || echo "[]"
}

#==================================================
# Label Matching Logic
#==================================================

check_requirement() {
    local provided_labels="$1"
    local requirement="$2"

    # Normalize requirement string
    requirement=$(echo "$requirement" | tr -d ' \n')

    if [[ "$requirement" == "["* ]]; then
        # OR requirement: at least one label must match
        local labels
        labels=$(echo "$requirement" | tr -d '[]' | tr ',' '\n' | tr -d '"')
        for label in $labels; do
            [[ -z "$label" ]] && continue
            if echo "$provided_labels" | grep -q "\"$label\""; then
                return 0
            fi
        done
        return 1
    else
        # Single label requirement: must be present
        local label
        label=$(echo "$requirement" | tr -d '"')
        if echo "$provided_labels" | grep -q "\"$label\""; then
            return 0
        fi
        return 1
    fi
}

check_labels_match() {
    local provided_labels="$1"
    local required_labels="$2"

    # Compact JSON for parsing
    local compact
    compact=$(echo "$required_labels" | tr -d ' \n')

    # Remove outer brackets
    compact="${compact#\[}"
    compact="${compact%\]}"

    # Empty requirements match everything
    [[ -z "$compact" ]] && return 0

    # Parse top-level elements (AND logic, nested arrays are OR)
    local depth=0
    local current=""
    local i=0

    while [[ $i -lt ${#compact} ]]; do
        local char="${compact:$i:1}"

        if [[ "$char" == "[" ]]; then
            ((depth++))
            current+="$char"
        elif [[ "$char" == "]" ]]; then
            ((depth--))
            current+="$char"
        elif [[ "$char" == "," ]] && [[ $depth -eq 0 ]]; then
            # Process completed top-level element
            if [[ -n "$current" ]]; then
                if ! check_requirement "$provided_labels" "$current"; then
                    return 1
                fi
            fi
            current=""
        else
            current+="$char"
        fi

        ((i++))
    done

    # Process final element
    if [[ -n "$current" ]]; then
        if ! check_requirement "$provided_labels" "$current"; then
            return 1
        fi
    fi

    return 0
}

#==================================================
# Symlink Installation
#==================================================

process_entry() {
    local table="$1"
    local selector="$2"
    local config_labels="$3"

    # Resolve source path
    local source_path
    local custom_source=""
    custom_source=$(dasel_query "$HOME_TOML" "$selector.source" 2>/dev/null | tr -d "'" || echo "")

    if [[ -n "$custom_source" ]]; then
        source_path="$SCRIPT_DIR/$custom_source"
    else
        source_path="$SCRIPT_DIR/config/$table"
    fi

    # Skip if source doesn't exist
    if [[ ! -e "$source_path" ]]; then
        return 1
    fi

    # Get entry's required labels
    local entry_labels
    entry_labels=$(dasel_query "$HOME_TOML" "$selector.labels" -o json 2>/dev/null || echo "[]")

    # Check label matching
    if [[ "$entry_labels" != "[]" ]] && [[ "$config_labels" != "[]" ]]; then
        if ! check_labels_match "$config_labels" "$entry_labels"; then
            return 1
        fi
    fi

    # Resolve target path
    local target
    target=$(dasel_query "$HOME_TOML" "$selector.target" | tr -d "'")
    target="${target//\~/$HOME}"

    # Output status
    if [[ -L "$target" ]]; then
        echo -e "[${COLOR_CYAN}$table${COLOR_RESET}] ${COLOR_BLUE}Already exists${COLOR_RESET} -> $target"
    elif [[ -e "$target" ]]; then
        echo -e "[${COLOR_CYAN}$table${COLOR_RESET}] ${COLOR_YELLOW}Skipped${COLOR_RESET} (not a symlink) -> $target"
    else
        if [[ "$DRYRUN" == true ]]; then
            echo -e "[${COLOR_CYAN}$table${COLOR_RESET}] ${COLOR_GREEN}Would create${COLOR_RESET} -> $target"
        else
            mkdir -p "$(dirname "$target")"
            ln -s "$source_path" "$target"
            echo -e "[${COLOR_CYAN}$table${COLOR_RESET}] ${COLOR_GREEN}Created${COLOR_RESET} -> $target"
        fi
    fi

    return 0
}

install_symlinks() {
    # Validate config file exists
    if [[ ! -f "$CONFIG_TOML" ]]; then
        echo "Error: config.toml not found at $CONFIG_TOML" >&2
        exit 1
    fi

    # Load configuration
    local config_labels
    config_labels=$(get_config_labels)
    local tables
    tables=$(get_tables)

    # Process each table
    for table in $tables; do
        if is_array_table "$table"; then
            # Process array of tables
            local idx=0
            while true; do
                local selector="$table[$idx]"

                # Check if array element exists
                if ! dasel_query "$HOME_TOML" "$selector.target" &>/dev/null; then
                    break
                fi

                process_entry "$table" "$selector" "$config_labels" || true

                ((idx++))
            done
        else
            # Process single table
            process_entry "$table" "$table" "$config_labels" || true
        fi
    done
}

#==================================================
# Git Push Command
#==================================================

generate_commit_message() {
    local diff_output="$1"

    # Try to use Claude if available
    if command -v claude &>/dev/null; then
        local commit_message
        commit_message=$(cat <<EOF | claude --no-cache 2>/dev/null | head -n 1
Based on the following git diff, generate a concise commit message
(50 characters or less) that describes the changes. Return only the
commit message, nothing else.

$diff_output
EOF
)

        # Return Claude's message if successful
        if [[ -n "$commit_message" ]]; then
            echo "$commit_message"
            return 0
        fi
    fi

    # Fallback to generic message
    echo "Update configuration"
}

push_changes() {
    # Navigate to repository root
    cd "$SCRIPT_DIR" || exit 1

    # Check for uncommitted changes
    if [[ -z "$(git status --porcelain)" ]]; then
        echo "No changes to commit"
        exit 0
    fi

    echo_h1 "Pushing changes"

    # Stage all changes
    git add -A
    echo -e "${COLOR_GREEN}Staged all changes${COLOR_RESET}"

    # Generate commit message
    local diff_output
    diff_output=$(git diff --cached)

    local commit_message
    if command -v claude &>/dev/null; then
        echo "Generating commit message with Claude..."
    fi
    commit_message=$(generate_commit_message "$diff_output")

    echo_kv "Commit message" "$commit_message"

    # Create commit
    git commit -m "$commit_message"
    echo -e "${COLOR_GREEN}Changes committed${COLOR_RESET}"

    # Push to remote
    git push
    echo -e "${COLOR_GREEN}Changes pushed to remote${COLOR_RESET}"
}

#==================================================
# Command Line Interface
#==================================================

COMMAND=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "${1:-}" in
        --dryrun)
            DRYRUN=true
            shift
            ;;
        install)
            COMMAND="install"
            shift
            ;;
        push)
            COMMAND="push"
            shift
            ;;
        *)
            echo "Error: Unknown argument '${1:-}'" >&2
            echo ""
            echo "Usage: home.sh [--dryrun] <command>"
            echo ""
            echo "Commands:"
            echo "  install    Create symlinks from home.toml (filtered by labels in config.toml)"
            echo "  push       Commit and push all changes with AI-generated commit message"
            echo ""
            echo "Flags:"
            echo "  --dryrun   Print actions without executing them"
            exit 1
            ;;
    esac
done

# Validate command was provided
if [[ -z "$COMMAND" ]]; then
    echo "Error: No command specified" >&2
    echo ""
    echo "Usage: home.sh [--dryrun] <command>"
    echo ""
    echo "Commands:"
    echo "  install    Create symlinks from home.toml (filtered by labels in config.toml)"
    echo "  push       Commit and push all changes with AI-generated commit message"
    echo ""
    echo "Flags:"
    echo "  --dryrun   Print actions without executing them"
    exit 1
fi

# Execute command
case "$COMMAND" in
    install)
        install_symlinks
        exit 0
        ;;
    push)
        push_changes
        exit 0
        ;;
esac
