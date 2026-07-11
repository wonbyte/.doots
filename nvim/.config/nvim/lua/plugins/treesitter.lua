-- treesitter.lua
--
-- nvim-treesitter installs parsers into stdpath("data") .. "/site/parser"
-- but it keeps its *query files* under the plugin's "runtime/queries" directory.
-- When using vim.pack with plugins under pack/*/opt, the plugin may not be on
-- runtimepath until it's required. So we:
--  1) require nvim-treesitter first (forces it onto runtimepath)
--  2) append its runtime/ dir to runtimepath so Neovim can find queries/<lang>/*.scm
--  3) start treesitter per-buffer via FileType autocmd
--  4) install missing parsers

-- 1) Force-load nvim-treesitter first (important if installed as an opt package)
require("nvim-treesitter")

-- 2) Add nvim-treesitter's runtime/ dir (where it stores queries) to runtimepath
local ts_init =
  vim.api.nvim_get_runtime_file("lua/nvim-treesitter/init.lua", false)
if #ts_init > 0 then
  local ts_runtime = vim.fn.fnamemodify(ts_init[1], ":h:h:h") .. "/runtime"
  if
    vim.fn.isdirectory(ts_runtime) == 1
    and not vim.tbl_contains(vim.opt.rtp:get(), ts_runtime)
  then
    vim.opt.rtp:append(ts_runtime)
  end
end

-- 3) Enable highlighting/indentation per buffer
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
  callback = function(args)
    local ok = pcall(vim.treesitter.start, args.buf)
    if ok then
      -- Only set this if Tree-sitter actually started for the buffer
      vim.bo[args.buf].indentexpr =
        "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- 4) Install missing parsers without reinstalling existing ones
local ensure_installed = {
  "bash",
  "c",
  "cpp",
  "dockerfile",
  "fish",
  "json",
  "javascript",
  "jsdoc",
  "lua",
  "markdown",
  "proto",
  "python",
  "rust",
  "sql",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "yaml",
}

local already_installed = require("nvim-treesitter").get_installed()
local parsers_to_install = vim
  .iter(ensure_installed)
  :filter(function(parser)
    return not vim.tbl_contains(already_installed, parser)
  end)
  :totable()

if #parsers_to_install > 0 then
  require("nvim-treesitter").install(parsers_to_install)
end
