local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Remove trailing whitespace on save (preserve cursor/view)
autocmd("BufWritePre", {
  group = augroup("RemoveWhitespace", { clear = true }),
  pattern = "*",
  desc = "Remove trailing whitespace before saving the file",
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- Remove auto comment
autocmd("FileType", {
  group = augroup("NoAutoComment", { clear = true }),
  pattern = "*",
  desc = "Disable auto-commenting while preserving indentation",
  callback = function()
    -- Remove the flags that trigger auto-commenting
    vim.opt_local.formatoptions:remove({ "r", "o" })

    -- Ensure autoindent is enabled so Neovim carries over whitespace
    vim.opt_local.autoindent = true
    -- vim.opt_local.indentexpr = ""
  end,
})

-- Highlight yanked text briefly
autocmd("TextYankPost", {
  group = augroup("YankHighlight", { clear = true }),
  desc = "Highlight yanked text briefly",
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 100 })
  end,
})
