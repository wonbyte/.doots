# Exports
set -Ux DOTFILES $HOME/.doots
set -Ux GOROOT /usr/local/go
set -Ux GOPATH $HOME/.go
set -Ux GPG_TTY (tty)
set -Ux LANG en_US.UTF-8
set -Ux LC_ALL en_US.UTF-8
set -Ux NVIM_BIN /usr/local/nvim/bin

# Disable greeting
set -U fish_greeting ""

# Paths
set -U fish_user_paths $HOME/.local/bin $NVIM_BIN $GOROOT/bin $HOME/.cargo/bin $GOPATH/bin

# Aliases
abbr clr clear
abbr v nvim
abbr vi nvim
abbr vim nvim

# Prompt
starship init fish | source
