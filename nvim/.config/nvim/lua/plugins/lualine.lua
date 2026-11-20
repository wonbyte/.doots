-- Diagnostics have no inline display (virtual_text, virtual_lines and
-- underline are all off in lsp.lua), so the statusline carries the counts.
-- vim.lsp.status() shows server progress messages (for example, while a
-- server loads a project). It returns "" when idle, so the component
-- disappears on its own.
local function lsp_status()
  return vim.lsp.status()
end

-- Arrow blocks, the same look as the tmux status bar. lualine can only
-- draw an arrow between two sections, so the blocks inside a section are
-- made here: each one is wrapped in its own highlights and arrow glyphs.
-- The colors come from the melange palette, so they follow the theme.
--
--   left side:   a notch, the text, a point      (like a tmux window)
--   right side:  a point, the text, a notch      (the mirror image)
--
-- The notch of one block and the point of the next one leave a thin gap
-- in the bar color, which is what separates the blocks.
local RIGHT_ARROW = "\u{E0B0}"
local LEFT_ARROW = "\u{E0B2}"

local function set_block_hl()
  local gray = require("melange/palettes/" .. vim.o.background).a
  local hl = vim.api.nvim_set_hl
  hl(0, "LualineBlock", { fg = gray.com, bg = gray.sel })
  hl(0, "LualineBlockBold", { fg = gray.com, bg = gray.sel, bold = true })
  -- The point: block color on the bar. The notch: bar color on the block.
  hl(0, "LualineBlockPoint", { fg = gray.sel, bg = gray.float })
  hl(0, "LualineBlockNotch", { fg = gray.float, bg = gray.sel })
end
set_block_hl()
-- :colorscheme clears custom groups, so set them again.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("LualineBlocks", { clear = true }),
  callback = set_block_hl,
})

-- lualine colors the arrow of a neighbor section from the nearest
-- highlight in this text, and that arrow must end on the bar color. So
-- each block starts and ends with lualine_c_normal (the bar). The "%(%)"
-- (an empty statusline group, zero width) keeps it apart from the next
-- group; lualine reads the LAST group when several stand directly together.
local BAR = "%#lualine_c_normal#"

-- Used as a component's `fmt`: gets the component's text, returns the
-- block. An empty text gives no block.
local function left_block(body_hl)
  return function(text)
    if text == "" then
      return ""
    end
    return BAR
      .. "%(%)%#LualineBlockNotch#"
      .. RIGHT_ARROW
      .. "%#"
      .. body_hl
      .. "# "
      .. text
      .. " %#LualineBlockPoint#"
      .. RIGHT_ARROW
      .. BAR
  end
end

local function right_block(text)
  if text == "" then
    return ""
  end
  return BAR
    .. "%(%)%#LualineBlockPoint#"
    .. LEFT_ARROW
    .. "%#LualineBlock# "
    .. text
    .. " %#LualineBlockNotch#"
    .. LEFT_ARROW
    .. BAR
end

require("lualine").setup({
  options = {
    theme = "melange",
    icons_enabled = false,
    component_separators = { left = "", right = "" },
    -- Powerline arrows between sections, the same two glyphs that the
    -- tmux status bar uses (U+E0B0 and U+E0B2). They need a Nerd Font or a
    -- Powerline font in the terminal.
    section_separators = { left = RIGHT_ARROW, right = LEFT_ARROW },
  },
  sections = {
    lualine_a = { { "mode" } },
    -- padding = 0: the blocks bring their own spaces, and they must touch
    -- for the gap between them to look right. They are in section b, not
    -- c, because a narrow window cuts section c first.
    lualine_b = {
      { "filename", fmt = left_block("LualineBlockBold"), padding = 0 },
      { "branch", fmt = left_block("LualineBlock"), padding = 0 },
    },
    -- Empty on purpose: lualine's default here is "filename", which would
    -- show the name a second time.
    lualine_c = {},
    -- Setting lualine_x replaces its defaults, so encoding, fileformat and
    -- filetype are listed explicitly to keep them.
    lualine_x = {
      "diagnostics",
      lsp_status,
      { "encoding", fmt = right_block, padding = 0 },
      { "fileformat", fmt = right_block, padding = 0 },
      { "filetype", fmt = right_block, padding = 0 },
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
