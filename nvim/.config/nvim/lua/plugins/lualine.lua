-- Diagnostics have no inline display (virtual_text, virtual_lines and
-- underline are all off in lsp.lua), so the statusline carries the counts.
-- vim.lsp.status() shows server progress messages (for example, while a
-- server loads a project). It returns "" when idle, so the component
-- disappears on its own.
local function lsp_status()
  return vim.lsp.status()
end

-- The file name as a yellow arrow block, the same shape and colors as the
-- current window in the tmux status bar: a notch on the left, a point on
-- the right. lualine cannot draw the notch itself (its separators only
-- point out of a section), so this component writes its own highlights.
-- The colors come from the melange palette, so they follow the theme.
local ARROW = "\u{E0B0}"

local function set_file_arrow_hl()
  local palette = require("melange/palettes/" .. vim.o.background)
  local yellow, dark, bar = palette.b.yellow, palette.a.bg, palette.a.float
  local hl = vim.api.nvim_set_hl
  hl(0, "LualineFileNotch", { fg = bar, bg = yellow })
  hl(0, "LualineFileName", { fg = dark, bg = yellow, bold = true })
  hl(0, "LualineFilePoint", { fg = yellow, bg = bar })
end
set_file_arrow_hl()
-- :colorscheme clears custom groups, so set them again.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("LualineFileArrow", { clear = true }),
  callback = set_file_arrow_hl,
})

local function file_arrow()
  local name = vim.fn.expand("%:t")
  if name == "" then
    name = "[No Name]"
  end
  if vim.bo.modified then
    name = name .. " [+]"
  elseif vim.bo.readonly or not vim.bo.modifiable then
    name = name .. " [-]"
  end
  -- "%" starts a statusline item, so a literal one must be doubled.
  name = name:gsub("%%", "%%%%")
  -- The leading lualine_c_normal (the bar color) is for lualine: it reads
  -- the first highlight of the next component to color the mode block's
  -- arrow, and that arrow must end on the bar, not on yellow. The "%<"
  -- (a zero-width statusline item) keeps the two groups apart; lualine
  -- reads the LAST group when several stand directly together.
  return "%#lualine_c_normal#%<%#LualineFileNotch#"
    .. ARROW
    .. "%#LualineFileName# "
    .. name
    .. " %#LualineFilePoint#"
    .. ARROW
end

require("lualine").setup({
  options = {
    theme = "melange",
    icons_enabled = false,
    component_separators = { left = "", right = "" },
    -- Powerline arrows between sections, the same two glyphs that the
    -- tmux status bar uses (U+E0B0 and U+E0B2). They need a Nerd Font or a
    -- Powerline font in the terminal.
    section_separators = { left = ARROW, right = "\u{E0B2}" },
  },
  sections = {
    lualine_a = { { "mode" } },
    -- Empty on purpose, so the mode block's arrow ends on the bar color
    -- and the file block's notch starts from it (as in tmux).
    lualine_b = {},
    -- This also replaces lualine's default here ("filename"), which would
    -- show the name a second time.
    lualine_c = { { file_arrow, padding = 0 }, "branch" },
    -- Setting lualine_x replaces its defaults, so encoding, fileformat and
    -- filetype are listed explicitly to keep them.
    lualine_x = {
      "diagnostics",
      lsp_status,
      "encoding",
      "fileformat",
      "filetype",
    },
    -- The same two blocks as the right end of the tmux bar: a dark block
    -- with light text, then a brown block with dark bold text. A function,
    -- so the colors are read again after a colorscheme or background change.
    lualine_y = {
      {
        "progress",
        color = function()
          local gray = require("melange/palettes/" .. vim.o.background).a
          return { fg = gray.com, bg = gray.sel }
        end,
      },
    },
    lualine_z = {
      {
        "location",
        color = function()
          local gray = require("melange/palettes/" .. vim.o.background).a
          return { fg = gray.bg, bg = gray.ui, gui = "bold" }
        end,
      },
    },
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
