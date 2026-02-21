#==================================================
# Path
#==================================================

test -d ~/.rd/bin && fish_add_path ~/.rd/bin
fish_add_path ~/.home/cache/npm-global/bin
fish_add_path /Users/prefect/.local/bin
fish_add_path /opt/homebrew/bin
fish_add_path ~/.home/bin


#==================================================
# Environment
#==================================================

export EDITOR="code"
export VISUAL="code"

#==================================================
# Aliases
#==================================================

if test (whoami) = prefect
  alias brew="sudo -i -u karsten brew"
end
alias ai="claude -p"
alias home="~/.home/bin/home.py"


if status is-interactive

  #==================================================
  # Tools
  #==================================================

  starship init fish | source
  mise activate fish | source


  #==================================================
  # Styling
  #==================================================

  # Cursor shapes
  set -U fish_greeting ''
  set -U fish_cursor_external block
  set -U fish_cursor_default block
  set -U fish_cursor_insert block
  set -U fish_cursor_replace_one underscore
  set -U fish_cursor_visual block


  #==================================================
  # Keybindings
  #==================================================

  # fzf key bindings
  fzf_configure_bindings --directory=super-f --git_log=super-l --git_status=super-s --history=super-r --processes=super-p --variables=super-v

  # natural-selection key bindings
  if functions --query _natural_selection
    bind escape            '_natural_selection end-selection'
    bind ctrl-r            '_natural_selection history-pager'
    bind up                '_natural_selection up-or-search'
    bind down              '_natural_selection down-or-search'
    bind left              '_natural_selection backward-char'
    bind right             '_natural_selection forward-char'
    bind shift-left        '_natural_selection backward-char --is-selecting'
    bind shift-right       '_natural_selection forward-char --is-selecting'
    bind super-left        '_natural_selection beginning-of-line'
    bind super-right       '_natural_selection end-of-line'
    bind super-shift-left  '_natural_selection beginning-of-line --is-selecting'
    bind super-shift-right '_natural_selection end-of-line --is-selecting'
    bind alt-left          '_natural_selection backward-word'
    bind alt-right         '_natural_selection forward-word'
    bind alt-shift-left    '_natural_selection backward-word --is-selecting'
    bind alt-shift-right   '_natural_selection forward-word --is-selecting'
    bind delete            '_natural_selection delete-char'
    bind backspace         '_natural_selection backward-delete-char'
    bind super-delete      '_natural_selection kill-line'
    bind super-backspace   '_natural_selection backward-kill-line'
    bind alt-backspace     '_natural_selection backward-kill-word'
    bind alt-delete        '_natural_selection kill-word'
    bind super-c           '_natural_selection copy-to-clipboard'
    bind super-x           '_natural_selection cut-to-clipboard'
    bind super-v           '_natural_selection paste-from-clipboard'
    bind super-a           '_natural_selection select-all'
    bind super-z           '_natural_selection undo'
    bind super-shift-z     '_natural_selection redo'
    bind ''                kill-selection end-selection self-insert
  end
end
