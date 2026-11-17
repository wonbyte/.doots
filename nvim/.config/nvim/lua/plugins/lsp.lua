-- Set blink.cmp capabilities for all LSP servers (deep-merged with each
-- server's own config).
--
-- No positionEncodings override: Neovim 0.12 already advertises
-- { "utf-8", "utf-16", "utf-32" } with utf-8 first (see
-- vim.lsp.protocol.make_client_capabilities).
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

-- SchemaStore catalog, built once on first use (see jsonls below).
-- nil = not built yet; false = plugin missing.
local json_schemas

-- tsgo: root dir -> the buffer that started it. root_dir records it so cmd
-- can resolve TypeScript from that file (see tsgo below).
local tsgo_start_buf = {}

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
  -- JSON (Mason package "json-lsp"; binary: vscode-json-language-server)
  jsonls = {
    cmd = { "vscode-json-language-server", "--stdio" },
    filetypes = { "json", "jsonc" },
    root_markers = { ".git" },
    settings = {
      json = {
        validate = { enable = true },
      },
    },
    -- JSON schemas from SchemaStore.nvim's bundled catalog, so jsonls
    -- matches files by name (package.json, tsconfig.json, ...) and
    -- validates them. The catalog is large, so it is built once, when the
    -- first jsonls client starts, not at every Neovim startup, and then
    -- reused for every later client (one per project root). pcall-guarded:
    -- a missing plugin means "no catalog" (validation then only applies
    -- where a file declares "$schema"), not an error.
    before_init = function(_, config)
      if json_schemas == nil then
        local ok, schemastore = pcall(require, "schemastore")
        json_schemas = ok and schemastore.json.schemas() or false
      end
      if json_schemas then
        config.settings.json.schemas = json_schemas
      end
    end,
  },
  -- XML / XSD / XSLT (Mason package "lemminx"). Keep attribute layout as
  -- written and allow long lines instead of hard-wrapping at 80.
  lemminx = {
    cmd = { "lemminx" },
    filetypes = { "xml", "xsd", "xslt", "svg" },
    root_markers = { ".git" },
    -- Make the server announce formatting at start, not a moment later.
    -- With the late (dynamic) announcement, a save in the first second
    -- after opening a file was not formatted.
    capabilities = {
      textDocument = {
        formatting = { dynamicRegistration = false },
        rangeFormatting = { dynamicRegistration = false },
      },
    },
    settings = {
      xml = {
        format = {
          enabled = true,
          splitAttributes = "preserve",
          -- Must be sent: the docs give true as the default, but that is
          -- the VS Code extension's default. Without it the server joins
          -- attributes that were on separate lines.
          preserveAttributeLineBreaks = true,
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
        -- Pass --all-features to cargo. (The old key cargo.allFeatures
        -- still works, but only through a compatibility shim.)
        cargo = { features = "all" },
        -- The server watches files itself. With Neovim watching (the "*"
        -- config at the top), build churn in target/ now and then gave an
        -- "inotify: Couldn't watch new directory" error.
        files = { watcher = "server" },
        -- checkOnSave is on by default; run clippy instead of cargo check.
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
      -- Resolve from the file that started this client, not from the root:
      -- in a monorepo the root can be the .git dir above the package, so
      -- an upward search from the root would miss the package's own
      -- node_modules. root_dir below records that buffer per root. The
      -- current buffer is only a fallback.
      local bufnr = tsgo_start_buf[config.root_dir]
      if not (bufnr and vim.api.nvim_buf_is_valid(bufnr)) then
        bufnr = 0
      end
      local bufname = vim.api.nvim_buf_get_name(bufnr)
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
            or (tsc .. " (TypeScript " .. (v or "unknown version") .. ")")
        end
      end

      -- No usable local binary: fall back to a global one on PATH.
      if not bin then
        if vim.fn.executable("tsgo") == 1 then
          -- Global tsgo is always native.
          bin = "tsgo"
        elseif vim.fn.executable("tsc") == 1 then
          -- Global tsc may also be old 5.x. Read the version from its
          -- package.json instead of running `tsc --version`, which would
          -- block the editor while Node starts. A global install links
          -- tsc to <node_modules>/typescript/bin/tsc.
          local real = vim.uv.fs_realpath(vim.fn.exepath("tsc"))
          local v = real
            and ts_major(vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(real))))
          if v and v >= 7 then
            bin = "tsc"
          else
            skipped_old = skipped_old
              or ("global tsc (TypeScript " .. (v or "unknown version") .. ")")
          end
        end
      end

      -- cmd-as-function MUST return an rpc client: client.lua assigns the
      -- return value to self.rpc with no nil check. error() gives a clear
      -- message here instead of a cryptic nil-index traceback later.
      if not bin then
        local msg = "tsgo: no native tsgo or TypeScript 7+ tsc found "
          .. "upward from "
          .. start
        if skipped_old then
          msg = msg
            .. "; skipped old "
            .. skipped_old
            .. ". Fix: npm install -D typescript@latest (7+)"
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
        tsgo_start_buf[root] = bufnr
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
  -- vim.diagnostic.jump({ float = true }), which 0.12 deprecates in favor
  -- of an on_jump callback. Setting it here, as the jump
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
    -- Disable built-in formatting for servers where Prettier (via conform)
    -- should always win. conform's lsp_format = "fallback" already prefers
    -- Prettier, but this guarantees the LSP's own formatter never fires,
    -- even if Prettier is missing, so files are never reformatted with
    -- different rules.
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
    -- Run the code lens on this line (replaces the grx default, which the
    -- nowait "gr" below makes unreachable). gopls and roslyn_ls offer lenses.
    { "n", "<leader>cl", vim.lsp.codelens.run, "[LSP] Run code lens" },
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
    -- nowait: Neovim 0.12 ships global gr* defaults (grn, grr, gra, gri,
    -- grt, grx). Our buffer-local "gr" is a prefix of all of them, so
    -- without nowait every press of gr would sit out 'timeoutlen' (300ms)
    -- waiting to see whether a longer mapping was being typed.
    --
    -- The flip side: once gr fires instantly, the gr* defaults become
    -- unreachable in LSP buffers. That is fine because every one of them
    -- has a local equivalent -- grn -> <leader>rn, grr -> gr, gra ->
    -- <leader>ca, gri -> gI, grt -> <leader>D, grx -> <leader>cl. If a new
    -- gr* default ever appears upstream, it needs a mapping here too.
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

-- C# (Roslyn). The server needs a lot of custom client code, so use the
-- maintained config from nvim-lspconfig instead of a copy. See init.lua for
-- why the file is read from disk. No formatter is set in conform for C#, so
-- lsp_format = "fallback" hands formatting to Roslyn. It reads the C# style
-- rules from .editorconfig; the indent width comes from the buffer's
-- shiftwidth/expandtab (sent with the request), which Neovim's built-in
-- EditorConfig support sets from indent_size.
--
-- A .NET SDK installed with dotnet-install.sh lives in ~/.dotnet, which is
-- outside the default search path. Without DOTNET_ROOT the server's launcher
-- cannot find the runtime and quits. config.fish sets it too; this covers
-- Neovim started from a shell (or a long-running tmux server) that does not
-- have it yet. A distro package registers its own location (in
-- /etc/dotnet/install_location) and needs nothing.
local home_dotnet = vim.env.HOME .. "/.dotnet"
if not vim.env.DOTNET_ROOT and vim.uv.fs_stat(home_dotnet .. "/dotnet") then
  vim.env.DOTNET_ROOT = home_dotnet
end

-- pcall: vim.pack.get() throws when the plugin is not installed (for
-- example a first start with no network). That must only cost C# support,
-- not stop every server below from being set up.
local ok, plugs = pcall(vim.pack.get, { "nvim-lspconfig" }, { info = false })
local roslyn_path = ok and plugs[1] and (plugs[1].path .. "/lsp/roslyn_ls.lua")
if roslyn_path and vim.uv.fs_stat(roslyn_path) then
  -- Let Roslyn watch files itself instead of asking Neovim to (the "*"
  -- config at the top turns client-side watching on). Roslyn also asks for
  -- /usr/share/dotnet/packs, which does not exist with Ubuntu's .NET
  -- package (it lives in /usr/lib/dotnet), and Neovim then shows a watch
  -- error at every server start. Roslyn still picks up new files on disk.
  servers.roslyn_ls = vim.tbl_deep_extend("force", dofile(roslyn_path), {
    capabilities = {
      workspace = { didChangeWatchedFiles = { dynamicRegistration = false } },
    },
  })
  -- Drop nvim-lspconfig's before_init. It only runs
  -- `roslyn-language-server --version` to warn about servers older than
  -- 5.8.0 (no --autoLoadProjects). Mason installs a newer one, so the check
  -- always passes and just costs one extra .NET start per server start.
  servers.roslyn_ls.before_init = nil
else
  -- Say so instead of skipping in silence. Seen for real: vim.pack cloned
  -- the plugin but never checked its files out, and C# was just missing.
  vim.notify(
    "lsp: C# (roslyn_ls) is off: nvim-lspconfig's lsp/roslyn_ls.lua was not"
      .. " found. See :checkhealth vim.pack",
    vim.log.levels.WARN
  )
end

for server_name, server_config in pairs(servers) do
  vim.lsp.config(server_name, server_config)
  vim.lsp.enable(server_name)
end
