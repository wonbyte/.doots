-- treesitter.lua
--
-- nvim-treesitter (main branch) is a parser and query manager. Highlighting,
-- indentation, and folding are built into Neovim itself; this file only
-- installs parsers and turns those features on per buffer.
--
-- install() copies both the parser and its query files into install_dir,
-- which defaults to stdpath("data") .. "/site". That directory is already on
-- runtimepath, so Neovim finds queries/<lang>/*.scm there with no extra rtp
-- manipulation.
--
-- Re-syncing parsers when the plugin itself updates is handled by the
-- PackChanged hook in init.lua, not here.

local ts = require("nvim-treesitter")

-- 1) Enable highlighting and indentation per buffer.
--
-- vim.treesitter.start() errors if no parser exists for the buffer's
-- language, so it is wrapped in pcall. indentexpr is only set when Tree-sitter
-- actually started, leaving the filetype's default indent in place otherwise.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
  callback = function(args)
    local ok = pcall(vim.treesitter.start, args.buf)
    if ok then
      vim.bo[args.buf].indentexpr =
        "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- 2) Install missing parsers.
--
-- install() runs asynchronously and skips any language that is already
-- installed, so calling it on every startup is a no-op once the list is
-- satisfied. No need to diff against get_installed() ourselves.
local ensure_installed = {
  "bash",
  "c",
  "cpp",
  "dockerfile",
  "fish",
  "go",
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

ts.install(ensure_installed)
