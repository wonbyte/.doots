-- Treat .h headers as C. Neovim's default guesses C++ for .h files.
vim.filetype.add({
  extension = {
    h = "c",
  },
})
