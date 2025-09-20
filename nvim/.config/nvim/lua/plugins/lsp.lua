return {
  {
    {
      "mason-org/mason-lspconfig.nvim",
      opts = {},
      dependencies = {
        { "mason-org/mason.nvim", opts = {} },
        "neovim/nvim-lspconfig",
      },
    },
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
    config = function()
      local cmp_lsp = require("blink.cmp").get_lsp_capabilities

      -- Apply diagnostics configuration
      vim.diagnostic.config({
        float = { border = "rounded", source = true },
        virtual_text = false,
        signs = true,
        underline = false,
        update_in_insert = false,
        severity_sort = true,
      })

      -- Configure LSP servers using the new vim.lsp.config API
      vim.lsp.config.clangd = {
        cmd = { "clangd" },
        filetypes = { "c", "cpp", "objc", "objcpp" },
        capabilities = cmp_lsp(),
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
      }

      vim.lsp.config.gopls = {
        cmd = { "gopls" },
        filetypes = { "go", "gomod", "gowork", "gotmpl" },
        capabilities = vim.tbl_deep_extend("force", cmp_lsp(), {
          workspace = {
            didChangeWatchedFiles = { dynamicRegistration = true },
          },
        }),
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
      }

      vim.lsp.config.lua_ls = {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        capabilities = cmp_lsp(),
        settings = {
          Lua = {
            completion = {
              callSnippet = "Disable",
              keywordSnippet = "Disable",
            },
          },
        },
      }

      vim.lsp.config.ols = {
        cmd = { "ols" },
        filetypes = { "odin" },
        capabilities = cmp_lsp(),
        settings = {},
      }

      vim.lsp.config.rust_analyzer = {
        cmd = { "rust-analyzer" },
        filetypes = { "rust" },
        capabilities = cmp_lsp(),
        settings = {
          ["rust-analyzer"] = {
            cargo = { allFeatures = true },
            completion = { capable = { snippets = "add_parenthesis" } },
          },
        },
      }

      vim.lsp.config.zls = {
        cmd = { "zls" },
        filetypes = { "zig", "zir" },
        capabilities = cmp_lsp(),
        settings = { semantic_tokens = "partial" },
      }

      -- Enable all configured language servers
      vim.lsp.enable("clangd")
      vim.lsp.enable("gopls")
      vim.lsp.enable("lua_ls")
      vim.lsp.enable("ols")
      vim.lsp.enable("rust_analyzer")
      vim.lsp.enable("zls")

      -- Set LSP keymaps
      local function on_lsp_attach(args)
        local bufnr = args.buf
        local keymaps = {
          { "n", "gd", vim.lsp.buf.definition, "[LSP] Go to definition" },
          { "n", "<C-k>", vim.lsp.buf.signature_help, "[LSP] Signature help" },
          { "n", "<leader>rn", vim.lsp.buf.rename, "[LSP] Rename symbol" },
          { "n", "<leader>ca", vim.lsp.buf.code_action, "[LSP] Code actions" },
          { "v", "<leader>ca", vim.lsp.buf.code_action, "[LSP] Code actions" },
        }

        for _, keymap in pairs(keymaps) do
          local mode = keymap[1]
          local key = keymap[2]
          local func = keymap[3]
          local desc = keymap[4]

          vim.keymap.set(mode, key, func, { buffer = bufnr, desc = desc })
        end
      end

      -- AutoCommand: Buffer-local keybindings on LspAttach
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = on_lsp_attach,
      })
    end,
  },
}
