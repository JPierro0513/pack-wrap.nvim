local M = {}

local utils = require('pack-wrap.utils')
local add = require('pack-wrap.add')

M.add = add.add
M.list_plugins = utils.list_plugins
M.update_plugins = utils.update_plugins
M.delete_plugins = utils.delete_plugins
M.complete_plugin_names = utils.complete_plugin_names

---@param folder string Module path under the config lua dir (e.g. 'plugins')
function M.load_from_folder(folder)
  local path = vim.fn.stdpath('config') .. '/lua/' .. folder:gsub('%.', '/')
  local files = vim.fn.glob(path .. '/*.lua', false, true)
  local all_specs = {}
  for _, file in ipairs(files) do
    local filename = vim.fn.fnamemodify(file, ':t:r')
    if filename ~= 'init' then
      local ok, spec = pcall(require, folder .. '.' .. filename)
      if ok and spec then
        for _, s in ipairs(utils.normalize(spec)) do
          table.insert(all_specs, s)
        end
      end
    end
  end
  if #all_specs > 0 then
    M.add(all_specs)
  end
end

return M
