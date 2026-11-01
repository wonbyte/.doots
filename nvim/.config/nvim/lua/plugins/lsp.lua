-- Set blink.cmp capabilities for all LSP servers (deep-merged with per-server config)
--
-- No positionEncodings override: Neovim 0.12 already advertises
-- { "utf-8", "utf-16", "utf-32" } with utf-8 first (see
-- vim.lsp.protocol.make_client_capabilities). Servers that do not
-- negotiate are handled per-server with offset_encoding below.
vim.lsp.config("*", {
  capabilities = vim.tbl_deep_extend(
    "force",
    require("blink.cmp").get_lsp_capabilities(),
    {
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
  -- Go
  gopls = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork" },
    root_markers = { { "go.work", "go.mod" }, ".git" },
    settings = {
      gopls = {
        analyses = {
          unusedparams = true,
          shadow = true,
        },
        staticcheck = true,
        -- gofumpt is a stricter superset of gofmt. Left false so gopls
        -- diagnostics match conform's goimports output (gofmt style).
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
  -- XML / XSD / XSLT (installed via Mason as "lemminx"). Format settings
  -- carried over from the old LazyVim config: keep attribute layout as
  -- written and allow long lines instead of hard-wrapping at 80.
  lemminx = {
    cmd = { "lemminx" },
    filetypes = { "xml", "xsd", "xslt", "svg" },
    root_markers = { ".git" },
    settings = {
      xml = {
        format = {
          enabled = true,
          splitAttributes = "preserve",
          maxLineWidth = 280,
        },
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
    -- cmd as a function: resolve the workspace's OWN TypeScript at server
    -- start, so each project uses the version it pins. When cmd is a
    -- function it must start the RPC client itself via vim.lsp.rpc.start().
    cmd = function(dispatchers, config)
      -- Resolve from the buffer being edited, not config.root_dir or cwd:
      -- both proved unreliable at cmd-invocation time. Walking upward from
      -- the actual file is independent of both.
      local bufname = vim.api.nvim_buf_get_name(0)
      local start = (bufname ~= "") and vim.fs.dirname(bufname) or vim.uv.cwd()

      -- Returns the major version number (7, 5, ...) from a version string
      -- like "7.0.1" or "Version 7.0.1". Returns nil if no number is found.
      local function major(s)
        return tonumber((s or ""):match("(%d+)%."))
      end

      -- Returns the major version of the `typescript` package inside one
      -- node_modules dir, or nil if it is missing or unreadable.
      -- Why: `.bin/tsc` exists for BOTH old TypeScript (5.x, JavaScript) and
      -- TS 7+ (native Go). Only 7+ understands `--lsp`. Old tsc exits with
      -- code 1 and prints its error to stdout, which Neovim reads as LSP
      -- data and drops -- so lsp.log shows nothing. We must check first.
      local function ts_major(nm)
        local ok, lines =
          pcall(vim.fn.readfile, nm .. "/typescript/package.json")
        if not ok or #lines == 0 then
          return nil
        end
        local ok2, pkg = pcall(vim.json.decode, table.concat(lines, "\n"))
        if not ok2 or type(pkg) ~= "table" then
          return nil
        end
        return major(pkg.version)
      end

      -- Every node_modules going up from the file, nearest first.
      -- limit = math.huge covers monorepos where deps are hoisted higher up.
      local nm_dirs = vim.fs.find("node_modules", {
        upward = true,
        type = "directory",
        path = start,
        limit = math.huge,
      })

      -- Remember if we skipped an old tsc, so the error message can say why.
      local skipped_old = nil

      local bin
      for _, nm in ipairs(nm_dirs) do
        -- 1. @typescript/native-preview ships `tsgo`. It is always native,
        --    so it wins with no version check.
        local tsgo = nm .. "/.bin/tsgo"
        if vim.uv.fs_stat(tsgo) then
          bin = tsgo
          break
        end

        -- 2. `tsc` only counts when the typescript package is 7 or newer.
        local tsc = nm .. "/.bin/tsc"
        if vim.uv.fs_stat(tsc) then
          local v = ts_major(nm)
          if v and v >= 7 then
            bin = tsc
            break
          end
          skipped_old = skipped_old
            or (tsc .. " (TypeScript " .. tostring(v) .. ")")
        end
      end

      -- No usable local binary: fall back to a global one on PATH.
      if not bin then
        if vim.fn.executable("tsgo") == 1 then
          -- Global tsgo is always native.
          bin = "tsgo"
        elseif vim.fn.executable("tsc") == 1 then
          -- Global tsc may also be old 5.x. Ask it for its version.
          -- Output looks like "Version 7.0.1".
          local res = vim.system({ "tsc", "--version" }, { text = true }):wait()
          local v = major(res.stdout)
          if v and v >= 7 then
            bin = "tsc"
          else
            skipped_old = skipped_old
              or ("global tsc (TypeScript " .. tostring(v) .. ")")
          end
        end
      end

      -- cmd-as-function MUST return an rpc client: client.lua assigns the
      -- return value to self.rpc with no nil check. error() gives a clear
      -- message here instead of a cryptic nil-index traceback later.
      if not bin then
        local msg = "tsgo: no native tsgo or TypeScript 7+ tsc found upward from "
          .. start
        if skipped_old then
          msg = msg
            .. "; skipped old "
            .. skipped_old
            .. ". Fix: npm install -D @typescript/native-preview"
        end
        error(msg)
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
  -- Show the diagnostic float after every jump. This replaces the old
  -- vim.diagnostic.jump({ float = true }), which 0.12 deprecates (removal in
  -- 0.14) in favor of an on_jump callback. Setting it here, as the jump
  -- default, means Neovim's built-in [d / ]d / [D / ]D all open the float --
  -- so no custom jump mappings are needed (see on_lsp_attach). The body
  -- mirrors exactly what 0.12 itself builds from the deprecated
  -- float = true: a non-focused float scoped to the cursor position.
  jump = {
    on_jump = function(_, bufnr)
      vim.diagnostic.open_float({
        bufnr = bufnr,
        scope = "cursor",
        focus = false,
      })
    end,
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
    -- gI, not gi: gi is a useful Vim built-in (insert at the last insert
    -- position), so it stays untouched.
    { "n", "gI", vim.lsp.buf.implementation, "[LSP] Go to implementation" },
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
    -- [d / ]d are no longer mapped here: Neovim's built-in defaults call
    -- vim.diagnostic.jump(), which picks up jump.on_jump from the
    -- vim.diagnostic.config() call above, so they already open the float.
  }

  for _, km in ipairs(keymaps) do
    -- nowait: Neovim 0.11+ ships global gr* defaults (grn, grr, gra, gri,
    -- grt). Our buffer-local "gr" is a prefix of all of them, so without
    -- nowait every press of gr would sit out 'timeoutlen' (300ms) waiting
    -- to see whether a longer mapping was being typed.
    --
    -- The flip side: once gr fires instantly, the gr* defaults become
    -- unreachable in LSP buffers. That is fine because every one of them
    -- has a local equivalent -- grn -> <leader>rn, grr -> gr, gra ->
    -- <leader>ca, gri -> gI, grt -> <leader>D. If a new gr* default ever
    -- appears upstream, it needs a mapping here too.
    vim.keymap.set(
      km[1],
      km[2],
      km[3],
      { buffer = bufnr, desc = km[4], nowait = true }
    )
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
