local keymap = vim.keymap.set

-- ============================================================================
-- SEARCH & NAVIGATION
-- ============================================================================

-- Clear search highlighting
keymap("n", "<C-h>", "<cmd>noh<CR>", { desc = "Clear search highlight" })

-- Toggle display of hidden characters
keymap(
  "n",
  "<leader>,",
  "<cmd>set invlist<CR>",
  { desc = "Toggle hidden characters" }
)

-- Open file explorer
keymap("n", "<leader>o", "<cmd>Ex<CR>", { desc = "Open file explorer" })

-- Keep default / and ? behavior; provide very-magic alternatives
keymap("n", "<leader>/", "/\\v", { desc = "Search forward (very magic)" })
keymap("n", "<leader>?", "?\\v", { desc = "Search backward (very magic)" })
keymap("n", "<leader>sr", [[:%s/\v]], { desc = "Substitute (very magic)" })

-- ============================================================================
-- EDITING
-- ============================================================================

-- Keep selection while indenting
keymap("v", "<", "<gv", { desc = "Indent left and reselect" })
keymap("v", ">", ">gv", { desc = "Indent right and reselect" })

-- ============================================================================
-- SPECIAL KEYS
-- ============================================================================

-- Disable F1
keymap({ "n", "i" }, "<F1>", "<Nop>", { desc = "Disable F1" })

-- ============================================================================
-- DEVELOPER TOOLS
-- ============================================================================

-- Source current file
keymap("n", "<leader>s", "<cmd>source %<CR>", { desc = "Source current file" })

-- Test Files
keymap(
  "n",
  "<leader>t",
  "<cmd>PlenaryBustedFile %<CR>",
  { desc = "Run Plenary tests" }
)

keymap(
  "n",
  "<leader>e",
  vim.diagnostic.open_float,
  { desc = "Line diagnostics" }
)

-- Toggle Inlay Hints
keymap("n", "<leader>h", function()
  local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
  vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
  vim.notify(
    "Inlay hints " .. (enabled and "disabled" or "enabled"),
    vim.log.levels.INFO
  )
end, { desc = "Toggle inlay hints" })

-- Toggle Autocomplete
keymap("n", "<leader>ac", function()
  if vim.b.completion == true then
    vim.b.completion = false
    vim.notify("Autocomplete disabled", vim.log.levels.INFO)
  else
    vim.b.completion = true
    vim.notify("Autocomplete enabled", vim.log.levels.INFO)
  end
end, { desc = "Toggle autocomplete" })
