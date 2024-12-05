return {
  {
    "windwp/nvim-autopairs",
    -- Load when entering insert mode for better performance
    event = "InsertEnter",
    opts = {
      -- Prevent conflicts
      disable_filetype = { "TelescopePrompt", "vim" },
      -- Enable treesitter integration for better pair handling
      check_ts = true,
    },
  },
}
