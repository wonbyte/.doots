local telescope = require("telescope")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local make_entry = require("telescope.make_entry")
local sorters = require("telescope.sorters")
local conf = require("telescope.config").values
local builtin = require("telescope.builtin")
local actions = require("telescope.actions")

local opts = {
  defaults = {
    layout_config = {
      horizontal = {
        preview_width = 0.6,
      },
      vertical = {
        preview_height = 0.5,
      },
      prompt_position = "top",
    },
    vimgrep_arguments = {
      "rg",
      "--color=never",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
      "--smart-case",
    },
    sorting_strategy = "ascending",
    prompt_prefix = "  ",
    selection_caret = " ",

    file_ignore_patterns = {
      "build/",
      ".cache/",
      "dist/",
      ".git/",
      "node_modules/",
      "target/",
    },
    path_display = { "smart" },

    mappings = {
      i = {
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        -- Chaining actions:
        ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
      },
    },
  },
}

-- Search dotfiles using Telescope and ripgrep
local function search_dotfiles()
  local dotfiles_dir = vim.env.DOTFILES or vim.fn.expand("~/.doots")

  local picker_opts = { cwd = dotfiles_dir }

  local finder = finders.new_async_job({
    command_generator = function(prompt)
      local args = {
        "rg",
        "--files",
        "--hidden",
        "--follow",
      }

      -- Match files based on user input (as a glob)
      if prompt and prompt ~= "" then
        table.insert(args, "-g")
        table.insert(args, "*" .. prompt .. "*")
      end

      return args
    end,
    cwd = dotfiles_dir,
    entry_maker = make_entry.gen_from_file(picker_opts),
  })

  pickers
    .new(picker_opts, {
      prompt_title = "< Dotfiles >",
      finder = finder,
      previewer = conf.file_previewer(picker_opts),
      -- Use conf.file_sorter (the configured file sorter) rather than a hard
      -- coded sorters.get_fuzzy_file(). Because fzf-native overrides the file
      -- sorter, this routes the custom picker through the compiled native
      -- sorter you built with `make`, instead of the pure-Lua fuzzy fallback.
      sorter = conf.file_sorter(picker_opts),
    })
    :find()
end

-- Multi-field live grep with pattern and glob
local function live_multigrep()
  local picker_opts = {}

  local finder = finders.new_async_job({
    command_generator = function(prompt)
      if not prompt or prompt == "" then
        return nil
      end

      -- Split on a DOUBLE space (two spaces), not one. Single spaces stay
      -- part of the ripgrep pattern, so the UX is: <pattern><space><space><glob>.
      -- If you type only one space, pieces[2] stays nil and no glob is applied.
      local pieces = vim.split(prompt, "  ")
      local args = { "rg" }

      if pieces[1] and pieces[1] ~= "" then
        vim.list_extend(args, { "-e", pieces[1] })
      end

      if pieces[2] and pieces[2] ~= "" then
        vim.list_extend(args, { "-g", pieces[2] })
      end

      return vim.list_extend(args, {
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case",
      })
    end,
    cwd = vim.uv.cwd(),
    entry_maker = make_entry.gen_from_vimgrep(picker_opts),
  })

  pickers
    .new(picker_opts, {
      debounce = 100,
      prompt_title = "Multi Grep",
      finder = finder,
      previewer = conf.grep_previewer(picker_opts),
      -- Intentionally empty: ripgrep already did the matching, so telescope
      -- should display results as-is without re-sorting them. This one does
      -- NOT use fzf-native, and that is correct.
      sorter = sorters.empty(),
    })
    :find()
end

telescope.setup(opts)

-- fzf-native is optional: it needs a compiled lib. Don't hard-crash startup if missing.
pcall(telescope.load_extension, "fzf")

-- ============================================================================
-- Key mappings
-- ============================================================================
local keymap = vim.keymap.set

-- File finding -- <leader>f prefix
keymap("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
keymap("n", "<leader>fg", live_multigrep, { desc = "Live multi-grep" })
keymap("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
keymap("n", "<leader>fd", search_dotfiles, { desc = "Search dotfiles" })

-- Buffer operations -- <leader>b prefix
keymap("n", "<leader>bb", builtin.buffers, { desc = "List buffers" })
keymap(
  "n",
  "<leader>bs",
  builtin.current_buffer_fuzzy_find,
  { desc = "Buffer search" }
)

-- Git -- <leader>g prefix
keymap("n", "<leader>gb", builtin.git_branches, { desc = "Git branches" })
keymap("n", "<leader>gc", builtin.git_commits, { desc = "Git commits" })
keymap("n", "<leader>gs", builtin.git_status, { desc = "Git status" })

-- Search -- <leader>s prefix (grep_string is a search operation, not git)
keymap(
  "n",
  "<leader>sw",
  builtin.grep_string,
  { desc = "Search word under cursor" }
)
