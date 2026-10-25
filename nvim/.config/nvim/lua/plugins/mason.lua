-- setup() prepends Mason's bin dir to PATH and sets $MASON, so servers in
-- plugins/lsp.lua can use plain executable names ("jdtls", "clangd", ...).
require("mason").setup({})

-- Mason packages to keep installed. mason.nvim has no ensure_installed
-- option of its own, so this uses its registry API directly: refresh the
-- registry (async), then install anything missing. Installs run in the
-- background; a server whose package is still installing simply won't
-- attach until the next time its filetype is opened.
--
-- Mason package names differ from vim.lsp.config server names, so each line
-- notes the server in plugins/lsp.lua it backs. tsgo is deliberately absent:
-- its cmd resolves TypeScript 7+ from each project's own node_modules.
-- pylsp's plugins (pylsp-mypy, python-lsp-ruff) are pip packages, not Mason
-- packages, so they still need a manual pip install into Mason's pylsp venv.
--
-- Formatters live here too: conform.lua calls them by name, and if one is
-- missing conform has nothing to run, so the whitespace-trim fallback in
-- aucommands.lua quietly takes over instead of erroring. rustfmt is the
-- exception -- it comes from rustup so it always matches the toolchain.
local ensure_installed = {
  -- Language servers
  "clangd", -- clangd
  "gopls", -- gopls
  "jdtls", -- jdtls
  "json-lsp", -- jsonls (vscode-json-language-server)
  "lemminx", -- lemminx
  "lua-language-server", -- lua_ls
  "python-lsp-server", -- pylsp
  "ruff", -- ruff (also the Python formatter in conform.lua)
  "rust-analyzer", -- rust_analyzer

  -- Formatters (see conform.lua)
  "clang-format", -- c, cpp
  "goimports", -- go
  "prettier", -- web filetypes, json
  "stylua", -- lua
}

local registry = require("mason-registry")
registry.refresh(function()
  for _, name in ipairs(ensure_installed) do
    local ok, pkg = pcall(registry.get_package, name)
    if ok and not pkg:is_installed() then
      vim.notify("mason: installing " .. name, vim.log.levels.INFO)
      pkg:install()
    end
  end
end)
