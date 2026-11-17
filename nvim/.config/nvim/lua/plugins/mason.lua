-- setup() prepends Mason's bin dir to PATH and sets $MASON, so servers in
-- plugins/lsp.lua can use plain executable names ("gopls", ...).
--
-- The second registry is only used for "roslyn", the C# language server.
-- One person (GitHub: Crashdummyy) runs it; it is not Microsoft's or
-- Mason's. It is updated daily and follows the server build that VS Code's
-- C# extension uses. It repackages Microsoft's files (checked for one build
-- that Microsoft also put on nuget.org: every file was identical).
-- Mason's own registry has the server too ("roslyn-language-server"), but
-- months behind, and its current build often fails to load a project that
-- has no solution file. The first registry wins for every package name
-- that both have.
require("mason").setup({
  registries = {
    "github:mason-org/mason-registry",
    "github:Crashdummyy/mason-registry",
  },
})

-- Mason packages to keep installed. mason.nvim has no ensure_installed
-- option of its own, so this uses its registry API directly: refresh the
-- registry (async), then install anything missing. Installs run in the
-- background; a server whose package is still installing simply won't
-- attach until the next time its filetype is opened.
--
-- Mason package names differ from vim.lsp.config server names, so each line
-- notes the server in plugins/lsp.lua it backs. tsgo is deliberately absent:
-- its cmd resolves TypeScript 7+ from each project's own node_modules.
--
-- Formatters live here too: conform.lua calls them by name, and if one is
-- missing conform has nothing to run, so the whitespace-trim fallback in
-- aucommands.lua quietly takes over instead of erroring. rustfmt is the
-- exception -- it comes from rustup so it always matches the toolchain.
-- prettier is not here either: it is installed per project with npm, and
-- conform runs the copy in the project's node_modules.
local ensure_installed = {
  -- Language servers
  "gopls", -- gopls
  "json-lsp", -- jsonls (vscode-json-language-server)
  "lemminx", -- lemminx
  "lua-language-server", -- lua_ls
  "roslyn", -- roslyn_ls (C#; from the second registry above)
  "rust-analyzer", -- rust_analyzer

  -- Formatters (see conform.lua)
  "goimports", -- go
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
