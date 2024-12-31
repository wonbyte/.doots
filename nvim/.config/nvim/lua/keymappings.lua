-- Global helper for debugging
P = function(v)
  print(vim.inspect(v))
  return v
end

-- Helper to check if QF is open
local function is_qf_open()
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      return true
    end
  end
  return false
end

-- Toggle the Quickfix window (close if already open, open if closed)
local function toggle_qf()
  if is_qf_open() then
    vim.cmd("cclose")
    return
  end

  vim.schedule(function()
    local bufnr = vim.api.nvim_get_current_buf()
    local diagnostics = vim.diagnostic.get(bufnr)
    if not vim.tbl_isempty(diagnostics) then
      vim.diagnostic.setqflist()
      vim.cmd("copen")
    else
      vim.notify("No diagnostics to show in Quickfix", vim.log.levels.INFO)
    end
  end)
end

-- Auto-refresh QF on saving *if* the QF window is already open
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*",
  callback = function()
    -- Only update if QF is already open
    if is_qf_open() then
      vim.schedule(function()
        -- Update existing QF diagnostics without opening it if closed
        vim.diagnostic.setqflist({ open = false })

        -- Auto-close when empty
        if vim.tbl_isempty(vim.diagnostic.get()) then
          vim.cmd("cclose")
        end
      end)
    end
  end,
})

local keymap = vim.keymap.set

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
keymap("n", "<leader>t", "<cmd>PlenaryBustedFile %<CR>")

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
