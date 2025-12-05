-- Core vim.pack wrapper functions
local M = {}

--- Get all installed plugins or filter by names
---@param names? string[] Optional list of plugin names to filter
---@return table[] List of plugin info
function M.get_plugins(names)
  if names and #names > 0 then
    return vim.pack.get(names)
  else
    return vim.pack.get()
  end
end

--- List all installed plugins
function M.list_plugins()
  local plugins = M.get_plugins()

  if #plugins == 0 then
    vim.notify('No plugins installed via vim.pack', vim.log.levels.INFO)
    return
  end

  -- Sort plugins by name
  table.sort(plugins, function(a, b)
    return a.spec.name < b.spec.name
  end)

  -- Build output
  local lines = { 'Installed Plugins:', '' }
  for _, plugin in ipairs(plugins) do
    table.insert(lines, string.format('  %-40s', plugin.spec.name))
  end

  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
end

--- Update one or all plugins
---@param name? string Plugin name to update (empty or nil = update all)
---@param bang? boolean If true, skip confirmation buffer
function M.update_plugin(name, bang)
  if name and name ~= '' then
    -- Update specific plugin
    vim.notify(string.format('Updating plugin: %s', name), vim.log.levels.INFO)
    vim.pack.update({ name }, { confirm = not bang })
  else
    -- Update all plugins (nil = all)
    vim.notify('Updating all plugins...', vim.log.levels.INFO)
    vim.pack.update(nil, { confirm = not bang })
  end
end

--- Delete one or more plugins
---@param names string[] List of plugin names to delete
function M.delete_plugins(names)
  if #names == 0 then
    vim.notify('No plugin names provided', vim.log.levels.WARN)
    return
  end

  -- Confirm deletion
  local plugin_list = table.concat(names, ', ')
  local confirm = vim.fn.confirm(string.format('Delete the following plugins?\n%s', plugin_list), '&Yes\n&No', 2)

  if confirm ~= 1 then
    vim.notify('Deletion cancelled', vim.log.levels.INFO)
    return
  end

  vim.pack.del(names)
  vim.notify(string.format('Deleted plugins: %s', plugin_list), vim.log.levels.INFO)
end

--- Get plugin name completion
---@return string[]
function M.get_plugin_names()
  local plugins = M.get_plugins()
  local names = {}

  for _, plugin in ipairs(plugins) do
    table.insert(names, plugin.spec.name)
  end

  return names
end

--- Custom completion function for plugin names
---@param arg_lead string The leading portion of the argument being completed
---@param cmd_line string The entire command line
---@param cursor_pos number The cursor position in the command line
---@return string[]
function M.complete_plugin_names(arg_lead, cmd_line, cursor_pos)
  local plugins = vim.pack.get()
  local names = {}
  for _, plugin in ipairs(plugins) do
    table.insert(names, plugin.spec.name)
  end
  return vim.tbl_filter(function(name)
    return vim.startswith(name, arg_lead)
  end, names)
end

return M
