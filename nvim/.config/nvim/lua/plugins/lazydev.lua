require("lazydev").setup({
  -- cmp integration defaults to true; you use blink, so turn it off.
  -- Functionally a no-op (it pcall-guards on missing nvim-cmp), but it
  -- documents that blink is the intended completion source, not cmp.
  integrations = { cmp = false },
  library = {
    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
  },
})
