-- Suppress the netrw banner
vim.g.netrw_banner = 0

-- Faster UI updates (CursorHold, swap-write interval; also used by LSP)
vim.o.updatetime = 300

-- Time to wait for a mapped key sequence. Every mapping in this config is
-- two keys after leader, so the 1000ms default is more waiting than needed
-- and 300 is enough that a hesitant second keystroke still lands.
vim.o.timeoutlen = 300

-- Relative line numbers, absolute number on the current line
vim.o.relativenumber = true
vim.o.number = true

-- Minimum lines/columns of context around the cursor
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8

-- No swap files; rely on persistent undo instead
vim.o.swapfile = false
vim.o.undofile = true

-- Case-insensitive search unless the pattern contains an uppercase letter
vim.o.ignorecase = true
vim.o.smartcase = true

-- NOTE: diffopt does not append "iwhite" globally. Hiding whitespace-only
-- changes in every diff also hides real regressions (trailing whitespace,
-- indent-only rewrites) exactly where you want to see them. It is a
-- per-session toggle on <leader>dw (see keymappings.lua) instead.

-- Always show the sign column to prevent layout shifts
vim.o.signcolumn = "yes"

-- Column guide at 80 characters
vim.o.colorcolumn = "80"

-- Route yank/delete to the system clipboard via the "+" register.
--
-- Clipboard path (this is a tmux-only workflow): Neovim's provider autodetect
-- checks the $TMUX branch BEFORE OSC52, so inside tmux it selects the tmux
-- provider (`tmux load-buffer`). The actual hop to the system clipboard is done
-- by tmux, not Neovim -- `set-clipboard on` in tmux.conf forwards the tmux
-- buffer out to the terminal over OSC52 (allow-passthrough on lets it through).
--
-- Note: Neovim's own OSC52 provider is NOT used here. It is suppressed while
-- 'clipboard' is non-empty (see provider/clipboard.vim: OSC52 only auto-enables
-- when &clipboard is ''), so clipboard integration depends on always running
-- nvim inside tmux. Outside tmux on a headless host it would not work without
-- an explicit g:clipboard opt-in.
vim.o.clipboard = "unnamedplus"

-- Open splits to the right and below
vim.o.splitright = true
vim.o.splitbelow = true

-- Tab and indentation settings. 4 spaces by default; web/config filetypes
-- are overridden to 2 in aucommands.lua. 'autoindent' is on by default and
-- 'smartindent' is off by default (Treesitter handles indent), so neither
-- is set here.
vim.o.tabstop = 4 -- Tab width
vim.o.softtabstop = 4 -- Number of spaces for a <Tab>
vim.o.shiftwidth = 4 -- Indent width
vim.o.expandtab = true -- Convert tabs to spaces
vim.o.shiftround = true -- Round indent to the nearest shiftwidth

-- Default border for ALL floating windows (blink menu + docs, LSP hover,
-- signature help, diagnostic floats). Blink and vim.lsp both inherit this
-- on 0.11+, so per-call border args are not needed elsewhere.
vim.o.winborder = "rounded"

-- Hidden characters: off by default, toggled with <leader>,
vim.o.list = false
vim.o.listchars = "tab:^ ,nbsp:¬,extends:»,precedes:«,trail:•,space:·"
