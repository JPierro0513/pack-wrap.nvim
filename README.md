# pack-wrap.nvim

A lightweight wrapper around Neovim's built-in `vim.pack` API.

## Requirements

- Neovim 0.12+ (requires `vim.pack` API)

## Installation

Bootstrap pack-wrap itself using `vim.pack` directly in your `init.lua`:

```lua
vim.pack.add({ 'https://github.com/jpierro0513/pack-wrap.nvim' })
```

## Plugin Spec

Each plugin is declared as a table. The only required field is the GitHub shorthand (index 1 or `src`):

```lua
{
  --[[src =]] 'user/repo',  -- GitHub shorthand; expands to https://github.com/user/repo
  name = 'name',            -- optional: override the plugin directory name
  module_name = 'mod',      -- optional: override the module name used for require(module_name)
  version = '*',            -- optional: version constraint passed to vim.pack
  event = 'BufEnter',       -- optional: defer loading until this event fires
  pattern = '*.lua',        -- optional: event pattern for lazy loading
  build = ':TSUpdate',      -- optional: run after install/update (see Build Hooks)
  opts = {},                -- optional: passed to plugin.setup(opts)
  config = function()       -- optional: called after load (runs after opts setup)
  end,
  keys = {                  -- optional: keybindings registered after load
    { '<leader>f', function() end, 'Description' },
  },
}
```

## Usage

### Load from plugin/

Any lua file inside this directory will automatically get included in the vim runtime and get run.

```lua
-- plugin/blink.lua
require('pack-wrap').add({
  { 'saghen/blink.lib' },
  { 'saghen/blink.cmp'
    event = 'InsertEnter',
    build = function()
      vim.cmd.packadd('blink.lib')
      require('blink.cmp').build():pwait()
    end,
    opts = {...}
  },
  ...
})

-- plugin/mini.lua
require('pack-wrap').add({
  { 'nvim-mini/mini.icons', ... },
  ...
})
```

### Load from a different folder

Load all `.lua` files from `~/.config/nvim/lua/plugins/`:

```lua
-- init.lua
require('pack-wrap').load_from_folder('plugins')
```

Each file returns a single spec or a list of specs:

```lua
-- lua/plugins/treesitter.lua
return {
  'nvim-treesitter/nvim-treesitter',
  version = 'main',
  build = ':TSUpdate',
  config = function()
    -- your config
  end,
}
```

### Load from a table

```lua
require('pack-wrap').add({
  { 'nvim-treesitter/nvim-treesitter', version = 'main', build = ':TSUpdate' },
  { 'folke/which-key.nvim', opts = {} },
})
```

A single spec (not wrapped in a list) also works:

```lua
require('pack-wrap').add({ 'folke/which-key.nvim', opts = {} })
```

### Lazy loading

Defer loading until an event fires. Plugins sharing the same event and pattern are batched into a single `vim.pack.add` call:

```lua
{ 'nvim-telescope/telescope.nvim', event = 'VeryLazy' }

{ 'some/ft-plugin', event = 'FileType', pattern = '*.lua' }

{ 'some/plugin', event = { 'BufReadPre', 'BufNewFile' } }
```

### Build hooks

Run a command after install or update:

```lua
{ 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' }     -- Vim command
{ 'some/plugin', build = 'make install' }                      -- shell command
{ 'some/plugin', build = function(path) vim.system({'make'}, { cwd = path }) end }
```

### Keybindings

Keys are registered after the plugin loads. The third element can be a description string or an options table (with an optional `mode` key, default `'n'`):

```lua
{
  'some/plugin',
  keys = {
    { '<leader>ff', function() end, 'Find files' },
    { '<leader>fg', function() end, { mode = 'v', desc = 'Live grep' } },
  },
}
```

## Commands

- `:PackList` — list all installed plugins
- `:PackUpdate [<name>]` — update all plugins, or a specific one; add `!` to skip confirmation
- `:PackDelete <name> [<name> ...]` — delete one or more plugins (space-separated, with confirmation)
