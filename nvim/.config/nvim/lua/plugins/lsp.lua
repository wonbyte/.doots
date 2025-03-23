return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "williamboman/mason.nvim",
        dependencies = {
          "williamboman/mason-lspconfig.nvim",
        },
        opts = {
          ui = {
            icons = {
              package_installed = "✓",
              package_pending = "➜",
              package_uninstalled = "✗",
            },
          },
        },
      },
      {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on Lua files
        opts = {
          library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          },
        },
      },
      {
        "saghen/blink.cmp",
        dependencies = "rafamadriz/friendly-snippets",
        version = "*",
        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
          keymap = { preset = "default" },
          appearance = {
            use_nvim_cmp_as_default = true,
            nerd_font_variant = "mono",
          },
          sources = {
            default = { "lazydev", "lsp", "path", "snippets", "buffer" },
            providers = {
              lazydev = {
                name = "LazyDev",
                module = "lazydev.integrations.blink",
                score_offset = 100, -- Make LazyDev completions top priority
              },
            },
          },
          completion = {
            menu = { border = "single" },
            documentation = { window = { border = "single" } },
          },
          fuzzy = { implementation = "prefer_rust_with_warning" },
          signature = { window = { border = "single" } },
        },
        opts_extend = { "sources.default" },
      },
    },
    opts = {
      -- Diagnostics Configuration
      diagnostics = {
        float = {
          border = "rounded",
          source = true,
        },
        virtual_text = false,
        signs = true,
        underline = false,
        update_in_insert = false,
        severity_sort = true,
      },
      -- Float Window Borders
      border = {
        { "╭", "FloatBorder" },
        { "─", "FloatBorder" },
        { "╮", "FloatBorder" },
        { "│", "FloatBorder" },
        { "╯", "FloatBorder" },
        { "─", "FloatBorder" },
        { "╰", "FloatBorder" },
        { "│", "FloatBorder" },
      },
      servers = {
        gopls = {
          settings = {
            gopls = {
              analyses = { unusedparams = true },
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
            },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = "Disable",
                keywordSnippet = "Disable",
              },
            },
          },
        },
        rust_analyzer = {
          settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
              },
              completion = {
                capable = {
                  snippets = "add_parenthesis",
                },
              },
            },
          },
        },
        zls = {
          settings = {
            semantic_tokens = "partial",
          },
        },
      },
    },
    config = function(_, opts)
      local lspconfig = require("lspconfig")

      -- Apply diagnostics configuration
      vim.diagnostic.config(opts.diagnostics)

      -- Function to wrap handlers with borders
      local function add_border(handler)
        return vim.lsp.with(handler, { border = opts.border })
      end

      -- Set up floating handlers
      local handlers = {
        ["textDocument/hover"] = add_border(vim.lsp.handlers.hover),
        ["textDocument/signatureHelp"] = add_border(
          vim.lsp.handlers.signature_help
        ),
      }

      -- Setup LSP servers
      for server, server_config in pairs(opts.servers) do
        lspconfig[server].setup(
          vim.tbl_deep_extend("force", vim.deepcopy(server_config), {
            capabilities = require("blink.cmp").get_lsp_capabilities(
              server_config.capabilities
            ),
            handlers = handlers,
          })
        )
      end

      -- AutoCommand: Buffer-local keybindings on LspAttach
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local map = vim.keymap.set
          local keymaps = {
            { mode = "n", key = "gd", action = vim.lsp.buf.definition },
            { mode = "n", key = "<C-k>", action = vim.lsp.buf.signature_help },
            { mode = "n", key = "<leader>rn", action = vim.lsp.buf.rename },
            {
              mode = { "n", "v" },
              key = "<leader>ca",
              action = vim.lsp.buf.code_action,
            },
          }

          for _, km in ipairs(keymaps) do
            map(km.mode, km.key, km.action, { buffer = bufnr })
          end
        end,
      })
    end,
  },
}
