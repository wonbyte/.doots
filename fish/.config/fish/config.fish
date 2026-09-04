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

# PATH (guard with existence checks to avoid dead entries)
for p in $HOME/.local/bin $HOME/.cargo/bin $GOPATH/bin /usr/local/go/bin
    if test -d $p
        fish_add_path -g $p
    end
end

# Aliases (abbr in fish)
abbr -a clr clear
abbr -a v nvim
abbr -a vi nvim
abbr -a vim nvim

# Prompt (only in interactive shell)
if status is-interactive
    starship init fish | source
end
