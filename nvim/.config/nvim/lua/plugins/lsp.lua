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
        ft = "lua", -- only load on lua files
        opts = {
          library = {
            -- See the configuration section for more details
            -- Load luvit types when the `vim.uv` word is found
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
            -- add lazydev to your completion providers
            default = { "lazydev", "lsp", "path", "snippets", "buffer" },
            providers = {
              lazydev = {
                name = "LazyDev",
                module = "lazydev.integrations.blink",
                -- make lazydev completions top priority (see `:h blink.cmp`)
                score_offset = 100,
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
            -- Neovim already provides basic syntax highlighting
            semantic_tokens = "partial",
          },
        },
      },
    },
    config = function(_, opts)
      local lspconfig = require("lspconfig")

      -- Apply diagnostics configuration
      vim.diagnostic.config(opts.diagnostics)

      -- Define a function to wrap handlers with borders
      local function with_border(handler)
        return vim.lsp.with(handler, { border = opts.border })
      end

      -- Set up float handlers
      local handlers = {
        ["textDocument/hover"] = with_border(vim.lsp.handlers.hover),
        ["textDocument/signatureHelp"] = with_border(
          vim.lsp.handlers.signature_help
        ),
      }

      -- Set up each LSP server
      for server, server_config in pairs(opts.servers) do
        lspconfig[server].setup(vim.tbl_deep_extend("force", server_config, {
          capabilities = require("blink.cmp").get_lsp_capabilities(
            server_config.capabilities
          ),
          handlers = handlers,
        }))
      end

      -- LspAttach AutoCommand for Buffer-Local Keybindings
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local map = vim.keymap.set

          local keymaps = {
            { "n", "gd", vim.lsp.buf.definition },
            { "n", "<C-k>", vim.lsp.buf.signature_help },
            { "n", "<leader>rn", vim.lsp.buf.rename },
            { { "n", "v" }, "<leader>ca", vim.lsp.buf.code_action },
          }

          for _, keymap in ipairs(keymaps) do
            map(keymap[1], keymap[2], keymap[3], { buffer = bufnr })
          end
        end,
      })
    end,
  },
}
