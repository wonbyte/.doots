return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      { "nvim-lua/popup.nvim" },
      { "nvim-lua/plenary.nvim" },
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
      telescope.setup(opts)
      -- Load the FZF extension
      telescope.load_extension("fzf")
    end,
  },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    -- Ensure the native extension is built
    build = "make",
  },
}
