-- Global helper for debugging
P = function(v)
  print(vim.inspect(v))
  return v
end

-- Function to toggle the Quickfix window
local function toggle_qf()
  -- Check if a Quickfix window is currently open
  local qf_open = false
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      qf_open = true
      P(qf_open)
      break
    end
  end

  -- If the Quickfix window is open, close it
  if qf_open then
    vim.cmd("cclose")
    return
  end

  -- Use vim.schedule to execute diagnostics fetching asynchronously
  vim.schedule(function()
    -- Get all current diagnostics
    local diagnostics = vim.diagnostic.get()

    -- If diagnostics exist, populate the Quickfix list and open the window
    if not vim.tbl_isempty(diagnostics) then
      -- Populate Quickfix with diagnostics
      vim.diagnostic.setqflist()
      -- Open the Quickfix window
      vim.cmd("copen")
    else
      -- Notify the user if there are no diagnostics to show
      vim.notify("No diagnostics to show in Quickfix", vim.log.levels.INFO)
    end
  end)
end

-- Helper function for binding keymaps
local function bind(op, outer_opts)
  outer_opts = outer_opts or { noremap = true, silent = true }
  return function(lhs, rhs, opts)
    opts = vim.tbl_extend("force", outer_opts, opts or {})
    vim.keymap.set(op, lhs, rhs, opts)
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

-- Source File
nnoremap("<leader>s", ":source <CR>")

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
