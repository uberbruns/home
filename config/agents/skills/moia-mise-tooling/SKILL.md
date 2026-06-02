---
name: moia-mise-tooling
description: Manage developer tooling, dependencies, and tasks via mise. Use when installing tools or managing mise configuration.
---

# Mise Tooling Management

Manage all development tools, dependencies, and automation tasks through mise.

## Initial Setup

Before using this skill, ensure the mise repository is available locally:

1. Check if repository exists: `test -d .agents/temp/checkouts/jdx/mise`
2. If not present, clone it: `mkdir -p .agents/temp/checkouts/jdx && git clone https://github.com/jdx/mise .agents/temp/checkouts/jdx/mise`
3. If repository exists but has not been updated this session, pull latest changes: `cd .agents/temp/checkouts/jdx/mise && git pull`

The repository provides reference documentation and examples for mise configuration and task patterns.

## Documentation Reference

The mise repository includes comprehensive documentation. Key areas:

### Getting Started
- **[getting-started.md](../../../.agents/temp/checkouts/jdx/mise/docs/getting-started.md)** - Installation and initial setup
  - Installation methods for different platforms (curl, brew, apt, winget)
  - Shell activation and integration setup
- **[walkthrough.md](../../../.agents/temp/checkouts/jdx/mise/docs/walkthrough.md)** - Step-by-step guide through core features
  - Hands-on introduction to tools, tasks, and environments

### Configuration
- **[configuration.md](../../../.agents/temp/checkouts/jdx/mise/docs/configuration.md)** - Complete `mise.toml` configuration reference
  - File paths and precedence rules for configuration discovery
  - Hierarchical configuration merging from system to project level
- **[configuration/environments.md](../../../.agents/temp/checkouts/jdx/mise/docs/configuration/environments.md)** - Environment-specific configs
  - Use `MISE_ENV` to load different configs per environment (dev, staging, prod)
- **[configuration/settings.md](../../../.agents/temp/checkouts/jdx/mise/docs/configuration/settings.md)** - Global settings reference
  - Customize mise behavior with settings like experimental features and defaults

### Tool Management
- **[dev-tools/index.md](../../../.agents/temp/checkouts/jdx/mise/docs/dev-tools/index.md)** - Overview of tool installation and management
  - Install and manage development tools across multiple projects
- **[core-tools.md](../../../.agents/temp/checkouts/jdx/mise/docs/core-tools.md)** - Built-in tool support
  - Native Rust implementations for Node, Python, Go, Ruby, etc.
- **[registry.md](../../../.agents/temp/checkouts/jdx/mise/docs/registry.md)** - Tool registry and discovery
  - Browse available tools in the mise registry

### Backends
- **[dev-tools/backends/index.md](../../../.agents/temp/checkouts/jdx/mise/docs/dev-tools/backends/index.md)** - Overview of tool backends
  - Backends are package managers (npm, cargo, pipx) that install tools
- **[dev-tools/backends/github.md](../../../.agents/temp/checkouts/jdx/mise/docs/dev-tools/backends/github.md)** - GitHub releases backend
  - Install tools from GitHub releases with asset pattern matching
- **[dev-tools/backends/aqua.md](../../../.agents/temp/checkouts/jdx/mise/docs/dev-tools/backends/aqua.md)** - Aqua registry integration
  - Access thousands of tools from the Aqua registry
- **[dev-tools/backends/cargo.md](../../../.agents/temp/checkouts/jdx/mise/docs/dev-tools/backends/cargo.md)** - Rust cargo packages
  - Install Rust CLI tools from crates.io
- **[dev-tools/backends/npm.md](../../../.agents/temp/checkouts/jdx/mise/docs/dev-tools/backends/npm.md)** - Node.js packages
  - Install JavaScript/TypeScript tools from npm
- **[dev-tools/backends/pipx.md](../../../.agents/temp/checkouts/jdx/mise/docs/dev-tools/backends/pipx.md)** - Python applications
  - Install isolated Python CLI tools

### Tasks
- **[tasks/index.md](../../../.agents/temp/checkouts/jdx/mise/docs/tasks/index.md)** - Task system overview
  - Define project tasks like make but with parallel execution and caching
- **[tasks/toml-tasks.md](../../../.agents/temp/checkouts/jdx/mise/docs/tasks/toml-tasks.md)** - Tasks in `mise.toml`
  - Define tasks directly in configuration with dependencies
- **[tasks/file-tasks.md](../../../.agents/temp/checkouts/jdx/mise/docs/tasks/file-tasks.md)** - Tasks as executable scripts
  - Create tasks as standalone bash scripts in `mise-tasks/` or `.mise/tasks/`
- **[tasks/running-tasks.md](../../../.agents/temp/checkouts/jdx/mise/docs/tasks/running-tasks.md)** - Executing and monitoring tasks
  - Run tasks with `mise run`, watch for changes, parallel execution
- **[tasks/task-configuration.md](../../../.agents/temp/checkouts/jdx/mise/docs/tasks/task-configuration.md)** - Advanced task options
  - Configure task sources, outputs, env vars, and dependencies

### Environments
- **[environments/index.md](../../../.agents/temp/checkouts/jdx/mise/docs/environments/index.md)** - Environment variable management
  - Set project-specific environment variables in `mise.toml`
  - Export variables for use with `mise exec` or `mise run`

### Troubleshooting
- **[troubleshooting.md](../../../.agents/temp/checkouts/jdx/mise/docs/troubleshooting.md)** - Common issues and solutions
  - Debug tool installation problems and configuration errors
- **[faq.md](../../../.agents/temp/checkouts/jdx/mise/docs/faq.md)** - Frequently asked questions
  - Answers to common questions about mise usage

### CLI Reference
- **[cli/index.md](../../../.agents/temp/checkouts/jdx/mise/docs/cli/index.md)** - Complete CLI command reference
  - Full documentation for all mise commands and options
