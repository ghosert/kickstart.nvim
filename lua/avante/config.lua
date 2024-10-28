---NOTE: user will be merged with defaults and
---we add a default var_accessor for this table to config values.

local Utils = require 'avante.utils'

---@class avante.CoreConfig: avante.Config
local M = {}

---@class avante.Config
M.defaults = {
  debug = false,
  ---@alias Provider "ollama" | "claude" | "openai" | "azure" | "gemini" | "cohere" | "copilot" | [string]
  provider = 'claude', -- NOTE: Only recommend using 'claude', 'ollama' for local
  auto_suggestions_provider = 'claude', -- NOTE: recommand 'claude', 'ollama' for local
  ---@alias Tokenizer "tiktoken" | "hf"
  -- Used for counting tokens and encoding text.
  -- By default, we will use tiktoken.
  -- For most providers that we support we will determine this automatically.
  -- If you wish to use a given implementation, then you can override it here.
  tokenizer = 'tiktoken',
  ---@alias AvanteSystemPrompt string
  -- Default system prompt. Users can override this with their own prompt
  -- You can use `require('avante.config').override({system_prompt = "MY_SYSTEM_PROMPT"}) conditionally
  -- in your own autocmds to do it per directory, or that fit your needs.
  system_prompt = [[
Act as an expert software developer.
Always use best practices when coding.
Respect and use existing conventions, libraries, etc that are already present in the code base.
]],
  ---@type AvanteSupportedProvider
  openai = {
    endpoint = 'https://api.openai.com/v1',
    model = 'gpt-4o',
    timeout = 30000, -- Timeout in milliseconds
    temperature = 0,
    max_tokens = 4096,
    ['local'] = false,
  },
  ---@type AvanteSupportedProvider
  copilot = {
    endpoint = 'https://api.githubcopilot.com',
    model = 'gpt-4o-2024-05-13',
    proxy = nil, -- [protocol://]host[:port] Use this proxy
    allow_insecure = false, -- Allow insecure server connections
    timeout = 30000, -- Timeout in milliseconds
    temperature = 0,
    max_tokens = 4096,
  },
  ---@type AvanteAzureProvider
  azure = {
    endpoint = '', -- example: "https://<your-resource-name>.openai.azure.com"
    deployment = '', -- Azure deployment name (e.g., "gpt-4o", "my-gpt-4o-deployment")
    api_version = '2024-06-01',
    timeout = 30000, -- Timeout in milliseconds
    temperature = 0,
    max_tokens = 4096,
    ['local'] = false,
  },
  ---@type AvanteSupportedProvider
  claude = {
    endpoint = 'https://api.anthropic.com',
    model = 'claude-3-5-sonnet-20241022',
    timeout = 30000, -- Timeout in milliseconds
    temperature = 0,
    max_tokens = 8000,
    ['local'] = false,
  },
  ---@type AvanteSupportedProvider
  gemini = {
    endpoint = 'https://generativelanguage.googleapis.com/v1beta/models',
    model = 'gemini-1.5-flash-latest',
    timeout = 30000, -- Timeout in milliseconds
    temperature = 0,
    max_tokens = 4096,
    ['local'] = false,
  },
  ---@type AvanteSupportedProvider
  cohere = {
    endpoint = 'https://api.cohere.com/v1',
    model = 'command-r-plus-08-2024',
    timeout = 30000, -- Timeout in milliseconds
    temperature = 0,
    max_tokens = 4096,
    ['local'] = false,
  },
  ---To add support for custom provider, follow the format below
  ---See https://github.com/yetone/avante.nvim/README.md#custom-providers for more details
  ---@type {[string]: AvanteProvider}
  -- vendors = {},
  vendors = {
    ---@type AvanteProvider
    ollama = {
      ['local'] = true,
      -- endpoint = '127.0.0.1:11434/v1',
      endpoint = '192.168.31.215:11434/v1', -- run `export OLLAMA_HOST="0.0.0.0:11434" && nohup ollama serve & diswn` to start ollama on MacOS, `pkill -9 ollama` to stop
      model = 'qwen2.5:14b', -- NOTE: 'codegemma', 'llama3.2', 'qwen2.5:14b', 'codestral'(need strong gpu)
      parse_curl_args = function(opts, code_opts)
        return {
          url = opts.endpoint .. '/chat/completions',
          headers = {
            ['Accept'] = 'application/json',
            ['Content-Type'] = 'application/json',
          },
          body = {
            model = opts.model,
            messages = require('avante.providers').copilot.parse_message(code_opts), -- you can make your own message, but this is very advanced
            max_tokens = 2048,
            stream = true,
          },
        }
      end,
      parse_response_data = function(data_stream, event_state, opts)
        require('avante.providers').openai.parse_response(data_stream, event_state, opts)
      end,
    },
  },
  ---Specify the behaviour of avante.nvim
  ---1. auto_apply_diff_after_generation: Whether to automatically apply diff after LLM response.
  ---                                     This would simulate similar behaviour to cursor. Default to false.
  ---2. auto_set_keymaps                : Whether to automatically set the keymap for the current line. Default to true.
  ---                                     Note that avante will safely set these keymap. See https://github.com/yetone/avante.nvim/wiki#keymaps-and-api-i-guess for more details.
  ---3. auto_set_highlight_group        : Whether to automatically set the highlight group for the current line. Default to true.
  ---4. support_paste_from_clipboard    : Whether to support pasting image from clipboard. This will be determined automatically based whether img-clip is available or not.
  behaviour = {
    auto_suggestions = false, -- Experimental stage
    auto_set_highlight_group = true,
    auto_set_keymaps = true,
    auto_apply_diff_after_generation = false,
    support_paste_from_clipboard = false,
  },
  history = {
    storage_path = vim.fn.stdpath 'state' .. '/avante',
    paste = {
      extension = 'png',
      filename = 'pasted-%Y-%m-%d-%H-%M-%S',
    },
  },
  highlights = {
    ---@type AvanteConflictHighlights
    diff = {
      current = 'DiffText',
      incoming = 'DiffAdd',
    },
  },
  mappings = {
    ---@class AvanteConflictMappings
    diff = {
      ours = 'co',
      theirs = 'ct',
      all_theirs = 'ca',
      both = 'cb',
      cursor = 'cc',
      next = ']x',
      prev = '[x',
    },
    suggestion = {
      accept = '<M-l>',
      next = '<M-]>',
      prev = '<M-[>',
      dismiss = '<C-]>',
    },
    jump = {
      next = ']]',
      prev = '[[',
    },
    submit = {
      normal = '<CR>',
      insert = '<C-s>',
    },
    -- NOTE: The following will be safely set by avante.nvim
    -- NOTE: jiawzhang: update '<leader>a' to '<leader>v' to avoid conflicts with chatgpt.nvim
    ask = '<leader>va',
    edit = '<leader>ve',
    refresh = '<leader>vr',
    focus = '<leader>vf',
    toggle = {
      default = '<leader>vt',
      debug = '<leader>vd',
      hint = '<leader>vh',
      suggestion = '<leader>vs',
      repomap = '<leader>vr',
    },
    sidebar = {
      apply_all = 'A',
      apply_cursor = 'a',
      switch_windows = '<Tab>',
      reverse_switch_windows = '<S-Tab>',
    },
  },
  windows = {
    ---@alias AvantePosition "right" | "left" | "top" | "bottom" | "smart"
    position = 'right',
    wrap = true, -- similar to vim.o.wrap
    width = 30, -- default % based on available width in vertical layout
    height = 30, -- default % based on available height in horizontal layout
    sidebar_header = {
      align = 'center', -- left, center, right for title
      rounded = true,
    },
    input = {
      prefix = '> ',
    },
    edit = {
      border = 'rounded',
      start_insert = true, -- Start insert mode when opening the edit window
    },
    ask = {
      floating = false, -- Open the 'AvanteAsk' prompt in a floating window
      border = 'rounded',
      start_insert = true, -- Start insert mode when opening the ask window
    },
  },
  --- @class AvanteConflictConfig
  diff = {
    autojump = true,
  },
  --- @class AvanteHintsConfig
  hints = {
    enabled = true,
  },
}

---@type avante.Config
M.options = {}

---@class avante.ConflictConfig: AvanteConflictConfig
---@field mappings AvanteConflictMappings
---@field highlights AvanteConflictHighlights
M.diff = {}

---@type Provider[]
M.providers = {}

---@param opts? avante.Config
function M.setup(opts)
  vim.validate { opts = { opts, 'table', true } }

  M.options = vim.tbl_deep_extend(
    'force',
    M.defaults,
    opts or {},
    ---@type avante.Config
    {
      behaviour = {
        support_paste_from_clipboard = M.support_paste_image(),
      },
    }
  )
  M.providers = vim
    .iter(M.defaults)
    :filter(function(_, value)
      return type(value) == 'table' and value.endpoint ~= nil
    end)
    :fold({}, function(acc, k)
      acc = vim.list_extend({}, acc)
      acc = vim.list_extend(acc, { k })
      return acc
    end)

  vim.validate { provider = { M.options.provider, 'string', false } }

  M.diff = vim.tbl_deep_extend('force', {}, M.options.diff, { mappings = M.options.mappings.diff, highlights = M.options.highlights.diff })

  if next(M.options.vendors) ~= nil then
    for k, v in pairs(M.options.vendors) do
      M.options.vendors[k] = type(v) == 'function' and v() or v
    end
    vim.validate { vendors = { M.options.vendors, 'table', true } }
    M.providers = vim.list_extend(M.providers, vim.tbl_keys(M.options.vendors))
  end
end

---@param opts? avante.Config
function M.override(opts)
  vim.validate { opts = { opts, 'table', true } }

  M.options = vim.tbl_deep_extend('force', M.options, opts or {})
  M.diff = vim.tbl_deep_extend('force', {}, M.options.diff, { mappings = M.options.mappings.diff, highlights = M.options.highlights.diff })

  if next(M.options.vendors) ~= nil then
    for k, v in pairs(M.options.vendors) do
      M.options.vendors[k] = type(v) == 'function' and v() or v
      if not vim.tbl_contains(M.providers, k) then
        M.providers = vim.list_extend(M.providers, { k })
      end
    end
    vim.validate { vendors = { M.options.vendors, 'table', true } }
  end
end

M = setmetatable(M, {
  __index = function(_, k)
    if M.options[k] then
      return M.options[k]
    end
  end,
})

M.support_paste_image = function()
  return Utils.has 'img-clip.nvim' or Utils.has 'img-clip'
end

M.get_window_width = function()
  return math.ceil(vim.o.columns * (M.windows.width / 100))
end

---@param provider Provider
---@return boolean
M.has_provider = function(provider)
  return M.options[provider] ~= nil or M.vendors[provider] ~= nil
end

---get supported providers
---@param provider Provider
---@return AvanteProviderFunctor
M.get_provider = function(provider)
  if M.options[provider] ~= nil then
    return vim.deepcopy(M.options[provider], true)
  elseif M.vendors[provider] ~= nil then
    return vim.deepcopy(M.vendors[provider], true)
  else
    error('Failed to find provider: ' .. provider, 2)
  end
end

M.BASE_PROVIDER_KEYS = {
  'endpoint',
  'model',
  'deployment',
  'api_version',
  'proxy',
  'allow_insecure',
  'api_key_name',
  'timeout',
  -- internal
  'local',
  '_shellenv',
  'tokenizer_id',
  'use_xml_format',
}

-- NOTE: jiawzhang: add more shortcuts to common coding scenarios to avoid typing same thing again and again

local prefill_edit_window = function(request)
  require('avante.api').edit()
  local code_bufnr = vim.api.nvim_get_current_buf()
  local code_winid = vim.api.nvim_get_current_win()
  if code_bufnr == nil or code_winid == nil then
    return
  end
  vim.api.nvim_buf_set_lines(code_bufnr, 0, -1, false, { request })
  -- Optionally set the cursor position to the end of the input
  vim.api.nvim_win_set_cursor(code_winid, { 1, #request + 1 })
  -- Simulate Ctrl+S keypress to submit
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-s>', true, true, true), 'v', true)
end
-- NOTE: jiawzhang: most templates are inspired from ~/.config/nvim/chatgpt-actions.json
local avante_grammar_correction = 'Correct the text to standard English, but keep any code blocks inside intact.'
local avante_keywords = 'Extract the main keywords from the following text'
local avante_code_readability_analysis = [[
  You must identify any readability issues in the code snippet.
  Some readability issues to consider:
  - Unclear naming
  - Unclear purpose
  - Redundant or obvious comments
  - Lack of comments
  - Long or complex one liners
  - Too much nesting
  - Long variable names
  - Inconsistent naming and code style.
  - Code repetition
  You may identify additional problems. The user submits a small section of code from a larger file.
  Only list lines with readability issues, in the format <line_num>|<issue and proposed solution>
  If there's no issues with code respond with only: <OK>
]]
local avante_optimize_code = 'Optimize the following code'
local avante_summarize = 'Summarize the following text'
local avante_translate = 'Translate this into Chinese, but keep any code blocks inside intact'
local avante_explain_code = 'Explain the following code'
local avante_complete_code = 'Complete the following codes written in ' .. vim.bo.filetype
local avante_add_docstring = 'Add docstring to the following codes'
local avante_fix_bugs = 'Fix the bugs inside the following codes if any'
local avante_add_tests = 'Implement tests for the following code'

require('which-key').add {
  { '<leader>v', group = 'A[v]ante' }, -- NOTE: add for avante.nvim
  {
    mode = { 'n', 'v' },
    { '<leader>vL', '<cmd>AvanteSwitchProvider ollama<CR>', desc = 'Local LLM' },
    { '<leader>vC', '<cmd>AvanteSwitchProvider claude<CR>', desc = 'Claude LLM' },
    {
      '<leader>vg',
      function()
        require('avante.api').ask { question = avante_grammar_correction }
      end,
      desc = 'Grammar Correction(ask)',
    },
    {
      '<leader>vk',
      function()
        require('avante.api').ask { question = avante_keywords }
      end,
      desc = 'Keywords(ask)',
    },
    {
      '<leader>vl',
      function()
        require('avante.api').ask { question = avante_code_readability_analysis }
      end,
      desc = 'Code Readability Analysis(ask)',
    },
    {
      '<leader>vo',
      function()
        require('avante.api').ask { question = avante_optimize_code }
      end,
      desc = 'Optimize Code(ask)',
    },
    {
      '<leader>vm',
      function()
        require('avante.api').ask { question = avante_summarize }
      end,
      desc = 'Summarize text(ask)',
    },
    {
      '<leader>vn',
      function()
        require('avante.api').ask { question = avante_translate }
      end,
      desc = 'Translate text(ask)',
    },
    {
      '<leader>vx',
      function()
        require('avante.api').ask { question = avante_explain_code }
      end,
      desc = 'Explain Code(ask)',
    },
    {
      '<leader>vc',
      function()
        require('avante.api').ask { question = avante_complete_code }
      end,
      desc = 'Complete Code(ask)',
    },
    {
      '<leader>vd',
      function()
        require('avante.api').ask { question = avante_add_docstring }
      end,
      desc = 'Docstring(ask)',
    },
    {
      '<leader>vb',
      function()
        require('avante.api').ask { question = avante_fix_bugs }
      end,
      desc = 'Fix Bugs(ask)',
    },
    {
      '<leader>vu',
      function()
        require('avante.api').ask { question = avante_add_tests }
      end,
      desc = 'Add Tests(ask)',
    },
  },
}

require('which-key').add {
  { '<leader>v', group = 'A[v]ante' }, -- NOTE: add for avante.nvim
  {
    mode = { 'v' },
    {
      '<leader>vG',
      function()
        prefill_edit_window(avante_grammar_correction)
      end,
      desc = 'Grammar Correction',
    },
    {
      '<leader>vK',
      function()
        prefill_edit_window(avante_keywords)
      end,
      desc = 'Keywords',
    },
    {
      '<leader>vO',
      function()
        prefill_edit_window(avante_optimize_code)
      end,
      desc = 'Optimize Code(edit)',
    },
    {
      '<leader>vC',
      function()
        prefill_edit_window(avante_complete_code)
      end,
      desc = 'Complete Code(edit)',
    },
    {
      '<leader>vD',
      function()
        prefill_edit_window(avante_add_docstring)
      end,
      desc = 'Docstring(edit)',
    },
    {
      '<leader>vB',
      function()
        prefill_edit_window(avante_fix_bugs)
      end,
      desc = 'Fix Bugs(edit)',
    },
    {
      '<leader>vU',
      function()
        prefill_edit_window(avante_add_tests)
      end,
      desc = 'Add Tests(edit)',
    },
  },
}

return M