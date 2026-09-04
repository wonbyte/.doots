-- Suppress the netrw banner
vim.g.netrw_banner = 0

-- Faster UI updates
vim.o.updatetime = 300
-- 500 rather than 300: 300 was workable for two-key leader maps but the
-- config now has three-key sequences (<leader>ghs and friends for git
-- hunks, plus the existing <leader>ac / <leader>cf). At 300ms a slightly
-- hesitant third keystroke silently fires the wrong (shorter) mapping or
-- nothing at all. 500 is still snappy; the failure mode it prevents is
-- maddening to debug because it looks like the keymap is broken.
vim.o.timeoutlen = 500

-- Relative line numbers
vim.o.relativenumber = true
-- Absolute line number for the current line
vim.o.number = true

-- Minimum lines of context around the cursor
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8

-- Disable swap/backup files
vim.o.swapfile = false
vim.o.backup = false

-- Enable persistent undo (recommended)
vim.o.undofile = true

-- Ignore case when searching
vim.o.ignorecase = true
-- Override ignorecase if uppercase letters are used in the search
vim.o.smartcase = true

-- NOTE: diffopt no longer appends "iwhite" globally. Hiding whitespace-only
-- changes in EVERY diff also hides real regressions (trailing whitespace,
-- indent-only rewrites) exactly where you'd want to see them: review.
-- It is now a per-session toggle on <leader>dw (see keymappings.lua), so
-- the old behavior is one keystroke away when a noisy reindent diff needs it.

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

-- Tab and indentation settings
vim.o.tabstop = 4 -- Tab width
vim.o.softtabstop = 4 -- Number of spaces for a <Tab>
vim.o.shiftwidth = 4 -- Indent width
vim.o.expandtab = true -- Convert tabs to spaces
vim.o.autoindent = true -- Copy indent from current line when starting a new line
vim.o.smartindent = false -- Handled by Treesitter
vim.o.shiftround = true -- Round indent to the nearest shiftwidth

-- Default border for ALL floating windows (blink menu + docs, LSP hover,
-- signature help, diagnostic floats). Blink and vim.lsp both inherit this
-- on 0.11+, so you can drop the per-call border = "rounded" args elsewhere.
vim.o.winborder = "rounded"

-- Enable the display of hidden characters
vim.o.list = false
vim.o.listchars = "tab:^ ,nbsp:¬,extends:»,precedes:«,trail:•,space:·"

-- Handle different line endings (Unix, Windows, Mac)
vim.o.fileformats = "unix,dos,mac"
