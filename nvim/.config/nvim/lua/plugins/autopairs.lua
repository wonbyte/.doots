require("nvim-autopairs").setup({
  -- Prevent conflicts
  disable_filetype = { "TelescopePrompt", "vim" },
  -- Enable treesitter integration for better pair handling
  check_ts = true,
})
