-- Melange colorscheme. There is NO setup() and no `overrides` option: the
-- scheme is applied entirely by :colorscheme, and
-- vim.g.melange_enable_font_variants (read at load time) is its only knob.
-- Customization therefore uses the core mechanism every colorscheme
-- supports: a ColorScheme autocmd that re-applies our highlight tweaks
-- after the scheme loads. Registered BEFORE vim.cmd.colorscheme so it
-- fires on this initial load, not just on later re-sourcing.

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("MelangeOverrides", { clear = true }),
  pattern = "melange",
  callback = function()
    -- Pull colors from melange's own palette module instead of hard-coding
    -- hex values. The module path mirrors how colors/melange.lua loads it:
    -- require("melange/palettes/dark") or ".../light", keyed off
    -- 'background'. Doing it this way keeps the overrides correct for both
    -- variants and survives upstream palette adjustments.
    local ok, palette = pcall(require, "melange/palettes/" .. vim.o.background)
    if not ok then
      return
    end
    local a = palette.a -- grays: bg, float, sel, ui, com, fg

    -- Melange paints NormalFloat
    -- with a.float (#34302C dark) -- a lighter panel behind hover,
    -- signature help, and diagnostics -- and leaves FloatBorder undefined
    -- (it inherits the float background). Repaint floats with the editor
    -- background (a.bg) so the rounded 'winborder' edge is the only thing
    -- separating a float from the buffer, and give the border melange's
    -- muted ui gray as its stroke.
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = a.bg })
    vim.api.nvim_set_hl(0, "FloatBorder", { fg = a.ui, bg = a.bg })

    -- Melange leaves BlinkCmpMenu/MenuBorder/Doc/DocBorder undefined
    -- (present but commented out in its source), so blink falls back to
    -- its own defaults. Link them to the float groups above explicitly so
    -- the completion menu and docs match hover and diagnostics rather than
    -- depending on blink's fallback chain.
    vim.api.nvim_set_hl(0, "BlinkCmpMenu", { link = "NormalFloat" })
    vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { link = "FloatBorder" })
    vim.api.nvim_set_hl(0, "BlinkCmpDoc", { link = "NormalFloat" })
    vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { link = "FloatBorder" })

    -- Melange links MatchParen to Substitute (red background), so the
    -- bracket under the cursor and its partner look like an error mark.
    -- Use the subtle selection gray with bold text instead, so the pair
    -- is still easy to see but does not look like a problem.
    vim.api.nvim_set_hl(0, "MatchParen", { bg = a.sel, bold = true })

    -- NOTE: no Visual override. Melange defines Visual as a subtle raised
    -- gray (a.sel). If selections turn out to be too quiet, a loud option
    -- in this palette is its bright yellow:
    --   local b = palette.b
    --   vim.api.nvim_set_hl(0, "Visual", { bg = b.yellow, fg = a.bg })
  end,
})

vim.cmd.colorscheme("melange")
