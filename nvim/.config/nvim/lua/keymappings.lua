local keymap = vim.keymap.set

-- ============================================================================
-- SEARCH & NAVIGATION
-- ============================================================================

-- Clear search highlighting on Escape.
-- <C-h> was the previous binding but it shadows the ASCII backspace code
-- (some terminals send <C-h> for <BS>) and blocks the common "navigate to
-- left split" convention if you ever add seamless tmux/split navigation.
keymap("n", "<Esc>", "<cmd>noh<CR>", { desc = "Clear search highlight" })

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
-- DIFF
-- ============================================================================

-- Toggle whitespace-insensitive diffing per session. This used to be a
-- global diffopt:append("iwhite") in settings.lua, which permanently hid
-- whitespace-only changes in every diff -- including real regressions.
-- Now the default diff shows everything and this opts INTO ignoring
-- whitespace when a noisy reindent-heavy diff calls for it.
keymap("n", "<leader>dw", function()
  local diffopt = vim.opt.diffopt:get()
  if vim.tbl_contains(diffopt, "iwhite") then
    vim.opt.diffopt:remove("iwhite")
    vim.notify("Diff: showing whitespace changes", vim.log.levels.INFO)
  else
    vim.opt.diffopt:append("iwhite")
    vim.notify("Diff: ignoring whitespace changes", vim.log.levels.INFO)
  end
end, { desc = "Toggle whitespace in diffs" })

-- ============================================================================
-- SPECIAL KEYS
-- ============================================================================

-- Disable F1
keymap({ "n", "i" }, "<F1>", "<Nop>", { desc = "Disable F1" })

-- ============================================================================
-- DEVELOPER TOOLS
-- ============================================================================

-- Source current file.
keymap("n", "<leader>so", "<cmd>source %<CR>", { desc = "Source current file" })

-- Test Files
keymap(
  "n",
  "<leader>t",
  "<cmd>PlenaryBustedFile %<CR>",
  { desc = "Run Plenary tests" }
)

-- Line diagnostics float.
keymap(
  "n",
  "<leader>e",
  vim.diagnostic.open_float,
  { desc = "Line diagnostics" }
)

-- Toggle diagnostics quickfix list.
-- Global rather than buffer-local (like <leader>e) because it must also
-- work from inside the quickfix window, which never has an LSP attached.
keymap("n", "<leader>q", function()
  -- getwininfo() lists every window; quickfix windows report quickfix == 1.
  -- Location list windows also set quickfix == 1, so loclist == 0 filters
  -- them out and we only ever close a real quickfix window.
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 and win.loclist == 0 then
      vim.cmd.cclose()
      return
    end
  end
  -- Not open: refill from current diagnostics (so it is never stale) and
  -- open it. setqflist() does both in one call.
  vim.diagnostic.setqflist()
end, { desc = "Toggle diagnostics quickfix" })

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
