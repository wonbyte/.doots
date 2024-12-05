local builtin = require("telescope.builtin")
local M = {}

-- Search dotfiles in the DOTFILES directory or fallback to Neovim config
M.search_dotfiles = function()
  local dotfiles_dir = vim.env.DOTFILES or vim.fn.expand("~/.config/nvim")
  builtin.find_files({
    -- Updated title for clarity
    prompt_title = "< Dotfiles >",
    cwd = dotfiles_dir,
    -- Include hidden files (e.g., .gitignore)
    hidden = true,
    -- Follow symbolic links
    follow = true,
  })
end

return M
