-- pack-wrap plugin setup
if vim.g.loaded_pack_wrap then
  return
end
vim.g.loaded_pack_wrap = 1

local pack = require('pack-wrap')

-- Create user commands for pack management
vim.api.nvim_create_user_command('PackList', function()
  pack.list_plugins()
end, { desc = 'List all installed plugins' })

vim.api.nvim_create_user_command('PackUpdate', function(opts)
  local name = #opts.fargs > 0 and opts.fargs[1] or nil
  pack.update_plugins(name, opts.bang)
end, {
  desc = 'Update plugin(s) - specify name or leave empty for all',
  bang = true,
  nargs = '*',
  complete = require('pack-wrap.utils').complete_plugin_names,
})

vim.api.nvim_create_user_command('PackDelete', function(opts)
  local names = vim.split(opts.args, '%s+')
  pack.delete_plugins(names)
end, {
  desc = 'Delete one or more plugins (space-separated)',
  nargs = '+',
  complete = require('pack-wrap.utils').complete_plugin_names,
})
