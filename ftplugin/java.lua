-- TODO: jiawzhang: java
-- Unit testing and its shortcut, watch later here: https://youtu.be/TryxysOh-fI?t=585
--
-- -- Filetype-specific keymaps (these can be done in the ftplugin directory instead if you prefer)
--
-- keymap.set("n", '<leader>go', function()
--   if vim.bo.filetype == 'java' then
--     require('jdtls').organize_imports();
--   end
-- end)
--
-- keymap.set("n", '<leader>gu', function()
--   if vim.bo.filetype == 'java' then
--     require('jdtls').update_projects_config();
--   end
-- end)
--
-- keymap.set("n", '<leader>tc', function()
--   if vim.bo.filetype == 'java' then
--     require('jdtls').test_class();
--   end
-- end)
--
-- keymap.set("n", '<leader>tm', function()
--   if vim.bo.filetype == 'java' then
--     require('jdtls').test_nearest_method();
--   end
-- end)
--
-- NOTE: jiawzhang: java
-- https://www.youtube.com/watch?v=TryxysOh-fI
-- https://github.com/bcampolo/nvim-starter-kit/blob/java/.config/nvim/ftplugin/java.lua
-- https://github.com/mfussenegger/nvim-jdtls

vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

-- JDTLS (Java LSP) configuration
local jdtls = require 'jdtls'
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
local workspace_dir = vim.env.HOME .. '/tmp/jdtls-workspace/' .. project_name

local system = (function()
  -- Lua example
  local os_name = vim.loop.os_uname().sysname
  if os_name == 'Linux' then
    return 'linux'
  elseif os_name == 'Darwin' then
    return 'mac'
  elseif os_name:find 'Windows' then
    return 'win'
  end
  return 'linux'
end)()

local cpu = (function()
  -- Lua example to detect ARM architecture
  local architecture = vim.fn.system 'uname -m'
  if architecture:match 'arm' then
    return 'arm'
  end
  return ''
end)()

local java_path = (function()
  if system == 'mac' then
    return '/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home'
  end
  if system == 'linux' then
    if cpu == 'arm' then
      return '/usr/lib/jvm/java-21-openjdk-arm64'
    else
      return '/usr/lib/jvm/java-21-openjdk-amd64'
    end
  end
end)()

local config_postfix = (function()
  if cpu == '' then
    return system
  end
  return system .. '_' .. cpu
end)()

-- Needed for debugging
local bundles = {
  vim.fn.glob(vim.env.HOME .. '/.local/share/nvim/mason/share/java-debug-adapter/com.microsoft.java.debug.plugin.jar'),
}

-- Needed for running/debugging unit tests
vim.list_extend(bundles, vim.split(vim.fn.glob(vim.env.HOME .. '/.local/share/nvim/mason/share/java-test/*.jar', 1), '\n'))

-- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
local config = {
  -- The command that starts the language server
  -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
  cmd = {
    'java',
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-javaagent:' .. vim.env.HOME .. '/.local/share/nvim/mason/share/jdtls/lombok.jar',
    '-Xmx4g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens',
    'java.base/java.util=ALL-UNNAMED',
    '--add-opens',
    'java.base/java.lang=ALL-UNNAMED',

    -- Eclipse jdtls location
    '-jar',
    vim.env.HOME .. '/.local/share/nvim/mason/share/jdtls/plugins/org.eclipse.equinox.launcher.jar',
    -- TODO Update this to point to the correct jdtls subdirectory for your OS (config_linux, config_mac, config_win, etc)
    '-configuration',
    vim.env.HOME .. '/.local/share/nvim/mason/packages/jdtls/config_' .. config_postfix,
    '-data',
    workspace_dir,
  },

  -- This is the default if not provided, you can remove it. Or adjust as needed.
  -- One dedicated LSP server & client will be started per unique root_dir
  root_dir = require('jdtls.setup').find_root { '.git', 'mvnw', 'pom.xml', 'build.gradle' },

  -- Here you can configure eclipse.jdt.ls specific settings
  -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
  settings = {
    java = {
      -- TODO Replace this with the absolute path to your main java version (JDK 21 or higher)
      home = java_path,
      eclipse = {
        downloadSources = true,
      },
      configuration = {
        updateBuildConfiguration = 'interactive',
        -- TODO Update this by adding any runtimes that you need to support your Java projects and removing any that you don't have installed
        -- The runtime name parameters need to match specific Java execution environments.  See https://github.com/tamago324/nlsp-settings.nvim/blob/2a52e793d4f293c0e1d61ee5794e3ff62bfbbb5d/schemas/_generated/jdtls.json#L317-L334
        runtimes = {
          {
            name = 'JavaSE-21',
            path = java_path,
          },
        },
      },
      maven = {
        downloadSources = true,
      },
      implementationsCodeLens = {
        enabled = true,
      },
      referencesCodeLens = {
        enabled = true,
      },
      references = {
        includeDecompiledSources = true,
      },
      signatureHelp = { enabled = true },
      format = {
        enabled = false, -- jiawzhang java: disable this first for existing projects.
        -- Formatting works by default, but you can refer to a specific file/URL if you choose
        -- settings = {
        --   url = "https://github.com/google/styleguide/blob/gh-pages/intellij-java-google-style.xml",
        --   profile = "GoogleStyle",
        -- },
      },
    },
    completion = {
      favoriteStaticMembers = {
        'org.hamcrest.MatcherAssert.assertThat',
        'org.hamcrest.Matchers.*',
        'org.hamcrest.CoreMatchers.*',
        'org.junit.jupiter.api.Assertions.*',
        'java.util.Objects.requireNonNull',
        'java.util.Objects.requireNonNullElse',
        'org.mockito.Mockito.*',
      },
      importOrder = {
        'java',
        'javax',
        'com',
        'org',
      },
    },
    extendedClientCapabilities = jdtls.extendedClientCapabilities,
    sources = {
      organizeImports = {
        starThreshold = 9999,
        staticStarThreshold = 9999,
      },
    },
    codeGeneration = {
      toString = {
        template = '${object.className}{${member.name()}=${member.value}, ${otherMembers}}',
      },
      useBlocks = true,
    },
  },
  -- Needed for auto-completion with method signatures and placeholders
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
  flags = {
    allow_incremental_sync = true,
  },
  init_options = {
    -- References the bundles defined above to support Debugging and Unit Testing
    bundles = bundles,
  },
}

-- Needed for debugging
config['on_attach'] = function(client, bufnr)
  jdtls.setup_dap { hotcodereplace = 'auto' }
  require('jdtls.dap').setup_dap_main_class_configs()
  lsp_signature_on_attach(client, bufnr) -- jiawzhang this is coming from init.lua
end

-- This starts a new client & server, or attaches to an existing client & server based on the `root_dir`.
jdtls.start_or_attach(config)
