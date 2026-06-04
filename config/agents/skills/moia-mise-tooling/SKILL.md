---
name: moia-mise-tooling
description: Manage developer tooling, dependencies, and tasks via mise. Use when installing tools or managing mise configuration.
---

# Mise Tooling Management

Manage all development tools, dependencies, and automation tasks through mise.

## Initial Setup

Before using this skill, ensure the mise repository is available in the system temp directory:

1. Define the checkout path: `MISE_CHECKOUT_DIR="${TMPDIR:?TMPDIR must point to the system temp directory}/codex-checkouts/jdx/mise"`
2. Check if the repository exists: `test -d "$MISE_CHECKOUT_DIR/.git"`
3. If the repository is missing, clone it: `mkdir -p "$(dirname "$MISE_CHECKOUT_DIR")" && git clone https://github.com/jdx/mise "$MISE_CHECKOUT_DIR"`
4. If the repository exists but has not been updated this session, pull latest changes: `git -C "$MISE_CHECKOUT_DIR" pull`

The repository provides reference documentation and examples for mise configuration and task patterns.

## Documentation Reference

The mise repository includes comprehensive documentation. Key areas:

### Getting Started
- **`$MISE_CHECKOUT_DIR/docs/getting-started.md`** - Installation and initial setup
  - Installation methods for different platforms (curl, brew, apt, winget)
  - Shell activation and integration setup
- **`$MISE_CHECKOUT_DIR/docs/walkthrough.md`** - Step-by-step guide through core features
  - Hands-on introduction to tools, tasks, and environments

### Configuration
- **`$MISE_CHECKOUT_DIR/docs/configuration.md`** - Complete `mise.toml` configuration reference
  - File paths and precedence rules for configuration discovery
  - Hierarchical configuration merging from system to project level
- **`$MISE_CHECKOUT_DIR/docs/configuration/environments.md`** - Environment-specific configs
  - Use `MISE_ENV` to load different configs per environment (dev, staging, prod)
- **`$MISE_CHECKOUT_DIR/docs/configuration/settings.md`** - Global settings reference
  - Customize mise behavior with settings like experimental features and defaults

### Tool Management
- **`$MISE_CHECKOUT_DIR/docs/dev-tools/index.md`** - Overview of tool installation and management
  - Install and manage development tools across multiple projects
- **`$MISE_CHECKOUT_DIR/docs/core-tools.md`** - Built-in tool support
  - Native Rust implementations for Node, Python, Go, Ruby, etc.
- **`$MISE_CHECKOUT_DIR/docs/registry.md`** - Tool registry and discovery
  - Browse available tools in the mise registry

### Backends
- **`$MISE_CHECKOUT_DIR/docs/dev-tools/backends/index.md`** - Overview of tool backends
  - Backends are package managers (npm, cargo, pipx) that install tools
- **`$MISE_CHECKOUT_DIR/docs/dev-tools/backends/github.md`** - GitHub releases backend
  - Install tools from GitHub releases with asset pattern matching
- **`$MISE_CHECKOUT_DIR/docs/dev-tools/backends/aqua.md`** - Aqua registry integration
  - Access thousands of tools from the Aqua registry
- **`$MISE_CHECKOUT_DIR/docs/dev-tools/backends/cargo.md`** - Rust cargo packages
  - Install Rust CLI tools from crates.io
- **`$MISE_CHECKOUT_DIR/docs/dev-tools/backends/npm.md`** - Node.js packages
  - Install JavaScript/TypeScript tools from npm
- **`$MISE_CHECKOUT_DIR/docs/dev-tools/backends/pipx.md`** - Python applications
  - Install isolated Python CLI tools

### Tasks
- **`$MISE_CHECKOUT_DIR/docs/tasks/index.md`** - Task system overview
  - Define project tasks like make but with parallel execution and caching
- **`$MISE_CHECKOUT_DIR/docs/tasks/toml-tasks.md`** - Tasks in `mise.toml`
  - Define tasks directly in configuration with dependencies
- **`$MISE_CHECKOUT_DIR/docs/tasks/file-tasks.md`** - Tasks as executable scripts
  - Create tasks as standalone bash scripts in `mise-tasks/` or `.mise/tasks/`
- **`$MISE_CHECKOUT_DIR/docs/tasks/running-tasks.md`** - Executing and monitoring tasks
  - Run tasks with `mise run`, watch for changes, parallel execution
- **`$MISE_CHECKOUT_DIR/docs/tasks/task-configuration.md`** - Advanced task options
  - Configure task sources, outputs, env vars, and dependencies

### Environments
- **`$MISE_CHECKOUT_DIR/docs/environments/index.md`** - Environment variable management
  - Set project-specific environment variables in `mise.toml`
  - Export variables for use with `mise exec` or `mise run`

### Troubleshooting
- **`$MISE_CHECKOUT_DIR/docs/troubleshooting.md`** - Common issues and solutions
  - Debug tool installation problems and configuration errors
- **`$MISE_CHECKOUT_DIR/docs/faq.md`** - Frequently asked questions
  - Answers to common questions about mise usage

### CLI Reference
- **`$MISE_CHECKOUT_DIR/docs/cli/index.md`** - Complete CLI command reference
  - Full documentation for all mise commands and options
