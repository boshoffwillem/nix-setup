-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  local nmap = function(keys, func, desc)
    if desc then
      desc = 'LSP: ' .. desc
    end

    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end

  if client.name == 'omnisharp' then
    -- https://github.com/OmniSharp/omnisharp-roslyn/issues/2483#issuecomment-1492605642
    local tokenModifiers = client.server_capabilities.semanticTokensProvider.legend.tokenModifiers
    for i, v in ipairs(tokenModifiers) do
      tmp = string.gsub(v, ' ', '_')
      tokenModifiers[i] = string.gsub(tmp, '-_', '')
    end
    local tokenTypes = client.server_capabilities.semanticTokensProvider.legend.tokenTypes
    for i, v in ipairs(tokenTypes) do
      tmp = string.gsub(v, ' ', '_')
      tokenTypes[i] = string.gsub(tmp, '-_', '')
    end
  end

  nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
  nmap('gd', vim.lsp.buf.definition, '')
  nmap('gr', vim.lsp.buf.references, '')
  nmap('gi', vim.lsp.buf.implementation, '')
  nmap('K', vim.lsp.buf.hover, '')
  nmap('<C-k>', vim.lsp.buf.signature_help, '')
  nmap('<space>wa', vim.lsp.buf.add_workspace_folder, '')
  nmap('<space>wr', vim.lsp.buf.remove_workspace_folder, '')
  nmap('<space>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, '')
  nmap('<space>D', vim.lsp.buf.type_definition, '')
  nmap('<space>lr', vim.lsp.buf.rename, '')
  nmap('<space>la', vim.lsp.buf.code_action, '')
  nmap('<space>l=', function() vim.lsp.buf.format { async = true } end, '')
  -- nmap('<leader>pt', require('telescope.builtin').lsp_document_symbols, '')
  nmap('<leader>pt', require('telescope.builtin').lsp_dynamic_workspace_symbols, '')

  -- Create a command `:Format` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
    vim.lsp.buf.format()
  end, { desc = 'Format current buffer with LSP' })
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)
local lsp_flags = {
  -- This is the default in Nvim 0.7+
  debounce_text_changes = 150,
}

-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--
--  Add any additional override configuration in the following tables. They will be passed to
--  the `settings` field of the server config. You must look up that documentation yourself.
local servers = {
  -- fsautocomplete = {},
  jsonls = {
    json = {
      schemas = require('schemastore').json.schemas(),
      validate = { enable = true },
    },
  },
  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
  omnisharp = {},
  powershell_es = {},
  rust_analyzer = {},
  tflint = {},
  terraformls = {},
  yamlls = {
    yaml = {
      format = true,
      schemaDownload = {
        enable = true
      },
      schemas = {
        ["https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json"] = { "/*Pipeline*.yml" },
        ["https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/v1.18.0-standalone-strict/all.json"] = "/*.k8s.yaml"
      },
      validate = true
    }
  },
  -- zls = {}
}

-- Setup neovim lua configuration
require('neodev').setup()

-- Setup mason so it can manage external tooling
require('mason').setup()

-- Ensure the servers above are installed
local mason_lspconfig = require 'mason-lspconfig'

mason_lspconfig.setup {
  ensure_installed = vim.tbl_keys(servers),
}

mason_lspconfig.setup_handlers {
  function(server_name)
    if server_name == 'omnisharp' then
      require('lspconfig')[server_name].setup {
        capabilities = capabilities,
        on_attach = on_attach,
        flags = lsp_flags,
        settings = servers[server_name],
      }
    else
      require('lspconfig')[server_name].setup {
        capabilities = capabilities,
        on_attach = on_attach,
        flags = lsp_flags,
        settings = servers[server_name],
      }
    end
  end,
}

-- Turn on lsp status information
require('fidget').setup()

-- nvim-cmp setup
local cmp = require 'cmp'
local luasnip = require 'luasnip'

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
  sources = {
    { name = 'buffer' },
    { name = 'path' },
    { name = 'nvim_lsp', keyword_length = 1 },
    { name = 'nvim_lua', keyword_length = 1 },
    { name = 'cmp_tabnine' },
  },
}

-- null-ls
local null_ls = require("null-ls")

null_ls.setup({
  sources = {
    null_ls.builtins.formatting.buf,
    null_ls.builtins.formatting.stylua,
    null_ls.builtins.formatting.terraform_fmt,
    null_ls.builtins.diagnostics.eslint,
    null_ls.builtins.diagnostics.buf,
    null_ls.builtins.diagnostics.editorconfig_checker,
    null_ls.builtins.diagnostics.cspell,
    null_ls.builtins.code_actions.cspell
  },
})
