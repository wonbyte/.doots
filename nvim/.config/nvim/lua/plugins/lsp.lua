return {
    {
        "neovim/nvim-lspconfig",
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
                        },
                    },
                },
                lua_ls = {
                    settings = {
                        Lua = {
                            runtime = { version = "LuaJIT" },
                            workspace = {
                                checkThirdParty = false,
                                library = { vim.env.VIMRUNTIME },
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
                local capabilities = vim.lsp.protocol.make_client_capabilities()

                lspconfig[server].setup(vim.tbl_deep_extend("force", {
                    capabilities = capabilities,
                    handlers = handlers,
                }, server_opts))
            end

            -- Handle potential diagnostic-related issues
            for _, method in ipairs({
                "textDocument/diagnostic",
                "workspace/diagnostic",
            }) do
                local default_handler = vim.lsp.handlers[method]
                vim.lsp.handlers[method] = function(err, result, context, config)
                    if err ~= nil and err.code == -32802 then
                        return
                    end
                    return default_handler(err, result, context, config)
                end
            end

            -- LspAttach AutoCommand for Buffer-Local Keybindings
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
                callback = function(args)
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client.supports_method("textDocument/formatting") then
                        -- Format the current buffer on save
                        vim.api.nvim_create_autocmd("BufWritePre", {
                            buffer = args.buf,
                            callback = function()
                                vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
                            end,
                        })
                    end
                    -- Buffer-Local Mappings
                    local opts = { buffer = args.buf }
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                    vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
                    vim.keymap.set("n", "rn", vim.lsp.buf.rename, opts)
                    vim.keymap.set({ "n", "v" }, "ca", vim.lsp.buf.code_action, opts)
                    vim.keymap.set("n", "<leader>f", function()
                        vim.lsp.buf.format({ async = true })
                    end, opts)
                end,
            })
        end,
    },
}
