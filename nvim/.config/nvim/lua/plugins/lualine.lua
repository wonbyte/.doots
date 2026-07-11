require("lualine").setup({
  options = {
    theme = "gruvbox",
    icons_enabled = false,
    component_separators = { left = "", right = "" },
    section_separators = { left = "", right = "" },
  },
  sections = {
    lualine_a = { { "mode" } },
    lualine_b = { "filename", "branch" },
    lualine_y = { "progress" },
    lualine_z = { { "location" } },
  },
  inactive_sections = {
    lualine_a = { "filename" },
    lualine_z = { "location" },
  },
  extensions = { "quickfix" },
})
