require("conform").setup({
  formatters_by_ft = {
    css = { "prettier" },
    -- goimports fixes imports AND formats in gofmt style, so a separate
    -- gofmt pass is redundant.
    go = { "goimports" },
    graphql = { "prettier" },
    html = { "prettier" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    lua = { "stylua" },
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
  --
  -- The empty table turns the mode on; the options come from
  -- default_format_opts above. No timeout_ms here: conform's docs say it has
  -- no effect on async formatting.
  format_after_save = {},
})

-- Format buffer. <leader>cf sits in the same "code" namespace as <leader>ca
-- (code action) and does not prefix-collide with the telescope <leader>f maps.
vim.keymap.set("n", "<leader>cf", function()
  require("conform").format({ async = true })
end, { desc = "Format buffer" })
