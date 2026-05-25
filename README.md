# .home

> **Personal Repository**
> This is my personal system configuration, tailored specifically to my workflow and preferences. Feel free to browse and take inspiration, but be aware that using it directly will require significant customization for your setup.

## What This Provides

| Feature | Description |
|---------|-------------|
| **[Terminal Setup](#terminal-setup)** | [Ghostty](https://ghostty.org/) terminal setup with [Fish](https://fishshell.com/) shell and [Starship](https://starship.rs/) prompt. |
| **[Configuration Management](#configuration-management)** | Declarative symlink management with label-based filtering for multi-machine setups via custom `home` script. |
| **[Development Tools](#development-tools)** | Version-managed toolchains and utilities via [mise](https://mise.jdx.dev/). |
## Setup

```sh
git clone https://github.com/uberbruns/home ~/.home
cd ~/.home
cp config.example.toml config.toml
# Edit config.toml to set the labels for this machine
./bootstrap.sh
```

## Features

### Terminal Setup

Ghostty terminal emulator configuration with Fish shell, Starship prompt, fzf.fish keybindings for fuzzy search, natural text selection, and mise activation.

**Relevant Files:** [config/fish/config.fish](config/fish/config.fish), [config/ghostty/config](config/ghostty/config), [config/starship.toml](config/starship.toml)

### Configuration Management

Configurations are symlinked from this repository to system locations. `home.toml` defines source-to-target mappings with optional labels; `config.toml` declares the machine's active labels.

**Relevant Files:** [home.toml](home.toml), [bin/home.py](bin/home.py)

#### Commands

| Command | Description |
|---------|-------------|
| `home install` | Create symlinks defined in `home.toml`, filtered by labels |
| `home push` | Stage all changes, generate a commit message with Claude, and push |
| `home pull` | Fetch and pull latest changes (aborts if uncommitted changes exist) |
| `home discard` | Discard all local changes and untracked files |
| `home update` | Pull, run `mise install`, update Homebrew, and reload fish |

All commands support `--dry-run` to print actions without executing them.

#### home.toml

Defines symlinks to create. Each entry specifies a `target` path on the system and optionally a `source` path within the repo (defaults to `config/<table-name>`). Labels restrict an entry to machines that have matching labels.

```toml
[fish]
target = "~/.config/fish"
labels = [["macos", "linux"], "cli"]  # (macos OR linux) AND cli

[[mise]]
source = "config/mise/ai.toml"
target = "~/.config/mise/conf.d/ai.toml"
labels = ["ai"]
```

Label logic supports AND/OR combinations:
- Plain string requires the label
- Nested array is OR (any label matches)
- Multiple top-level elements are AND (all must match)

#### config.toml

Machine-local file (not committed) that declares which labels apply here:

```toml
labels = ["macos", "cli", "dev"]
```

### Development Tools

mise manages tool versions. Setting up the development environment uses the configuration management system described above—mise configuration files are symlinked with label-based filtering to control which tools are installed on each machine.

**Relevant Files:** [config/mise](config/mise)

