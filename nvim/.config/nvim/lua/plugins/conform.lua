require("conform").setup({
  formatters_by_ft = {
    astro = { "prettier" },
    c = { "clang-format" },
    cpp = { "clang-format" },
    css = { "prettier" },
    -- goimports fixes imports AND formats in gofmt style, so a separate
    -- gofmt pass is redundant.
    go = { "goimports" },
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
  formatters = {
    -- With no .clang-format file, clang-format uses LLVM style, which
    -- indents with 2 spaces -- but C/C++ buffers here indent with 4 (see
    -- settings.lua). --fallback-style only takes a built-in style name, so
    -- look for a config file ourselves and, only when there is none, pass
    -- LLVM style with the buffer's own indent width (ctx.shiftwidth). A
    -- project's own .clang-format always wins.
    ["clang-format"] = {
      prepend_args = function(_, ctx)
        local config = vim.fs.find({ ".clang-format", "_clang-format" }, {
          upward = true,
          path = ctx.dirname,
        })[1]
        if config then
          return {}
        end
        local style = "{BasedOnStyle: LLVM, IndentWidth: %d}"
        return { "--style=" .. style:format(ctx.shiftwidth) }
      end,
    },
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

-- Format buffer. <leader>cf sits in the same "code" namespace as <leader>ca
-- (code action) and does not prefix-collide with the telescope <leader>f maps.
vim.keymap.set("n", "<leader>cf", function()
  require("conform").format({ async = true })
end, { desc = "Format buffer" })
