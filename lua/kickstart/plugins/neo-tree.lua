-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    { '\\', ':Neotree reveal<CR>', { desc = 'NeoTree reveal' } },
  },
  opts = {
    filesystem = {
      filtered_items = {
        -- visible = true,
        show_hidden_count = true,
        hide_dotfiles = false, -- jiawzhang: show hidden files
        hide_gitignored = true,
      },
      use_libuv_file_watcher = true,
      window = {
        mappings = {
          ['\\'] = 'close_window',
          ['z'] = 'close_all_nodes',
          ['Z'] = 'expand_all_nodes', -- jiawzhang: 'Z' to expand all nodes
        },
      },
    },
    -- NOTE: jiawzhang install: "sudo apt install fd-find", this will fix fuzzy_find bug with "find" linux command.
    find_command = 'fd', -- this is determined automatically, you probably don't need to set it
    find_args = { -- you can specify extra args to pass to the find command.
      fd = {
        '--exclude',
        '.git',
        '--exclude',
        'node_modules',
      },
    },
  },
}
