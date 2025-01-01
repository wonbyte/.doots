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
        version = "v0.*",
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
          signature = { enabled = true },
        },
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
        signs = false,
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
      },
    },
    config = function(_, opts)
      local lspconfig = require("lspconfig")

      -- Apply diagnostics configuration
      vim.diagnostic.config(opts.diagnostics)

      -- Set up float handlers
      local handlers = {
        ["textDocument/hover"] = vim.lsp.with(
          vim.lsp.handlers.hover,
          { border = opts.border }
        ),
        ["textDocument/signatureHelp"] = vim.lsp.with(
          vim.lsp.handlers.signature_help,
          { border = opts.border }
        ),
      }

      -- Set up each server
      for server, server_opts in pairs(opts.servers) do
        local capabilities = require("blink.cmp").get_lsp_capabilities()

        lspconfig[server].setup(vim.tbl_deep_extend("force", {
          capabilities = capabilities,
          handlers = handlers,
        }, server_opts))
      end

      -- LspAttach AutoCommand for Buffer-Local Keybindings
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(args)
          -- Buffer-Local Mappings
          local bufnr = { buffer = args.buf }
          local builtin = require("telescope.builtin")

          vim.opt_local.omnifunc = "v:lua.vim.lsp.omnifunc"
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufnr)
          vim.keymap.set("n", "gr", builtin.lsp_references, bufnr)
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufnr)
          vim.keymap.set("n", "gT", vim.lsp.buf.type_definition, bufnr)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, bufnr)
          vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufnr)
          vim.keymap.set("n", "rn", vim.lsp.buf.rename, bufnr)
          vim.keymap.set({ "n", "v" }, "ca", vim.lsp.buf.code_action, bufnr)
          vim.keymap.set("n", "<leader>wd", builtin.lsp_document_symbols, bufnr)
        end,
      })
    end,
  },
}
