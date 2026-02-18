# .home

My personal dotfiles. Configs are stored here and symlinked onto the system. A label system controls which ones are active on a given machine.

## Setup

```sh
git clone <repo> ~/.home
cd ~/.home
cp config.example.toml config.toml
# Edit config.toml to set the labels for this machine
./bootstrap.sh
```

## Commands

| Command | Description |
|---------|-------------|
| `home install` | Create symlinks defined in `home.toml`, filtered by labels |
| `home push` | Stage all changes, generate a commit message with Claude, and push |
| `home pull` | Fetch and pull latest changes (aborts if uncommitted changes exist) |
| `home update` | Pull, run `mise install`, update Homebrew, and reload fish |

All commands support `--dryrun` to print actions without executing them.

## How It Works

### home.toml

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

Label logic:
- A plain string `"cli"` requires that label to be present
- A nested array `["macos", "linux"]` is an OR — any one of them satisfies it
- Multiple top-level elements are AND — all must be satisfied

### config.toml

Machine-local file (not committed) that declares which labels apply here:

```toml
labels = ["macos", "cli", "dev"]
```

## Configs

### Fish

Shell configuration at `~/.config/fish`. Includes:
- [fzf.fish](https://github.com/PatrickF1/fzf.fish) bindings — fuzzy search for history, files, git log, git status, processes, and variables via super key chords
- [natural-selection](https://github.com/sbrstrkkdwmdr/natural-selection) — text selection keybindings in the terminal
- Starship prompt integration
- mise activation

### Starship

Prompt config at `~/.config/starship.toml`. Shows current directory, git branch and status, Docker context, and the current time. Uses a two-line layout with a `❯` character prompt.

### Hammerspoon (macOS)

Full macOS automation via [Hammerspoon](https://www.hammerspoon.org/), symlinked to `~/.hammerspoon`. Includes:

- **App launcher + tiling** — launch and arrange apps into side-by-side layouts with the hyper key, see below
- **Window positioning hotkeys** — see below
- **Safari bookmark launcher** — hyper+`b` opens a fuzzy search over Safari bookmarks

### Ghostty

Terminal emulator config, symlinked to the platform-appropriate location (`~/Library/Application Support/com.mitchellh.ghostty` on macOS, `~/.config/ghostty` on Linux).

### mise

Tool version manager configs at `~/.config/mise/`. Tools are split into label-gated groups:

|  Label  | Tools |
|---------|-------|
| `ai`    | Claude Code |
| `dev`   | Node (LTS), Python, uv, gh, fresh-editor |
| `media` | ffmpeg, yt-dlp |
| `work`  | aws-sso |

### Xcode Color Theme (dev-apple)

Installs the [Aura Soft Dark](https://github.com/daltonmenezes/aura-theme) theme to Xcode's color themes directory.

---

## Tiling Window Manager

I use Hammerspoon to launch, focus, and arrange apps into side-by-side layouts using a **hyper key** (Cmd+Shift+Alt+Ctrl).

### App Shortcuts

I've registered apps to letter shortcuts. Press hyper+letter to focus or launch that app:

| Key | App |
|-----|-----|
| `t` | Ghostty |
| `w` | Safari |
| `e` | VS Code |
| `f` | Finder |
| `g` | Tower |
| `c` | Slack |
| `d` | Discord |
| `v` | Teams |
| `x` | Xcode |
| `nn` | Notion |
| `no` | Notes |
| `pw` | 1Password |
| `mm` | Messages |
| `mo` | Outlook |
| `ms` | Signal |
| `mw` | WhatsApp |
| `mu` | Music |
| `ph` | Photos |
| `pl` | Plex |
| `ad` | Affinity Designer |
| `ap` | Affinity Photo |
| `os` | OpenSCAD |
| `sl` | PrusaSlicer |

Multi-letter shortcuts must not share a prefix with single-letter ones — conflicting sequences are not resolved automatically.

### Tiling

Hold hyper and press multiple app keys in sequence. When hyper is released, all queued apps are tiled side-by-side on screen, dividing the width equally. Pressing the same app key multiple times increases its weight (relative width).

Press hyper+`space` between apps to force a split between tiles of the same app.

If only one app is queued, it is focused or launched without any layout being applied.

### Window Positioning

Manual window placement with hyper+number (positions are `x-offset, width` as fractions of screen width):

| Key | Position |
|-----|----------|
| `1` | Left 25% |
| `2` | Middle 75% (from 25%) |
| `3` | Left 33% |
| `4` | Middle 33% |
| `5` | Left 50% |
| `6` | Right 50% |
| `7` | Left 67% |
| `8` | Right 33% |
| `9` | Left 75% |
| `0` | Right 75% (from 25%) |
| `ß` | Full width |
| `` ´ `` | Move to next screen (maximized) |
| `delete` | Cycle windows of the current app |
