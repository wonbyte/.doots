-- Reuse the same window when browsing
vim.g.netrw_banner = 0 -- Suppress the banner

-- Faster UI updates
vim.o.updatetime = 300
vim.o.timeoutlen = 300

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

-- Ignore whitespace in diffs
vim.opt.diffopt:append("iwhite")

-- Always show the sign column to prevent layout shifts
vim.o.signcolumn = "yes"

-- Column guide at 80 characters
vim.o.colorcolumn = "80"

-- Neovim 0.12 auto-detects the clipboard provider (OSC52 over SSH/tmux, pbcopy on macOS)
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

-- Enable the display of hidden characters
vim.o.list = false
vim.o.listchars = "tab:^ ,nbsp:¬,extends:»,precedes:«,trail:•,space:·"

-- Handle different line endings (Unix, Windows, Mac)
vim.o.fileformats = "unix,dos,mac"
