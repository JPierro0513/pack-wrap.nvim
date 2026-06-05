local M = {}

---@class PluginSpec
---@field src? string The GitHub user/repo of the plugin
---@field [1] string The GitHub user/repo of the plugin (positional alternative to src)
---@field event? string|string[] Optional event(s) to trigger loading
---@field pattern? string|string[] Optional pattern(s) to trigger loading
---@field build? string|fun():nil Optional build: 'shell cmd', ':VimCmd', or function
---@field name? string Optional name override (defaults to repo name)
---@field version? string Optional version constraint
---@field module_name? string Optional module name for configuration
---@field opts? table|fun():table Optional options passed to plugin.setup()
---@field config? fun():nil Optional function run after the plugin loads
---@field keys? table Optional key bindings for the plugin

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

--- List all installed plugins
function M.list_plugins()
  local plugins = M.get_plugin_names()
  if #plugins == 0 then
    vim.notify('No plugins installed via vim.pack', vim.log.levels.INFO)
    return
  end
  local lines = { 'Installed Plugins:' }
  for _, plugin in ipairs(plugins) do
    table.insert(lines, string.format('  %-40s', plugin))
  end
  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
end

--- Update one or all plugins
---@param name? string Plugin name to update (empty or nil = update all)
---@param bang? boolean If true, skip confirmation buffer
function M.update_plugins(name, bang)
  if name and name ~= '' then
    -- Update specific plugin
    vim.notify(string.format('Updating plugin: %s', name), vim.log.levels.INFO)
    vim.pack.update({ name }, { force = bang })
  else
    -- Update all plugins (nil = all)
    vim.notify('Updating all plugins...', vim.log.levels.INFO)
    vim.pack.update(nil, { force = bang })
  end
end

--- Delete one or more plugins
---@param names string[] List of plugin names to delete
function M.delete_plugins(names)
  if #names == 0 then
    vim.notify('No plugin names provided', vim.log.levels.WARN)
    return
  end
  local plugin_list = table.concat(names, ', ')
  local confirm = vim.fn.confirm(string.format('Delete the following plugins?\n%s', plugin_list), '&Yes\n&No', 2)
  if confirm ~= 1 then
    vim.notify('Deletion cancelled', vim.log.levels.INFO)
    return
  end
  vim.pack.del(names)
  vim.notify(string.format('Deleted plugins: %s', plugin_list), vim.log.levels.INFO)
end

--- Completion function for plugin names
---@param arg_lead string The leading portion of the argument being completed
---@param _cmd_line string The entire command line
---@param _cursor_pos number The cursor position in the command line
---@return string[]
function M.complete_plugin_names(arg_lead, _cmd_line, _cursor_pos)
  local plugins = vim.pack.get()
  local names = {}
  for _, plugin in ipairs(plugins) do
    table.insert(names, plugin.spec.name)
  end
  return vim.tbl_filter(function(name)
    return vim.startswith(name, arg_lead)
  end, names)
end

---@class keyspec.opts: vim.keymap.set.Opts
---@field mode? string The mode to bind the key in (default: 'n')
---@class keyspec
---@field [1] string lhs - The key to bind
---@field [2] string|function rhs - The function to call when the key is pressed
---@field [3]? keyspec.opts|string Additional options or description string

--- Set up keybinds from a list of key mapping specifications
---@param keys keyspec[] List of key mapping specifications
function M.setup_keybinds(keys)
  if not keys then
    return
  end
  for _, map in ipairs(keys) do
    local lhs = map[1]
    local rhs = map[2]
    local opts = {}
    local mode = 'n'
    if type(map[3]) == 'string' then
      opts = { desc = map[3] }
    elseif type(map[3]) == 'table' then
      mode = map[3].mode or 'n'
      map[3].mode = nil
      opts = map[3] --[[@as vim.keymap.set.Opts]]
    end
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

---@param plugins PluginSpec|PluginSpec[]
---@return PluginSpec[]
function M.normalize(plugins)
  if type(plugins[1]) == 'string' or plugins.src then
    return { plugins }
  end
  return plugins
end

---@param spec PluginSpec
function M.configure_spec(spec)
  local src = spec.src or spec[1]
  local reserved = { src = true, name = true, version = true, [1] = true }
  local data = {}
  for k, v in pairs(spec) do
    if not reserved[k] then
      data[k] = v
    end
  end
  return {
    src = 'https://github.com/' .. src,
    name = spec.name or src:match('/([^/]+)$'),
    version = spec.version,
    data = data,
  }
end

return M
