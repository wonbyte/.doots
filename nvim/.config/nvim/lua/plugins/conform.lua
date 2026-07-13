require("conform").setup({
  formatters_by_ft = {
    astro = { "prettier" },
    c = { "clang-format" },
    cpp = { "clang-format" },
    css = { "prettier" },
    go = { "goimports", "gofmt" },
    html = { "prettier" },
    javascript = { "prettier" },
    json = { "prettier" },
    lua = { "stylua" },
    rust = { "rustfmt" },
    typescript = { "prettier" },
  },
  default_format_opts = {
    lsp_format = "fallback",
  },
  format_on_save = { timeout_ms = 500 },
})

vim.keymap.set("n", "<leader>f", function()
  require("conform").format({ async = true })
end, { desc = "Format buffer" })
