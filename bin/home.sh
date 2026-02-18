#!/bin/bash
set -euo pipefail

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
COLOR_RED='\033[31m'

# Output helpers
echo_h1() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}# $1${COLOR_RESET}"
    echo ""
}

echo_h2() {
    echo -e "${COLOR_BOLD}## $1${COLOR_RESET}"
}

echo_kv() {
    local key="$1"
    local value="$2"
    echo -e "${COLOR_CYAN}${key}:${COLOR_RESET} ${value}"
}

echo_status_skip() {
    echo -e "${COLOR_YELLOW}Status: Skipped${COLOR_RESET} - $1"
}

echo_status_exists() {
    echo -e "${COLOR_GREEN}Status: Already exists${COLOR_RESET}"
}

echo_status_would_skip() {
    echo -e "${COLOR_YELLOW}Status: Would skip${COLOR_RESET} - $1"
}

echo_status_would_create() {
    echo -e "${COLOR_GREEN}Status: Would create symlink${COLOR_RESET}"
}

dasel_query() {
    local file="$1"
    local selector="$2"
    shift 2
    dasel query "$selector" -i toml "$@" < "$file"
}

get_tables() {
    grep -E '^\[+.+\]+$' "$HOME_TOML" | tr -d '[]' | sort -u
}

is_array_table() {
    local table="$1"
    grep -qE "^\[\[$table\]\]" "$HOME_TOML"
}

get_config_labels() {
    dasel_query "$CONFIG_TOML" "labels" -o json 2>/dev/null || echo "[]"
}

# Check if provided_labels satisfies a single requirement (string or OR-array)
# Args: provided_labels (json string), requirement (string, may be nested array marker)
# Returns: 0 if satisfied, 1 if not
check_requirement() {
    local provided_labels="$1"
    local requirement="$2"

    # Clean up the requirement
    requirement=$(echo "$requirement" | tr -d ' \n')

    if [[ "$requirement" == "["* ]]; then
        # OR requirement: at least one must be in provided
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
        # Single label requirement: must be in provided
        local label
        label=$(echo "$requirement" | tr -d '"')
        if echo "$provided_labels" | grep -q "\"$label\""; then
            return 0
        fi
        return 1
    fi
}

# Check if config labels satisfy all entry requirements
# Entry labels format: ["label1", ["or1", "or2"], "label2"]
# Top level = AND, nested arrays = OR
# Args: provided_labels (json array from config), required_labels (json array from entry)
# Returns: 0 if all requirements satisfied, 1 if any fails
check_labels_match() {
    local provided_labels="$1"
    local required_labels="$2"

    # Compact JSON to single line for easier parsing
    local compact
    compact=$(echo "$required_labels" | tr -d ' \n')

    # Remove outer brackets
    compact="${compact#\[}"
    compact="${compact%\]}"

    # If empty, match everything
    [[ -z "$compact" ]] && return 0

    # Parse top-level elements (handling nested arrays)
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
            # End of top-level element
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

    # Check last element
    if [[ -n "$current" ]]; then
        if ! check_requirement "$provided_labels" "$current"; then
            return 1
        fi
    fi

    return 0
}

# Process a single entry (table or array element)
# Args: table name, selector prefix, config_labels
# Returns: 0 if processed (matched or created), 1 if skipped
process_entry() {
    local table="$1"
    local selector="$2"
    local config_labels="$3"

    # Determine source path: use 'source' key if present, otherwise default to config/$table
    local source_path
    local custom_source
    custom_source=$(dasel_query "$HOME_TOML" "$selector.source" 2>/dev/null | tr -d "'" || true)

    if [[ -n "$custom_source" ]]; then
        source_path="$SCRIPT_DIR/$custom_source"
    else
        source_path="$SCRIPT_DIR/config/$table"
    fi

    if [[ ! -e "$source_path" ]]; then
        return 1
    fi

    local entry_labels
    entry_labels=$(dasel_query "$HOME_TOML" "$selector.labels" -o json 2>/dev/null || echo "[]")

    if [[ "$DRYRUN" == true ]]; then
        echo_h2 "$table"
        echo_kv "Required labels" "$entry_labels"
    fi

    if [[ "$entry_labels" != "[]" ]] && [[ "$config_labels" != "[]" ]]; then
        if ! check_labels_match "$config_labels" "$entry_labels"; then
            if [[ "$DRYRUN" == true ]]; then
                echo_status_skip "no matching labels"
                echo ""
            fi
            return 1
        fi
    fi

    local target
    target=$(dasel_query "$HOME_TOML" "$selector.target" | tr -d "'")
    target="${target//\~/$HOME}"

    if [[ "$DRYRUN" == true ]]; then
        echo_kv "Source" "$source_path"
        echo_kv "Target" "$target"
        if [[ -L "$target" ]]; then
            echo_status_exists
        elif [[ -e "$target" ]]; then
            echo_status_would_skip "target exists and is not a symlink"
        else
            echo_status_would_create
        fi
        echo ""
    else
        if [[ -L "$target" ]]; then
            echo "Symlink already exists: $target"
        elif [[ -e "$target" ]]; then
            echo "Warning: $target exists and is not a symlink, skipping"
        else
            mkdir -p "$(dirname "$target")"
            ln -s "$source_path" "$target"
            echo "Created symlink: $target -> $source_path"
        fi
    fi

    return 0
}

install_symlinks() {
    if [[ ! -f "$CONFIG_TOML" ]]; then
        echo "Error: config.toml not found at $CONFIG_TOML" >&2
        exit 1
    fi

    local config_labels
    config_labels=$(get_config_labels)
    local tables
    tables=$(get_tables)

    if [[ "$DRYRUN" == true ]]; then
        echo_h1 "Config"
        echo_kv "Labels" "$config_labels"
        echo ""
        echo_h1 "Symlinks"
    fi

    for table in $tables; do
        if is_array_table "$table"; then
            # Array of tables: iterate until first match
            local idx=0
            local matched=false
            while true; do
                local selector="$table[$idx]"
                # Check if index exists
                if ! dasel_query "$HOME_TOML" "$selector.target" &>/dev/null; then
                    break
                fi

                if process_entry "$table" "$selector" "$config_labels"; then
                    matched=true
                    break
                fi

                ((idx++))
            done

            if [[ "$matched" == false ]] && [[ "$DRYRUN" != true ]]; then
                echo "Skipping $table: no matching labels in any variant"
            fi
        else
            # Regular table
            if ! process_entry "$table" "$table" "$config_labels"; then
                if [[ "$DRYRUN" != true ]]; then
                    echo "Skipping $table: no matching labels"
                fi
            fi
        fi
    done
}

COMMAND=""

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
        *)
            echo "Error: Unknown argument '${1:-}'" >&2
            echo ""
            echo "Usage: home.sh [--dryrun] <command>"
            echo ""
            echo "Commands:"
            echo "  install    Create symlinks from home.toml (filtered by labels in config.toml)"
            echo ""
            echo "Flags:"
            echo "  --dryrun   Print actions without executing them"
            exit 1
            ;;
    esac
done

if [[ -z "$COMMAND" ]]; then
    echo "Error: No command specified" >&2
    echo ""
    echo "Usage: home.sh [--dryrun] <command>"
    echo ""
    echo "Commands:"
    echo "  install    Create symlinks from home.toml (filtered by labels in config.toml)"
    echo ""
    echo "Flags:"
    echo "  --dryrun   Print actions without executing them"
    exit 1
fi

case "$COMMAND" in
    install)
        install_symlinks
        exit 0
        ;;
esac
