-- Diagnostics have no inline display (virtual_text, virtual_lines and
-- underline are all off in lsp.lua), so the statusline carries the counts.
-- vim.lsp.status() shows server progress messages -- most useful for jdtls,
-- which reports "Importing Maven project" etc. while it indexes. It returns
-- "" when idle, so the component disappears on its own.
local function lsp_status()
  return vim.lsp.status()
end

require("lualine").setup({
  options = {
    theme = "melange",
    icons_enabled = false,
    component_separators = { left = "", right = "" },
    section_separators = { left = "", right = "" },
  },
  sections = {
    lualine_a = { { "mode" } },
    lualine_b = { "filename", "branch" },
    -- Setting lualine_x replaces its defaults, so encoding, fileformat and
    -- filetype are listed explicitly to keep them.
    lualine_x = {
      "diagnostics",
      lsp_status,
      "encoding",
      "fileformat",
      "filetype",
    },
    lualine_y = { "progress" },
    lualine_z = { { "location" } },
  },
  inactive_sections = {
    lualine_a = { "filename" },
    lualine_z = { "location" },
  },
  extensions = { "quickfix" },
})

-- lualine only redraws on its own timer and on cursor/mode events, so
-- progress messages would lag. Refresh as each one arrives.
vim.api.nvim_create_autocmd("LspProgress", {
  group = vim.api.nvim_create_augroup("LualineLspProgress", { clear = true }),
  callback = function()
    require("lualine").refresh()
  end,
})
