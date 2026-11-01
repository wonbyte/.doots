# Locale
set -gx LANG en_US.UTF-8

# Core paths
set -gx DOTFILES "$HOME/.doots"
set -gx GOPATH "$HOME/.go"

# Default editor -- used by git commit, crontab -e, sudoedit, kubectl edit, etc.
set -gx EDITOR nvim
set -gx VISUAL nvim

# Disable greeting
set -g fish_greeting ""

# PATH. fish_add_path skips dirs that do not exist, so no guard is needed.
fish_add_path -g $HOME/.local/bin $HOME/.cargo/bin $GOPATH/bin /usr/local/go/bin

# Aliases (abbr in fish)
abbr -a clr clear
abbr -a v nvim
abbr -a vi nvim
abbr -a vim nvim

# Interactive-only hooks. Run after PATH is set so tools in ~/.local/bin
# are found, and guarded so a missing tool does not print an error.
if status is-interactive
    command -q direnv; and direnv hook fish | source
    command -q starship; and starship init fish | source
end
