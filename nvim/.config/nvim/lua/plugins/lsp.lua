return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "williamboman/mason.nvim",
        dependencies = { "williamboman/mason-lspconfig.nvim" },
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
        ft = "lua", -- Load only for Lua files
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
                score_offset = 100, -- Prioritize LazyDev completions
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
        float = { border = "rounded", source = true },
        virtual_text = false,
        signs = true,
        underline = false,
        update_in_insert = false,
        severity_sort = true,
      },
      -- Float Window Borders
      border = "rounded",
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
        ols = { settings = {} },
        rust_analyzer = {
          settings = {
            ["rust-analyzer"] = {
              cargo = { allFeatures = true },
              completion = { capable = { snippets = "add_parenthesis" } },
            },
          },
        },
        zls = { settings = { semantic_tokens = "partial" } },
      },
    },
    config = function(_, opts)
      local lspconfig = require("lspconfig")
      local cmp_lsp = require("blink.cmp").get_lsp_capabilities

      -- Apply diagnostics configuration
      vim.diagnostic.config(opts.diagnostics)

      -- Function to add borders to LSP handlers
      local function add_border(handler)
        return vim.lsp.with(handler, { border = opts.border })
      end

      -- Default handlers with borders
      local handlers = {
        ["textDocument/hover"] = add_border(vim.lsp.handlers.hover),
        ["textDocument/signatureHelp"] = add_border(
          vim.lsp.handlers.signature_help
        ),
      }

      -- Set up LSP servers
      for server, server_config in pairs(opts.servers) do
        lspconfig[server].setup(vim.tbl_deep_extend("force", server_config, {
          capabilities = cmp_lsp(server_config.capabilities),
          handlers = vim.tbl_deep_extend(
            "force",
            server_config.handlers or {},
            handlers
          ),
        }))
      end

      -- Set LSP keymaps
      local function on_lsp_attach(args)
        local bufnr = args.buf
        local keymaps = {
          { "n", "gd", vim.lsp.buf.definition, "[LSP] Go to definition" },
          { "n", "<C-k>", vim.lsp.buf.signature_help, "[LSP] Signature help" },
          { "n", "<leader>rn", vim.lsp.buf.rename, "[LSP] Rename symbol" },
          {
            { "n", "v" },
            "<leader>ca",
            vim.lsp.buf.code_action,
            "[LSP] Code actions",
          },
        }

        vim.tbl_map(function(km)
          vim.keymap.set(km[1], km[2], km[3], { buffer = bufnr, desc = km[4] })
        end, keymaps)
      end

      -- AutoCommand: Buffer-local keybindings on LspAttach
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = on_lsp_attach,
      })
    end,
  },
}
