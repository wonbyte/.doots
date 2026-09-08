local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Remove trailing whitespace on save (preserve cursor/view)
autocmd("BufWritePre", {
  group = augroup("RemoveWhitespace", { clear = true }),
  pattern = "*",
  desc = "Remove trailing whitespace when conform won't format this buffer",
  callback = function(args)
    -- Ask conform what it would actually do for THIS buffer, right now,
    -- instead of maintaining a hard-coded filetype list that mirrors
    -- formatters_by_ft in conform.lua.
    --
    -- list_formatters_to_run(bufnr) returns two values:
    --   1. the exact formatter list conform would run for this buffer
    --   2. a boolean: whether the LSP formatter would be used as fallback
    -- If either is truthy, a formatter owns this buffer and will normalize
    -- whitespace itself, so the regex trim below is redundant. This also
    -- handles the case where a formatter binary is missing from PATH:
    -- conform reports nothing to run, and the trim takes over as fallback.
    local formatters, will_use_lsp =
      require("conform").list_formatters_to_run(args.buf)
    if #formatters > 0 or will_use_lsp then
      return
    end

    -- Markdown: trailing double-space is a hard line break, so trimming
    -- would silently change rendered output.
    if vim.bo[args.buf].filetype == "markdown" then
      return
    end

    -- keeppatterns: do not overwrite the last search pattern, so `n` after
    -- a save still repeats what you were actually searching for.
    -- keepjumps: do not add a jumplist entry for the substitution.
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns keepjumps %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- Remove auto comment
autocmd("FileType", {
  group = augroup("NoAutoComment", { clear = true }),
  pattern = "*",
  desc = "Disable auto-commenting on Enter and o/O",
  callback = function()
    -- r: continue comment on Enter in insert mode
    -- o: continue comment on o/O in normal mode
    -- Removing both leaves indentation alone (autoindent is on globally).
    vim.opt_local.formatoptions:remove({ "r", "o" })
  end,
})

-- Web/Config indentation
autocmd("FileType", {
  group = augroup("WebIndent", { clear = true }),
  pattern = {
    "astro",
    "css",
    "html",
    "javascript",
    "javascriptreact",
    "json",
    "jsonc",
    "lua",
    "typescript",
    "typescriptreact",
    "yaml",
  },
  desc = "2-space indentation for web/config filetypes",
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
  end,
})

-- Spell-check comments and strings in code. With Treesitter highlighting
-- active, Neovim only checks @spell captures, so identifiers and keywords
-- are never flagged.
autocmd("FileType", {
  group = augroup("CodeSpell", { clear = true }),
  pattern = {
    "c",
    "cpp",
    "go",
    "javascript",
    "javascriptreact",
    "lua",
    "python",
    "rust",
    "typescript",
    "typescriptreact",
  },
  desc = "Enable spell checking for code comments and strings",
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "en_us"
  end,
})

-- Briefly highlight yanked text.
-- vim.hl.on_yank is the 0.12 API. Nightly (0.13) renames it to vim.hl.hl_op
-- and adds a TextPutPost event; revisit when upgrading.
autocmd("TextYankPost", {
  group = augroup("YankHighlight", { clear = true }),
  desc = "Highlight yanked text briefly",
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 100 })
  end,
})
