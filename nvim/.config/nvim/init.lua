-- Set <Space> as the leader key (must be set before plugins are loaded)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("settings")
require("aucommands")
require("keymappings")

-- ============================================================================
-- Post-change hooks for plugins.
--
-- vim.pack has NO `build` field on its spec (only src/name/version/data), so
-- a `build = "make"` key is silently ignored. Build steps run from the
-- PackChanged event instead, dispatched by plugin name from the table below.
--
-- This autocmd MUST be registered BEFORE vim.pack.add() below, otherwise it
-- will not fire on the very first install (only on later updates).
--
-- ev.data.spec.name is the plugin dir name, ev.data.kind is
-- "install" | "update" | "delete", ev.data.path is its on-disk root, and
-- ev.data.active is whether the plugin is already loaded in this session.
-- ============================================================================
local pack_hooks = {
  -- Compile the native fzf sorter. :wait() runs make synchronously so the
  -- compiled libfzf is present before telescope.load_extension("fzf") is
  -- called at startup.
  ["telescope-fzf-native.nvim"] = function(ev)
    if ev.data.kind == "install" or ev.data.kind == "update" then
      vim.system({ "make" }, { cwd = ev.data.path }):wait()
    end
  end,

  -- Re-sync parsers when the plugin itself moves forward.
  --
  -- plugins/treesitter.lua only installs MISSING parsers at startup. A plugin
  -- update can bump the expected parser revisions, and update() with no
  -- arguments re-fetches only the ones whose on-disk revision is out of date
  -- (no-op when current). "install" is skipped on purpose: the first-install
  -- case is covered by ts.install() in plugins/treesitter.lua.
  ["nvim-treesitter"] = function(ev)
    if ev.data.kind == "update" then
      -- Only packadd if the plugin is not already loaded in this session.
      -- update() clears its own parsers module cache internally, so no
      -- manual package.loaded reset is needed.
      if not ev.data.active then
        vim.cmd.packadd("nvim-treesitter")
      end
      require("nvim-treesitter").update()
    end
  end,
}

vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("PackHooks", { clear = true }),
  callback = function(ev)
    local hook = pack_hooks[ev.data.spec.name]
    if hook then
      hook(ev)
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

  -- Treesitter. Parser re-sync on plugin update runs from the PackChanged
  -- hook above; parser install and per-buffer setup live in
  -- plugins/treesitter.lua.
  "https://github.com/nvim-treesitter/nvim-treesitter",

  -- Telescope
  "https://github.com/nvim-telescope/telescope.nvim",
  "https://github.com/nvim-lua/plenary.nvim",
  -- No `build` key here: the native `make` step runs from the PackChanged
  -- hook above. This entry is just a plain source string.
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
-- Plugin setup. lua/plugins/init.lua requires each plugins/*.lua file in
-- order; each one configures its plugin at require time.
-- ============================================================================
require("plugins")
