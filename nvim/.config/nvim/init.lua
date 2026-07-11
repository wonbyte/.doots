-- Set <Space> as the leader key (must be set before plugins are loaded)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("settings")
require("aucommands")
require("keymappings")

-- ============================================================================
-- Plugin declarations via vim.pack (Neovim 0.12 built-in plugin manager)
-- Update plugins with :lua vim.pack.update() (then :write to confirm)
-- ============================================================================
vim.pack.add({
  -- Colorscheme
  "https://github.com/ellisonleao/gruvbox.nvim",

  -- Statusline
  "https://github.com/nvim-lualine/lualine.nvim",

  -- Treesitter
  "https://github.com/nvim-treesitter/nvim-treesitter",

  -- Telescope
  "https://github.com/nvim-telescope/telescope.nvim",
  "https://github.com/nvim-lua/plenary.nvim",
  {
    src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
  },

  -- LSP & Completion
  "https://github.com/mason-org/mason.nvim",
  { src = "https://github.com/saghen/blink.cmp", version = "v1" },
  "https://github.com/rafamadriz/friendly-snippets",
  "https://github.com/folke/lazydev.nvim",

  -- Formatting
  "https://github.com/stevearc/conform.nvim",

  -- Autopairs
  "https://github.com/windwp/nvim-autopairs",
})

-- ============================================================================
-- Plugin setup (each file calls require("plugin").setup())
-- ============================================================================
require("plugins")
