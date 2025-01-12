-- Reuse the same window when browsing
vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0 -- Suppress the banner

-- Better completion
vim.o.completeopt = "menuone,noinsert,noselect"

-- RGB color
vim.o.termguicolors = true

-- Improve performance during macros or scripts
vim.o.lazyredraw = true

-- Adjust for light/dark themes
vim.o.background = "dark"

-- Faster UI updates
vim.o.updatetime = 300

-- Relative line numbers
vim.o.relativenumber = true
-- Absolute line number for the current line
vim.o.number = true

-- Minimum lines of context around the cursor
vim.o.scrolloff = 2
-- Height of the command line
vim.o.cmdheight = 1

-- Disable swap file
vim.o.swapfile = false
-- Disable backup file
vim.o.backup = false
-- Disable persistent undo
vim.o.undofile = false

-- Ignore case when searching
vim.o.ignorecase = true
-- Override ignorecase if uppercase letters are used in the search
vim.o.smartcase = true

-- Ignore whitespace in diffs
vim.o.diffopt = vim.o.diffopt .. ",iwhite"

-- Always show the sign column to prevent layout shifts
vim.o.signcolumn = "yes"

-- Column guide at 80 characters
vim.o.colorcolumn = "80"

-- Use system clipboard for all operations
vim.o.clipboard = "unnamedplus"

-- Ubuntu-specific clipboard handling fallback (if unnamedplus fails)
if vim.fn.has("clipboard") == 0 then
  vim.o.clipboard = ""
end

-- Tab and indentation settings
vim.o.tabstop = 4 -- Tab width
vim.o.softtabstop = 4 -- Number of spaces for a <Tab>
vim.o.shiftwidth = 4 -- Indent width
vim.o.expandtab = true -- Convert tabs to spaces
vim.o.smartindent = true -- Smart indentation
vim.o.shiftround = true -- Round indent to the nearest shiftwidth

-- Enable the display of hidden characters
vim.o.list = true
vim.o.listchars = "tab:^ ,nbsp:¬,extends:»,precedes:«,trail:•"

-- Ensure files are saved with UTF-8 encoding
vim.o.fileencoding = "utf-8"
-- Handle different line endings (Unix and Windows)
vim.o.fileformats = "unix,dos,mac"
