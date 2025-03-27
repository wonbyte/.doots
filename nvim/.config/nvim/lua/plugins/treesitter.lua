return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "cpp",
        "css",
        "dockerfile",
        "fish",
        "html",
        "go",
        "javascript",
        "json",
        "lua",
        "markdown",
        "odin",
        "rust",
        "scss",
        "sql",
        "toml",
        "vim",
        "vimdoc",
        "yaml",
        "zig",
      },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
}
