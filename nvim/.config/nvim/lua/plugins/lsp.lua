-- Set blink.cmp capabilities for all LSP servers (deep-merged with per-server config)
vim.lsp.config("*", {
  capabilities = vim.tbl_deep_extend(
    "force",
    require("blink.cmp").get_lsp_capabilities(),
    {
      general = {
        -- Advertise UTF-8 as most preferred. Helps servers that implement
        -- LSP 3.17 positionEncodings negotiation pick UTF-8 over the
        -- spec default (UTF-16). Servers that don't negotiate are handled
        -- per-server with offset_encoding overrides below.
        positionEncodings = { "utf-8", "utf-16" },
      },
      workspace = {
        -- Enable LSP file watching (workspace/didChangeWatchedFiles).
        -- Neovim disables this by default on Linux because its watcher
        -- backends scale poorly on very large directories. With this on,
        -- servers learn about file changes made outside Neovim (git
        -- checkout, codegen, deletes) without a buffer touch or restart.
        --
        -- Backend selection is automatic at startup: if `inotifywait`
        -- (inotify-tools) is on PATH Neovim uses the inotify backend;
        -- otherwise it falls back to libuv-watchdirs, which checkhealth
        -- flags for known performance issues. Keep inotify-tools installed.
        didChangeWatchedFiles = {
          dynamicRegistration = true,
        },
      },
    }
  ),
})

