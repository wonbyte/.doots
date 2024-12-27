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
      local conf = require("telescope.config").values

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

      -- Search dotfiles in the DOTFILES directory or fallback to Neovim config
      local search_dotfiles = function(opts)
        opts = opts or {}

        -- Determine your dotfiles directory
        local dotfiles_dir = vim.env.DOTFILES or vim.fn.expand("~/.config/nvim")

        -- Create an async finder
        local finder = finders.new_async_job({
          command_generator = function(prompt)
            -- Use ripgrep (`rg`) in "list files" mode
            -- * Include hidden files (`--hidden`)
            -- * Follow symlinks (`--follow`)
            -- * Use `--no-ignore-vcs` if you want to ignore .gitignore
            local rg_args = {
              "rg",
              "--files",
              "--hidden",
              "--follow",
            }

            -- If the user typed something, interpret it as a glob for filenames
            if prompt and prompt ~= "" then
              table.insert(rg_args, "-g")
              table.insert(rg_args, "*" .. prompt .. "*")
            end

            return rg_args
          end,

          -- We'll run `rg` inside the dotfiles directory
          cwd = dotfiles_dir,

          -- Convert each line of output to a Telescope entry
          entry_maker = make_entry.gen_from_file(opts),
        })

        -- Build the Telescope picker
        pickers
          .new(opts, {
            prompt_title = "< Dotfiles >",
            finder = finder,
            previewer = conf.file_previewer(opts),
            sorter = sorters.get_fuzzy_file(),
          })
          :find()
      end

      -- Custom multi-arg live grep
      local live_multigrep = function()
        local finder = finders.new_async_job({
          command_generator = function(prompt)
            -- Exit early if prompt is empty or nil
            if not prompt or prompt == "" then
              return nil
            end

            local pieces = vim.split(prompt, "  ")
            local args = { "rg" }

            if pieces[1] then
              table.insert(args, "-e")
              table.insert(args, pieces[1])
            end

            if pieces[2] then
              table.insert(args, "-g")
              table.insert(args, pieces[2])
            end

            return vim.tbl_flatten({
              args,
              {
                "--color=never",
                "--no-heading",
                "--with-filename",
                "--line-number",
                "--column",
                "--smart-case",
              },
            })
          end,
          entry_maker = make_entry.gen_from_vimgrep(opts),
          cwd = vim.uv.cwd(),
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
      local builtin = require("telescope.builtin")

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
