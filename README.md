# pack-wrap.nvim

A lightweight wrapper around Neovim's built-in `vim.pack`.

## Requirements

- Neovim 0.12+ (requires `vim.pack` API)

## Installation

```lua
vim.pack.add({ { src = 'https://github.com/jpierro0513/pack-wrap.nvim' } })
```

## Usage

### Load from a folder (recommended)

```lua
require('pack-wrap').setup('plugins')
```

This loads all `.lua` files from `~/.config/nvim/lua/plugins/`. Each file returns a plugin spec:

```lua
-- lua/plugins/treesitter.lua
return {
  {
    'nvim-treesitter/nvim-treesitter',
    version = 'main',
    build = ':TSUpdate',
    config = function()
      -- your config
    end
  },
  ...
}
```

### Load from a table

```lua
require('pack-wrap').setup({
  { 'nvim-treesitter/nvim-treesitter', ... },
  { 'folke/which-key.nvim', ... },
  ...
})
```

## Commands

- `:PackList` - List plugins
- `:PackUpdate [<name>]` - Update all plugins or named one
- `:PackDelete <name1> [<name2> ...]` - Delete plugin(s)
