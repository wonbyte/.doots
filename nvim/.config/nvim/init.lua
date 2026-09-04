-- Set <Space> as the leader key (must be set before plugins are loaded)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("settings")
require("aucommands")
require("keymappings")

-- ============================================================================
-- Build hooks for plugins that ship native code.
--
-- vim.pack has NO `build` field on its spec (only src/name/version/data), so
-- a `build = "make"` key is silently ignored and the native library never
-- compiles. vim.pack runs build steps through the PackChanged event instead.
--
-- This autocmd MUST be registered BEFORE vim.pack.add() below, otherwise it
-- will not fire on the very first install (only on later updates).
-- ============================================================================
vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("PackBuild", { clear = true }),
  callback = function(ev)
    -- ev.data.spec.name is the plugin dir name, ev.data.kind is
    -- "install" | "update" | "delete", ev.data.path is its on-disk root.
    local is_fzf = ev.data.spec.name == "telescope-fzf-native.nvim"
    local changed = ev.data.kind == "install" or ev.data.kind == "update"
    if is_fzf and changed then
      -- :wait() runs make synchronously so the compiled libfzf is present
      -- before telescope.load_extension("fzf") is called at startup.
      vim.system({ "make" }, { cwd = ev.data.path }):wait()
    end
  end,
})

-- ============================================================================
-- Plugin declarations via vim.pack (Neovim 0.12 built-in plugin manager)
-- Update plugins with :lua vim.pack.update() (then :write to confirm)
-- ============================================================================
vim.pack.add({
  -- Colorscheme. Melange has no setup() function -- it is configured (if at
  -- all) via vim.g.melange_enable_font_variants BEFORE :colorscheme, and
  -- customized via a ColorScheme autocmd (see plugins/colorscheme.lua).
  "https://github.com/savq/melange-nvim",

  -- Statusline
  "https://github.com/nvim-lualine/lualine.nvim",

  -- Treesitter
  "https://github.com/nvim-treesitter/nvim-treesitter",

  -- Telescope
  "https://github.com/nvim-telescope/telescope.nvim",
  "https://github.com/nvim-lua/plenary.nvim",
  -- No `build` key here: the native `make` step runs from the PackChanged
  -- autocmd above. This entry is now just a plain source string.
  "https://github.com/nvim-telescope/telescope-fzf-native.nvim",

  -- LSP & Completion
  "https://github.com/mason-org/mason.nvim",
  { src = "https://github.com/saghen/blink.cmp", version = "v1" },
  "https://github.com/rafamadriz/friendly-snippets",
  "https://github.com/folke/lazydev.nvim",

  -- JSON schema catalog for jsonls. Pure data plugin (a Lua table mapping
  -- well-known filenames like package.json / tsconfig.json to their
  -- schemas). Without it, jsonls validation only applies to files that
  -- declare a $schema key themselves. Consumed in plugins/lsp.lua.
  "https://github.com/b0o/SchemaStore.nvim",

  -- Formatting
  "https://github.com/stevearc/conform.nvim",

  -- Autopairs
  "https://github.com/windwp/nvim-autopairs",
})

-- ============================================================================
-- Plugin setup (each file calls require("plugins").setup())
-- ============================================================================
require("plugins")
