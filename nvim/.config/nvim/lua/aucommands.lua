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
    -- formatters_by_ft in conform.lua. The old list had already drifted:
    -- it skipped "markdown" (which conform does not format at all) and
    -- missed javascriptreact/typescriptreact (which conform does format).
    --
    -- list_formatters_to_run(bufnr) returns two values:
    --   1. the exact formatter list conform would run for this buffer
    --   2. a boolean: whether the LSP formatter would be used as fallback
    -- If either is truthy, a formatter owns this buffer and will normalize
    -- whitespace itself, so the regex trim below is redundant. This also
    -- handles a case the static list never could: when a formatter binary
    -- is missing from PATH, conform reports nothing to run, and the trim
    -- correctly takes over as the fallback.
    local formatters, will_use_lsp =
      require("conform").list_formatters_to_run(args.buf)
    if #formatters > 0 or will_use_lsp then
      return
    end

    -- Markdown: trailing double-space is a hard line break, so trimming
    -- would silently change rendered output. This was previously hidden
    -- inside the "conform handles it" list, which was false -- conform has
    -- no markdown formatter. Keep the exclusion, but make it explicit and
    -- give it its real reason.
    if vim.bo[args.buf].filetype == "markdown" then
      return
    end

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

-- Enable spell checking for programming buffers.
-- With Treesitter highlighting on, Neovim only spell-checks @spell captures
-- (comments and strings), so this does not flag identifiers or keywords.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "lua", "go", "python", "typescript", "rust" },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "en_us"
  end,
})

-- Highlight yanked text briefly
autocmd("TextYankPost", {
  group = augroup("YankHighlight", { clear = true }),
  desc = "Highlight yanked text briefly",
  callback = function()
    -- vim.hl.on_yank is the stable name through 0.12. Some nightlies
    -- introduced vim.hl.hl_op as a replacement; try it first so this
    -- keeps working if on_yank is eventually removed. Both take the
    -- same opts table.
    local highlight = vim.hl.hl_op or vim.hl.on_yank
    highlight({ higroup = "IncSearch", timeout = 100 })
  end,
})
