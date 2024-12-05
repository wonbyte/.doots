-- Define the path to lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Clone lazy.nvim if it is not already installed
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath
  })
end

-- Prepend lazy.nvim to the runtime path
vim.opt.rtp:prepend(lazypath)

-- Set <Space> as the leader key (must be set before plugins are loaded)
vim.g.mapleader = " "

-- Look for plugins in the 'lua/plugins' directory
require("lazy").setup("plugins")

-- Load Custom Settings
require("settings")

-- Load Key Mappings
require("keymappings")

-- Load Autocommands
require("aucommands")
