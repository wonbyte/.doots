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
--
-- It is also only set when the language has an "indents" query. Some
-- parsers ship none (c_sharp, dockerfile, vim, ...); for those the
-- Tree-sitter indentexpr gives no indent at all, so keep the filetype's own
-- indent (for example Neovim's indent/cs.vim).
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
  callback = function(args)
    if not pcall(vim.treesitter.start, args.buf) then
      return
    end
    local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
    if lang and vim.treesitter.query.get(lang, "indents") then
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
  "c_sharp",
  "css",
  "diff",
  "dockerfile",
  "fish",
  "gitcommit",
  "go",
  "html",
  "javascript",
  "jsdoc",
  "json",
  "lua",
  "luadoc",
  "markdown",
  -- Inline markdown (code spans, links, emphasis). Without it the markdown
  -- parser only highlights block-level structure.
  "markdown_inline",
  "proto",
  -- Used by :InspectTree / :EditQuery and the queries in after/queries/.
  "query",
  -- Highlights regex literals embedded in other languages.
  "regex",
  "rust",
  "sql",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
}

ts.install(ensure_installed)
