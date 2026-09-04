require("blink.cmp").setup({
  appearance = { nerd_font_variant = "mono" },
  sources = {
    default = { "lazydev", "lsp", "path", "snippets", "buffer" },
    providers = {
      lazydev = {
        name = "LazyDev",
        module = "lazydev.integrations.blink",
        score_offset = 100,
      },
    },
  },
  completion = { documentation = {} },
  fuzzy = { implementation = "prefer_rust" },
  -- Off by default, per buffer.
  --
  -- blink's built-in default for `enabled` is:
  --   vim.bo.buftype ~= "prompt" and vim.b.completion ~= false
  -- That's opt-out: an unset vim.b.completion (nil) counts as ON,
  -- because `nil ~= false` evaluates true.
  --
  -- We want the opposite: opt-in. So instead of checking "not
  -- explicitly false", we check "explicitly true":
  enabled = function()
    return vim.bo.buftype ~= "prompt" and vim.b.completion == true
  end,
  -- Effect: every buffer starts with completion off, since
  -- vim.b.completion is nil until something sets it. <leader>ac in
  -- keymappings.lua already does exactly that -- it flips
  -- vim.b.completion true/false per buffer -- so the toggle keeps
  -- working, and it now works correctly on the FIRST press too (under
  -- the old opt-out default, the first press was a no-op that still
  -- printed "Autocomplete enabled", because nil already counted as on).
  -- The buftype check is kept as a defensive guard, not because it's
  -- load-bearing -- an unset vim.b.completion is already off under
  -- this logic regardless of buftype.
})
