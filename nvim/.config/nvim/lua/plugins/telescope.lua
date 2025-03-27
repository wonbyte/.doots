return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      { "nvim-lua/popup.nvim" },
      { "nvim-lua/plenary.nvim" },
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    opts = function()
      local actions = require("telescope.actions")
      local previewers = require("telescope.previewers")
      local sorters = require("telescope.sorters")

      return {
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
          prompt_prefix = " 🔍 ",
          selection_caret = " ",
          color_devicons = true,

          file_sorter = sorters.get_fuzzy_file,
          file_ignore_patterns = { ".git/", "target/" },
          path_display = { "smart" },

          file_previewer = previewers.vim_buffer_cat.new,
          grep_previewer = previewers.vim_buffer_vimgrep.new,
          qflist_previewer = previewers.vim_buffer_qflist.new,

          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              -- Chaining actions:
              ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
            },
          },
        },

        pickers = {
          find_files = {
            hidden = false,
            previewer = true,
          },
          live_grep = {
            previewer = true,
          },
        },
      }
    end,
    config = function(_, opts)
      local telescope = require("telescope")
      local finders = require("telescope.finders")
      local pickers = require("telescope.pickers")
      local make_entry = require("telescope.make_entry")
      local sorters = require("telescope.sorters")
      local conf = require("telescope.config").values
      local builtin = require("telescope.builtin")

      -- Search dotfiles using Telescope and ripgrep
      local search_dotfiles = function()
        opts = opts or {}

        local dotfiles_dir = vim.env.DOTFILES or vim.fn.expand("~/.config/nvim")

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
          entry_maker = make_entry.gen_from_file(opts),
        })

        pickers
          .new(opts, {
            prompt_title = "< Dotfiles >",
            finder = finder,
            previewer = conf.file_previewer(opts),
            sorter = sorters.get_fuzzy_file(),
          })
          :find()
      end

      -- Multi-field live grep with pattern and glob
      local live_multigrep = function()
        opts = opts or {}

        local finder = finders.new_async_job({
          command_generator = function(prompt)
            if not prompt or prompt == "" then
              return nil
            end

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
          entry_maker = make_entry.gen_from_vimgrep(opts),
        })

        pickers
          .new(opts, {
            debounce = 100,
            prompt_title = "Multi Grep",
            finder = finder,
            previewer = conf.grep_previewer(opts),
            sorter = sorters.empty(),
          })
          :find()
      end

      telescope.setup(opts)
      telescope.load_extension("fzf")

      -- Key mappings
      local keymap = vim.keymap.set

      keymap("n", "<leader>rc", search_dotfiles)
      keymap("n", "<leader>gb", builtin.git_branches)
      keymap("n", "<leader>gc", builtin.git_commits)
      keymap("n", "<leader>gs", builtin.git_status)

      keymap("n", "<leader>fb", builtin.current_buffer_fuzzy_find)
      keymap("n", "<leader>ff", builtin.find_files)
      keymap("n", "<leader>fg", live_multigrep)
      keymap("n", "<leader>cb", builtin.buffers)

      keymap("n", "<leader>gw", builtin.grep_string)
      keymap("n", "<leader>tj", builtin.help_tags)
    end,
  },
}
