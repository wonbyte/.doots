local keymap = vim.keymap.set

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

-- Clear search highlighting
keymap("n", "<C-h>", "<cmd>noh<CR>")
-- Toggle display of hidden characters

keymap("n", "<leader>,", ":set invlist<CR>")

-- Open file explorer
keymap("n", "<leader>o", ":Ex<CR>")

-- Disable F1
keymap("n", "<F1>", "<Nop>")
keymap("i", "<F1>", "<Nop>")

-- "Very magic" regexes by default
keymap("n", "?", "?\\v")
keymap("n", "/", "/\\v")
keymap("c", "%s/", "%sm/")

-- Keep selection while indenting
keymap("v", "<", "<gv")
keymap("v", ">", ">gv")

-- Quickfix
keymap("n", "<leader>q", toggle_qf)

-- Source File
keymap("n", "<leader>s", ":source <CR>")

-- Test Files
keymap("n", "<leader>t", "<Plug>PlenaryTestFile")

-- Toggle Inlay Hints
keymap("n", "<leader>h", function()
  local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
  vim.lsp.inlay_hint.enable(not enabled)
  if enabled then
    vim.notify("Inlay hints disabled", vim.log.levels.INFO)
  else
    vim.notify("Inlay hints enabled", vim.log.levels.INFO)
  end
end)
