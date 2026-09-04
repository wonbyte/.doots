require("conform").setup({
  formatters_by_ft = {
    astro = { "prettier" },
    c = { "clang-format" },
    cpp = { "clang-format" },
    css = { "prettier" },
    go = { "goimports", "gofmt" },
    html = { "prettier" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    lua = { "stylua" },
    -- Python: conform runs these against the `ruff` CLI directly (not the
    -- LSP client from lsp.lua) -- ruff_fix, ruff_format, and
    -- ruff_organize_imports are formatter definitions conform.nvim ships
    -- built in. This is the exact sequence Astral's own docs recommend for
    -- conform.nvim.
    python = {
      -- Fix auto-fixable lint errors (unused imports, etc).
      "ruff_fix",
      -- Run the Ruff formatter (a drop-in for black).
      "ruff_format",
      -- Sort/organize imports.
      "ruff_organize_imports",
    },
    rust = { "rustfmt" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
  },
  default_format_opts = {
    lsp_format = "fallback",
  },
  -- format_after_save instead of format_on_save: :w returns immediately and
  -- the formatter runs asynchronously afterwards. Chosen because Prettier and
  -- rustfmt under WSL2's filesystem overhead made the old synchronous hook
  -- block every save for up to its 1500ms timeout.
  --
  -- What actually happens (from conform's source, not guessed): on
  -- BufWritePost conform formats the buffer async, then re-saves it itself
  -- via vim.cmd.update(), guarded by b:conform_applying_formatting so the
  -- hook doesn't recurse. Net effect: disk always ends up formatted; the
  -- only cost is a sub-second window where the just-written file is
  -- unformatted. If some external watcher (a test runner on save) reacts
  -- to that intermediate write, switch back to format_on_save -- that is
  -- the one real downside of this mode.
  format_after_save = { timeout_ms = 1500 },
})

-- Format buffer.
-- Moved from <leader>f to <leader>cf: <leader>f was a prefix of the telescope
-- find maps (<leader>ff, <leader>fb, <leader>fg), so a plain format keystroke
-- stalled for 'timeoutlen' every time. <leader>cf sits in the same "code"
-- namespace as <leader>ca (code action) and no longer collides.
vim.keymap.set("n", "<leader>cf", function()
  require("conform").format({ async = true })
end, { desc = "Format buffer" })
