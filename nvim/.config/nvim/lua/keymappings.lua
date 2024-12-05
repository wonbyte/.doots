-- Global helper for debugging
P = function(v)
  print(vim.inspect(v))
  return v
end

-- Helper function for binding keymaps
local function bind(op, outer_opts)
  outer_opts = outer_opts or { noremap = true, silent = true }
  return function(lhs, rhs, opts)
    opts = vim.tbl_extend("force", outer_opts, opts or {})
    vim.keymap.set(op, lhs, rhs, opts)
  end
end

-- Function to toggle the Quickfix window
local function toggle_qf()
  -- Check if a Quickfix window is open
  local qf_open = vim.iter(vim.fn.getwininfo()):find(function(win)
    return win.quickfix == 1
  end) ~= nil

  if qf_open then
    vim.cmd("cclose")
  else
    -- Populate the Quickfix list with diagnostics
    vim.diagnostic.setqflist()
    vim.cmd("copen")
  end
end

-- Keybinding helper functions
local nnoremap = bind("n")
local vnoremap = bind("v")
local inoremap = bind("i")
local cnoremap = bind("c")

-- Clear search highlighting
nnoremap("<C-h>", "<cmd>noh<CR>")
-- Toggle display of hidden characters
nnoremap("<leader>,", ":set invlist<CR>")
-- Open file explorer
nnoremap("<leader>o", ":Ex<CR>")
-- Disable F1
nnoremap("<F1>", "<Nop>")
inoremap("<F1>", "<Nop>")

-- "Very magic" regexes by default
nnoremap("?", "?\\v")
nnoremap("/", "/\\v")
cnoremap("%s/", "%sm/")

-- Keep selection while indenting
vnoremap("<", "<gv")
vnoremap(">", ">gv")

-- Quickfix
nnoremap("<leader>q", toggle_qf)

-- Telescope Integrations
nnoremap("<leader>rc", require("util.builtins").search_dotfiles)
nnoremap("<leader>gb", require("telescope.builtin").git_branches)
nnoremap("<leader>gc", require("telescope.builtin").git_commits)
nnoremap("<leader>gs", require("telescope.builtin").git_status)
nnoremap("<leader>fb", require("telescope.builtin").current_buffer_fuzzy_find)
nnoremap("<leader>ff", require("telescope.builtin").find_files)
nnoremap("<leader>fg", require("telescope.builtin").live_grep)
nnoremap("<leader>cb", require("telescope.builtin").buffers)
nnoremap("<leader>gw", require("telescope.builtin").grep_string)
nnoremap("<leader>tj", ":Telescope help_tags<CR>")

-- Test Files
nnoremap("<leader>t", "<Plug>PlenaryTestFile")

-- Toggle Inlay Hints
nnoremap("<leader>h", function()
  local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
  vim.lsp.inlay_hint.enable(not enabled)
  if enabled then
    vim.notify("Inlay hints disabled", vim.log.levels.INFO)
  else
    vim.notify("Inlay hints enabled", vim.log.levels.INFO)
  end
end)