-- JSON schemas for jsonls, from SchemaStore.nvim's bundled catalog.
-- pcall-guarded so a missing plugin degrades to "no catalog" instead of
-- breaking LSP setup for every server (this file builds all configs).
-- With the catalog, jsonls matches files by name (package.json,
-- tsconfig.json, .github/workflows/*.yml's JSON cousins, etc) and
-- validates against the right schema. Without it, validation only
-- applies where the file itself declares "$schema".
local json_schemas = {}
do
  local ok, schemastore = pcall(require, "schemastore")
  if ok then
    json_schemas = schemastore.json.schemas()
  end
end

local servers = {
  clangd = {
    cmd = { "clangd" },
    filetypes = { "c", "cpp", "objc", "objcpp" },
    root_markers = {
      "compile_commands.json",
      "compile_flags.txt",
      ".clangd",
      ".git",
    },
    init_options = {
      offsetEncoding = "utf-8",
    },
  },
  -- Go
  gopls = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork" },
    root_markers = { "go.work", "go.mod", ".git" },
    settings = {
      gopls = {
        analyses = {
          unusedparams = true,
          shadow = true,
        },
        staticcheck = true,
        -- gofumpt is a stricter superset of gofmt; set to true if you
        -- use gofumpt, otherwise leave false to match conform's gofmt.
        gofumpt = false,
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
  -- JSON (installed via Mason as "json-lsp"; executable links as vscode-json-language-server)
  jsonls = {
    cmd = { "vscode-json-language-server", "--stdio" },
    filetypes = { "json", "jsonc" },
    root_markers = { ".git" },
    settings = {
      json = {
        -- SchemaStore catalog resolved above. Empty table if the plugin
        -- is missing, which jsonls treats the same as "no schemas
        -- configured" -- prior behavior, not an error.
        schemas = json_schemas,
        validate = { enable = true },
      },
    },
  },
  lua_ls = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = {
      ".luarc.json",
      ".luarc.jsonc",
      ".stylua.toml",
      "stylua.toml",
      ".git",
    },
    settings = {
      Lua = {
        completion = {
          callSnippet = "Disable",
          keywordSnippet = "Disable",
        },
      },
    },
  },
  -- Python completions, hover, go-to-definition (via jedi), and type
  -- checking (via mypy). Runs alongside ruff's standalone server, which
  -- handles linting and formatting. pylsp is installed via Mason;
  -- pylsp-mypy and python-lsp-ruff are pip-installed into Mason's pylsp
  -- venv (they are not Mason packages).
  pylsp = {
    cmd = { "pylsp" },
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "setup.py", "setup.cfg", ".git" },
    -- Force UTF-8 to match ruff. pylsp doesn't implement the LSP 3.17
    -- positionEncodings negotiation, so it defaults to UTF-16. This
    -- client-side override makes neovim treat pylsp's offsets as UTF-8,
    -- eliminating the mixed encoding warning.
    offset_encoding = "utf-8",
    settings = {
      pylsp = {
        plugins = {
          -- ruff runs as a standalone server (see ruff entry below),
          -- so disable pylsp's ruff plugin to avoid duplicate diagnostics.
          ruff = { enabled = false },
          -- mypy for type checking (installed into Mason's pylsp venv).
          pylsp_mypy = { enabled = true },
          -- Disable every built-in linter/formatter that ruff replaces.
          pycodestyle = { enabled = false },
          pyflakes = { enabled = false },
          mccabe = { enabled = false },
          autopep8 = { enabled = false },
          yapf = { enabled = false },
        },
      },
    },
  },
  -- Python linting. Replaces pyflakes/pycodestyle/mccabe -- the exact
  -- plugins that used to be disabled in this file's old pylsp config.
  -- This is Ruff's native Rust server ("ruff server"), not the deprecated
  -- "ruff-lsp" Python package.
  ruff = {
    cmd = { "ruff", "server" },
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
    init_options = {
      settings = {
        lineLength = 80,
      },
    },
  },
  rust_analyzer = {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_markers = { "Cargo.toml", "rust-project.json", ".git" },
    settings = {
      ["rust-analyzer"] = {
        cargo = { allFeatures = true },
        -- The fix: 'checkOnSave' is implicitly true, just define the 'check' command
        check = { command = "clippy" },
        completion = { callable = { snippets = "add_parentheses" } },
      },
    },
  },
  -- TypeScript / JavaScript (TS 7 native Go-based LSP, invoked as `tsc --lsp`).
  tsgo = {
    -- cmd as a function instead of a list: this resolves the workspace's OWN
    -- tsc at server-start time, so each project uses the TypeScript version it
    -- pins -- what `npx tsc` did, minus the npx wrapper's per-spawn overhead.
    --
    -- When cmd is a function it does NOT return a command list; it must start
    -- the RPC client itself via vim.lsp.rpc.start(cmd, dispatchers).
    cmd = function(dispatchers, config)
      -- Resolve from the buffer being edited, not config.root_dir or cwd:
      -- both proved unreliable at cmd-invocation time and produced a bare
      -- "tsc" that was not on PATH. Walking upward from the actual file is
      -- independent of both.
      local bufname = vim.api.nvim_buf_get_name(0)
      local start = (bufname ~= "") and vim.fs.dirname(bufname) or vim.uv.cwd()

      -- Every node_modules going up from the file, nearest first.
      -- limit = math.huge covers monorepos where tsc is hoisted to a
      -- node_modules higher up than the nearest package-level one.
      local nm_dirs = vim.fs.find("node_modules", {
        upward = true,
        type = "directory",
        path = start,
        limit = math.huge,
      })

      -- TS 7.0 stable (the `typescript` package) ships `tsc`;
      -- @typescript/native-preview ships `tsgo`. Probe both, use the first
      -- .bin that actually has one. fs_stat follows the symlink, so this
      -- checks the real target (e.g. .bin/tsc -> ../typescript/bin/tsc).
      local bin
      for _, nm in ipairs(nm_dirs) do
        for _, name in ipairs({ "tsc", "tsgo" }) do
          local p = nm .. "/.bin/" .. name
          if vim.uv.fs_stat(p) then
            bin = p
            break
          end
        end
        if bin then
          break
        end
      end

      -- No workspace-local binary anywhere up the tree: last resort is a
      -- global tsgo/tsc on PATH (fresh clone before `npm install`, etc).
      if not bin then
        for _, name in ipairs({ "tsgo", "tsc" }) do
          if vim.fn.executable(name) == 1 then
            bin = name
            break
          end
        end
      end

      -- Nothing local OR global. cmd-as-function MUST return an rpc client:
      -- client.lua assigns the return value to self.rpc with no nil check,
      -- so returning nil produces a cryptic nil-index traceback later.
      -- error() here surfaces a readable message at the actual failure point.
      if not bin then
        error("tsgo: no local or global tsc/tsgo found upward from " .. start)
      end

      return vim.lsp.rpc.start({ bin, "--lsp", "--stdio" }, dispatchers)
    end,

    filetypes = {
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
    },

    -- typescript-go panics ("path \"tsconfig.json\" is not absolute") if it is
    -- started with NO workspace root (null rootUri) -- it has no usable
    -- single-file mode. root_dir as a function resolves an ABSOLUTE root from
    -- the buffer (vim.fs.root walks upward, returns an absolute dir or nil)
    -- and only activates when one is found. Passing bufnr, not a name string,
    -- avoids any relative-path issue. This replaces root_markers, which is
    -- ignored once root_dir is defined.
    root_dir = function(bufnr, on_dir)
      local root = vim.fs.root(bufnr, {
        "tsconfig.json",
        "jsconfig.json",
        "package.json",
        ".git",
      })
      -- Only start when we have a real root. If nil, we don't call on_dir, so
      -- the server does not attach for this buffer instead of crashing.
      if root then
        on_dir(root)
      end
    end,

    -- Belt-and-suspenders: never let Neovim launch tsgo root-less even if the
    -- above ever yields nothing. Native equivalent of lspconfig's
    -- single_file_support = false.
    workspace_required = true,

    -- tsgo's inlay hint settings are nested per-language and each hint type
    -- takes an object (not a flat boolean) -- a different shape than the old
    -- ts_ls / tsserver config. These describe WHICH hints the server sends;
    -- rendering them in the buffer is still gated by vim.lsp.inlay_hint.enable,
    -- which now starts off (toggle with <leader>h).
    settings = {
      typescript = {
        inlayHints = {
          parameterNames = { enabled = "literals" },
          parameterTypes = { enabled = true },
          variableTypes = { enabled = true },
          propertyDeclarationTypes = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
          enumMemberValues = { enabled = true },
        },
      },
      javascript = {
        inlayHints = {
          parameterNames = { enabled = "literals" },
          parameterTypes = { enabled = true },
          variableTypes = { enabled = true },
          propertyDeclarationTypes = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
          enumMemberValues = { enabled = true },
        },
      },
    },
  },
}

vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = false,
  underline = false,
  signs = true,
  severity_sort = true,
  float = {
    -- No `border` here: global 'winborder' already supplies the rounded
    -- border to every float, diagnostic floats included.
    source = "if_many",
  },
})

-- LSP keymaps on attach
local function on_lsp_attach(args)
  local bufnr = args.buf
  local client = vim.lsp.get_client_by_id(args.data.client_id)

  if client then
    -- Disable built-in formatting for servers where Prettier (via conform) should
    -- always win -- this is a deliberate belt-and-suspenders choice: conform's
    -- lsp_format = "fallback" already prefers Prettier when it's available, but
    -- this guarantees the LSP's own formatter never fires even if Prettier is
    -- temporarily missing, rather than silently reformatting with different rules.
    if client.name == "tsgo" or client.name == "jsonls" then
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end

    -- Ruff's server is documented as lint/format-only and is meant to run
    -- alongside a full Python LSP for hover/nav (see Astral's own editor
    -- setup docs) -- pylsp owns hover here, so this just makes that
    -- explicit instead of relying on Ruff never advertising the capability.
    if client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end

    -- Inlay hints are intentionally NOT auto-enabled here: they start off in
    -- every buffer. Toggle them on per buffer with <leader>h (see
    -- keymappings.lua). Servers still advertise support and send the hints;
    -- this only controls whether Neovim renders them.
  end

  -- NOTE: <leader>e (diagnostics float) is intentionally NOT here -- it is
  -- defined once globally in keymappings.lua so it works in every buffer.
  local keymaps = {
    { "n", "gd", vim.lsp.buf.definition, "[LSP] Go to definition" },
    { "n", "gD", vim.lsp.buf.declaration, "[LSP] Go to declaration" },
    { "n", "gr", vim.lsp.buf.references, "[LSP] References" },
    {
      "n",
      "K",
      function()
        -- No `border` arg: global 'winborder' supplies the rounded border.
        vim.lsp.buf.hover({
          max_width = 100,
          max_height = 40,
        })
      end,
      "[LSP] Hover documentation",
    },
    {
      "n",
      "<C-k>",
      function()
        -- No `border` arg: global 'winborder' supplies the rounded border.
        vim.lsp.buf.signature_help()
      end,
      "[LSP] Signature help",
    },
    { "n", "<leader>D", vim.lsp.buf.type_definition, "[LSP] Type definition" },
    { "n", "<leader>rn", vim.lsp.buf.rename, "[LSP] Rename symbol" },
    {
      { "n", "v" },
      "<leader>ca",
      vim.lsp.buf.code_action,
      "[LSP] Code actions",
    },
    {
      "n",
      "[d",
      function()
        vim.diagnostic.jump({ count = -1, float = true })
      end,
      "[Diag] Prev",
    },
    {
      "n",
      "]d",
      function()
        vim.diagnostic.jump({ count = 1, float = true })
      end,
      "[Diag] Next",
    },
  }

  for _, km in ipairs(keymaps) do
    vim.keymap.set(km[1], km[2], km[3], { buffer = bufnr, desc = km[4] })
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
  callback = on_lsp_attach,
})

for server_name, server_config in pairs(servers) do
  vim.lsp.config(server_name, server_config)
  vim.lsp.enable(server_name)
end
