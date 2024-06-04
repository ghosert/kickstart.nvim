-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    -- 'leoluz/nvim-dap-go', -- jiawzhang comment it out, since we don't have go language here.

    -- jiawzhang this url contains all the supported debugger adapters: https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#javascript
    -- jiawzhang add for javascript nvim-dap debugger adapter, following this to setup: https://github.com/mxsdev/nvim-dap-vscode-js
    'mxsdev/nvim-dap-vscode-js',
    -- jiawzhang Install the vscode-js-debug debugger for javascript
    {
      'microsoft/vscode-js-debug',
      -- After install, build it and rename the dist directory to out
      build = 'npm install --legacy-peer-deps --no-save && npx gulp vsDebugServerBundle && rm -rf out && mv dist out',
      config = function()
        -- jiawzhang Install javascript specific config: https://github.com/mxsdev/nvim-dap-vscode-js
        require('dap-vscode-js').setup {
          -- node_path = "node", -- Path of node executable. Defaults to $NODE_PATH, and then "node"
          -- debugger_path = "(runtimedir)/site/pack/packer/opt/vscode-js-debug", -- Path to vscode-js-debug installation.
          debugger_path = vim.fn.resolve(vim.fn.stdpath 'data' .. '/lazy/vscode-js-debug'),
          -- debugger_cmd = { "js-debug-adapter" }, -- Command to use to launch the debug server. Takes precedence over `node_path` and `debugger_path`.
          adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' }, -- which adapters to register in nvim-dap
          -- log_file_path = "(stdpath cache)/dap_vscode_js.log" -- Path for file logging
          -- log_file_level = false -- Logging level for output to file. Set to false to disable file logging.
          -- log_console_level = vim.log.levels.ERROR -- Logging level for output to console. Set to false to disable console output.
        }
        for _, language in ipairs { 'typescript', 'javascript' } do
          require('dap').configurations[language] = {
            {
              type = 'pwa-node',
              request = 'launch',
              name = 'Launch file',
              program = '${file}',
              cwd = '${workspaceFolder}',
            },
            {
              type = 'pwa-node',
              request = 'attach',
              name = 'Attach',
              processId = require('dap.utils').pick_process,
              cwd = '${workspaceFolder}',
            },
          }
        end
      end,
    },
    {
      'mfussenegger/nvim-dap-python', -- jiawzhang add for python debug, relying on 'pip2 install debugpy' under virtual env ~/devenv, preinstalled.
      ft = 'python',
      config = function()
        local path = '~/devenv/bin/python' -- NOTE: jiawzhang python: set virtual python env when debugging
        require('dap-python').setup(path)
      end,
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_setup = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        --'delve', -- jiawzhang comment it out since we don't have go language here.
      },
    }

    -- Basic debugging keymaps, feel free to change to your liking!
    vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', '<F1>', dap.step_into, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', '<F2>', dap.step_over, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', '<F3>', dap.step_out, { desc = 'Debug: Step Out' })
    vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
    vim.keymap.set('n', '<leader>B', function()
      dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
    end, { desc = 'Debug: Set Breakpoint' })

    -- TODO: jiawzhang: Debugging feature key bindings, try them later.
    -- keymap.set("n", "<leader>bb", "<cmd>lua require'dap'.toggle_breakpoint()<cr>")
    -- keymap.set("n", "<leader>bc", "<cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>")
    -- keymap.set("n", "<leader>bl", "<cmd>lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<cr>")
    -- keymap.set("n", '<leader>br', "<cmd>lua require'dap'.clear_breakpoints()<cr>")
    -- keymap.set("n", '<leader>ba', '<cmd>Telescope dap list_breakpoints<cr>')
    -- keymap.set("n", "<leader>dc", "<cmd>lua require'dap'.continue()<cr>")
    -- keymap.set("n", "<leader>dj", "<cmd>lua require'dap'.step_over()<cr>")
    -- keymap.set("n", "<leader>dk", "<cmd>lua require'dap'.step_into()<cr>")
    -- keymap.set("n", "<leader>do", "<cmd>lua require'dap'.step_out()<cr>")
    -- keymap.set("n", '<leader>dd', function() require('dap').disconnect(); require('dapui').close(); end)
    -- keymap.set("n", '<leader>dt', function() require('dap').terminate(); require('dapui').close(); end)
    -- keymap.set("n", "<leader>dr", "<cmd>lua require'dap'.repl.toggle()<cr>")
    -- keymap.set("n", "<leader>dl", "<cmd>lua require'dap'.run_last()<cr>")
    -- keymap.set("n", '<leader>di', function() require "dap.ui.widgets".hover() end)
    -- keymap.set("n", '<leader>d?', function() local widgets = require "dap.ui.widgets"; widgets.centered_float(widgets.scopes) end)
    -- keymap.set("n", '<leader>df', '<cmd>Telescope dap frames<cr>')
    -- keymap.set("n", '<leader>dh', '<cmd>Telescope dap commands<cr>')
    -- keymap.set("n", '<leader>de', function() require('telescope.builtin').diagnostics({default_text=":E:"}) end)

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- Add dap configurations based on your language/adapter settings
    -- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation
    dap.configurations.java = {
      {
        name = 'Debug Launch (2GB)',
        type = 'java',
        request = 'launch',
        vmArgs = '' .. '-Xmx2g ',
      },
      {
        name = 'Debug Attach (8000)',
        type = 'java',
        request = 'attach',
        hostName = '127.0.0.1',
        port = 8000,
      },
      {
        name = 'Debug Attach (5005)',
        type = 'java',
        request = 'attach',
        hostName = '127.0.0.1',
        port = 5005,
      },
      {
        name = 'My Custom Java Run Configuration',
        type = 'java',
        request = 'launch',
        -- You need to extend the classPath to list your dependencies.
        -- `nvim-jdtls` would automatically add the `classPaths` property if it is missing
        -- classPaths = {},

        -- If using multi-module projects, remove otherwise.
        -- projectName = "yourProjectName",

        -- javaExec = "java",
        mainClass = 'replace.with.your.fully.qualified.MainClass',

        -- If using the JDK9+ module system, this needs to be extended
        -- `nvim-jdtls` would automatically populate this property
        -- modulePaths = {},
        vmArgs = '' .. '-Xmx2g ',
      },
    }

    -- Install golang specific config
    -- require('dap-go').setup() -- jiawzhang comment it out since we don't have go language here and maybe move it to above like python and js
  end,
}
