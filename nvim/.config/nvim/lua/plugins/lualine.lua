-- Diagnostics have no inline display (virtual_text, virtual_lines and
-- underline are all off in lsp.lua), so the statusline carries the counts.
-- vim.lsp.status() shows server progress messages (for example, while a
-- server loads a project). It returns "" when idle, so the component
-- disappears on its own.
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
    -- Empty on purpose: lualine's default here is "filename", which would
    -- show the name a second time.
    lualine_c = {},
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
    -- Empty for the same reason: the defaults are "filename" and "location".
    lualine_c = {},
    lualine_x = {},
    lualine_z = { "location" },
  },
  extensions = { "quickfix" },
})

-- lualine only redraws on its own timer and on cursor/mode events, so
-- progress messages would lag. Refresh when they arrive, but at most once
-- per 100ms: a server can send many progress messages per second while it
-- loads a project. The refresh reads the newest status when it runs, so
-- no message is shown late.
local progress_timer = assert(vim.uv.new_timer())
vim.api.nvim_create_autocmd("LspProgress", {
  group = vim.api.nvim_create_augroup("LualineLspProgress", { clear = true }),
  callback = function()
    if progress_timer:is_active() then
      return
    end
    progress_timer:start(
      100,
      0,
      vim.schedule_wrap(function()
        require("lualine").refresh()
      end)
    )
  end,
})
