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

    file_sorter = sorters.get_fuzzy_file,
    file_ignore_patterns = { ".git/", "target/", "build/", ".cache/" },
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

  -- FIX: Pass the cwd to the picker_opts so make_entry builds absolute paths correctly
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
      sorter = sorters.get_fuzzy_file(),
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

      -- Note: Ensure this is a standard space inside the quotes
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
      sorter = sorters.empty(),
    })
    :find()
end

telescope.setup(opts)

-- fzf-native is optional: it needs a compiled lib. Don't hard-crash startup if missing.
pcall(telescope.load_extension, "fzf")

-- Key mappings (moved all to the bottom after functions are defined)
local keymap = vim.keymap.set

keymap("n", "<leader>rc", search_dotfiles, { desc = "Search dotfiles" })
keymap("n", "<leader>gb", builtin.git_branches, { desc = "Git branches" })
keymap("n", "<leader>gc", builtin.git_commits, { desc = "Git commits" })
keymap("n", "<leader>gs", builtin.git_status, { desc = "Git status" })

keymap(
  "n",
  "<leader>fb",
  builtin.current_buffer_fuzzy_find,
  { desc = "Fuzzy find in buffer" }
)
keymap("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
keymap("n", "<leader>fg", live_multigrep, { desc = "Live multi-grep" })
keymap("n", "<leader>cb", builtin.buffers, { desc = "List buffers" })

keymap(
  "n",
  "<leader>gw",
  builtin.grep_string,
  { desc = "Grep word under cursor" }
)
keymap("n", "<leader>tj", builtin.help_tags, { desc = "Help tags" })
