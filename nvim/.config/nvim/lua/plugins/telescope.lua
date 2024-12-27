return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      { "nvim-lua/popup.nvim" },
      { "nvim-lua/plenary.nvim" },
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    opts = {
      defaults = {
        layout_config = {
          horizontal = {
            -- Adjust preview window size (60% of window)
            preview_width = 0.6,
          },
          vertical = {
            -- Adjust preview height for vertical layout
            preview_height = 0.5,
          },
          -- Move prompt to the top for better ergonomics
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

        file_sorter = require("telescope.sorters").get_fuzzy_file,
        file_ignore_patterns = { ".git/", "target/" },
        path_display = { "smart" },

        file_previewer = require("telescope.previewers").vim_buffer_cat.new,
        grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
        qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,

        -- Better mappings within Telescope prompts
        mappings = {
          i = {
            ["<C-j>"] = require("telescope.actions").move_selection_next,
            ["<C-k>"] = require("telescope.actions").move_selection_previous,
            ["<C-q>"] = require("telescope.actions").send_to_qflist
              + require("telescope.actions").open_qflist,
          },
        },
      },
      pickers = {
        find_files = {
          -- Show hidden files
          hidden = false,
          -- Enable preview for `find_files`
          previewer = true,
        },
        live_grep = {
          -- Enable preview for `live_grep`
          previewer = true,
        },
      },
      extensions = {
        fzf = {
          -- Enable fuzzy matching
          fuzzy = true,
          -- Override built-in sorter
          override_generic_sorter = true,
          -- Override file sorter
          override_file_sorter = true,
          -- Case-sensitive if input contains uppercase
          case_mode = "smart_case",
        },
      },
    },
    config = function(_, opts)
      local telescope = require("telescope")
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local make_entry = require("telescope.make_entry")
      local conf = require("telescope.config").values

      local live_multigrep = function(opts)
        opts = opts or {}
        opts.cwd = opts.cwd or vim.uv.cwd()

        local finder = finders.new_async_job({
          command_generator = function(prompt)
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

            ---@diagnostic disable-next-line: deprecated
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
          cwd = opts.cwd,
        })

        pickers
          .new(opts, {
            debounce = 100,
            prompt_title = "Multi Grep",
            finder = finder,
            previewer = conf.grep_previewer(opts),
            sorter = require("telescope.sorters").empty(),
          })
          :find()
      end

      telescope.setup(opts)
      -- Load the FZF extension
      telescope.load_extension("fzf")

      vim.keymap.set(
        "n",
        "<leader>gb",
        require("telescope.builtin").git_branches
      )
      vim.keymap.set(
        "n",
        "<leader>gc",
        require("telescope.builtin").git_commits
      )
      vim.keymap.set("n", "<leader>gs", require("telescope.builtin").git_status)
      vim.keymap.set(
        "n",
        "<leader>fb",
        require("telescope.builtin").current_buffer_fuzzy_find
      )
      vim.keymap.set("n", "<leader>ff", require("telescope.builtin").find_files)
      vim.keymap.set("n", "<leader>fg", live_multigrep)
      vim.keymap.set("n", "<leader>cb", require("telescope.builtin").buffers)
      vim.keymap.set(
        "n",
        "<leader>gw",
        require("telescope.builtin").grep_string
      )
      vim.keymap.set("n", "<leader>tj", require("telescope.builtin").help_tags)
    end,
  },
}
