local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Remove trailing whitespace on save
local remove_whitespace_group = augroup("RemoveWhitespace", { clear = true })
autocmd("BufWritePre", {
  group = remove_whitespace_group,
  pattern = "*",
  desc = "Remove trailing whitespace before saving the file",
  command = [[:%s/\s\+$//e]],
})

-- Disable automatic commenting on new lines
local no_comment_group = augroup("NoAutoComment", { clear = true })
autocmd("BufEnter", {
  group = no_comment_group,
  pattern = "*",
  desc = "Disable automatic commenting on new lines",
  callback = function()
    vim.opt_local.formatoptions:remove({ "c", "r", "o" })
  end,
})

-- Highlight yanked text briefly
local yank_group = augroup("YankHighlight", { clear = true })
autocmd("TextYankPost", {
  group = yank_group,
  desc = "Highlight yanked text briefly",
  callback = function()
    vim.highlight.on_yank({
      higroup = "IncSearch",
      timeout = 100,
      on_visual = true,
    })
  end,
})
