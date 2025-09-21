return {
  {
    "mason-org/mason.nvim",
    dependencies = {
      {
        "folke/lazydev.nvim",
        ft = "lua",
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
    config = function(_, opts)
      -- Setup Mason first
      require("mason").setup(opts)

      local cmp_lsp = require("blink.cmp").get_lsp_capabilities

      -- LSP server configurations
      local servers = {
        clangd = {
          cmd = { "clangd" },
          filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
          settings = {
            clangd = {
              offsetEncoding = { "utf-8", "utf-16" },
              textDocument = {
                completion = {
                  editsNearCursor = true,
                },
              },
            },
          },
        },
        gopls = {
          cmd = { "gopls" },
          filetypes = { "go", "gomod", "gowork", "gotmpl" },
          capabilities = {
            workspace = {
              didChangeWatchedFiles = { dynamicRegistration = true },
            },
          },
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
          cmd = { "lua-language-server" },
          filetypes = { "lua" },
          settings = {
            Lua = {
              completion = {
                callSnippet = "Disable",
                keywordSnippet = "Disable",
              },
            },
          },
        },
        ols = {
          cmd = { "ols" },
          filetypes = { "odin" },
          settings = {},
        },
        rust_analyzer = {
          cmd = { "rust-analyzer" },
          filetypes = { "rust" },
          settings = {
            ["rust-analyzer"] = {
              cargo = { allFeatures = true },
              completion = { capable = { snippets = "add_parenthesis" } },
            },
          },
        },
        zls = {
          cmd = { "zls" },
          filetypes = { "zig", "zir" },
          settings = { semantic_tokens = "partial" },
        },
      }

      -- Diagnostics configuration
      vim.diagnostic.config({
        float = { border = "rounded", source = true },
        virtual_text = false,
        signs = true,
        underline = false,
        update_in_insert = false,
        severity_sort = true,
      })

      -- Override default floating preview
      local orig = vim.lsp.util.open_floating_preview
      ---@diagnostic disable-next-line
      vim.lsp.util.open_floating_preview = function(contents, syntax, o, ...)
        o = o or {}
        o.border = "rounded"
        return orig(contents, syntax, o, ...)
      end

      -- Set LSP keymaps function
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

      -- Set up LSP servers using vim.lsp.config (Neovim 0.11+)
      for server_name, server_config in pairs(servers) do
        -- Configure the LSP server using vim.lsp.config
        vim.lsp.config(
          server_name,
          vim.tbl_deep_extend("force", server_config, {
            capabilities = cmp_lsp(server_config.capabilities),
          })
        )

        -- Enable the LSP server using vim.lsp.enable
        vim.lsp.enable(server_name)
      end
    end,
  },
}
