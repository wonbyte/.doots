-- setup() prepends Mason's bin dir to PATH and sets $MASON, so servers in
-- plugins/lsp.lua can use plain executable names ("gopls", ...).
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
--
-- Formatters live here too: conform.lua calls them by name, and if one is
-- missing conform has nothing to run, so the whitespace-trim fallback in
-- aucommands.lua quietly takes over instead of erroring. rustfmt is the
-- exception -- it comes from rustup so it always matches the toolchain.
local ensure_installed = {
  -- Language servers
  "gopls", -- gopls
  "jdtls", -- jdtls
  "json-lsp", -- jsonls (vscode-json-language-server)
  "lemminx", -- lemminx
  "lua-language-server", -- lua_ls
  "roslyn-language-server", -- roslyn_ls (C#)
  "rust-analyzer", -- rust_analyzer

  -- Formatters (see conform.lua)
  "goimports", -- go
  "prettier", -- web filetypes, json
  "stylua", -- lua
}

-- Tool Mason needs on PATH to install a package. A package is skipped while
-- its tool is missing, so Mason does not fail and retry on every start.
local requires = {
  ["roslyn-language-server"] = "dotnet",
}

-- Versions to install instead of the registry's default.
--
-- roslyn-language-server: the registry still has 5.12.0-1.26426.8, which
-- has a bug in --autoLoadProjects. In a folder with .csproj files but no
-- single .sln/.slnx at its root, the project list is usually lost and no
-- project loads (so no cross-file navigation). Fixed in dotnet/roslyn
-- commit c6cdf9f, first released in 5.13.0-1.26507.4. Remove this pin when
-- the Mason registry has that version or a newer one.
local versions = {
  ["roslyn-language-server"] = "5.13.0-1.26514.10",
}

local registry = require("mason-registry")
registry.refresh(function()
  for _, name in ipairs(ensure_installed) do
    local tool = requires[name]
    local can_install = not tool or vim.fn.executable(tool) == 1
    local ok, pkg = pcall(registry.get_package, name)
    if can_install and ok and not pkg:is_installed() then
      vim.notify("mason: installing " .. name, vim.log.levels.INFO)
      pkg:install({ version = versions[name] })
    end
  end
end)
