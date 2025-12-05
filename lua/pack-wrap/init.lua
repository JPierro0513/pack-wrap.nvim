-- pack-wrap: A wrapper around vim.pack for easier plugin management
local M = {}

-- Import submodules
local core = require('pack-wrap.core')
local build = require('pack-wrap.build')
local loader = require('pack-wrap.loader')

-- Store plugin specs for rebuild on update
M._plugin_specs = {}

-- Re-export core functions
M.get_plugins = core.get_plugins
M.list_plugins = core.list_plugins
M.update_plugin = core.update_plugin
M.delete_plugins = core.delete_plugins
M.get_plugin_names = core.get_plugin_names
M.complete_plugin_names = core.complete_plugin_names

-- Re-export build functions
M.has_build_marker = build.has_marker
M.create_build_marker = build.create_marker
M.remove_build_marker = build.remove_marker
M.execute_build = build.execute

-- Re-export loader functions
M.transform_spec = loader.transform_spec
M.load_plugins = loader.load_plugins
M.get_plugin_path = loader.get_plugin_path
M.setup_keymaps = loader.setup_keymaps

--- Load a plugin immediately (for early dependencies)
---@param spec string|table Plugin spec (lazy.nvim format)
function M.add(spec)
  local pack_spec, metadata = loader.transform_spec(spec)
  if not pack_spec then
    vim.notify('pack-wrap.add: Invalid plugin spec', vim.log.levels.ERROR)
    return
  end

  -- Load plugin immediately
  loader.load_plugins(pack_spec)

  -- Store in specs for update tracking
  local plugin_name = pack_spec.name or pack_spec.src:match('([^/]+)$'):gsub('%.git$', '')
  M._plugin_specs[plugin_name] = {
    pack_spec = pack_spec,
    config = metadata.config,
    keys = metadata.keys,
    build = metadata.build,
  }

  -- Run config immediately if provided
  if metadata.config and type(metadata.config) == 'function' then
    metadata.config()
  end

  -- Setup keymaps immediately
  loader.setup_keymaps(metadata.keys)
end

--- Main setup function to load and configure plugins
---@param opts string|table Either a folder name (string) or array of plugin specs (table)
function M.setup(opts)
  local plugin_specs = {}

  -- Handle string argument as folder name
  if type(opts) == 'string' then
    local folder_path = vim.fn.stdpath('config') .. '/lua/' .. opts
    plugin_specs = loader.load_specs_from_folder(folder_path)
  elseif type(opts) == 'table' then
    plugin_specs = loader.process_specs(opts)
  else
    vim.notify('pack-wrap: No specs or folder provided', vim.log.levels.WARN)
    return
  end

  -- Store plugin specs for later access (e.g., rebuild on update)
  for _, entry in ipairs(plugin_specs) do
    local plugin_name = entry.pack_spec.name or entry.pack_spec.src:match('([^/]+)$'):gsub('%.git$', '')
    M._plugin_specs[plugin_name] = entry
  end

  -- Extract pack_specs for loading
  local pack_specs = {}
  for _, entry in ipairs(plugin_specs) do
    table.insert(pack_specs, entry.pack_spec)
  end

  -- Load all plugins at once
  if #pack_specs > 0 then
    loader.load_plugins(pack_specs)
  end

  -- Separate plugins that need building from those that don't
  local build_queue = {}
  local no_build_queue = {}

  for _, entry in ipairs(plugin_specs) do
    if entry.build then
      table.insert(build_queue, entry)
    else
      table.insert(no_build_queue, entry)
    end
  end

  -- Setup autocmd to handle plugin updates
  vim.api.nvim_create_autocmd('User', {
    pattern = 'PackChanged',
    callback = function(args)
      local spec = args.data.spec
      local plugin_name = spec.name or vim.fn.fnamemodify(spec.src, ':t:r')
      local plugin_path = args.data.path

      vim.notify('PackChanged event: ' .. plugin_name, vim.log.levels.DEBUG)

      -- Find the plugin spec
      local entry = M._plugin_specs[plugin_name]
      if not entry then
        vim.notify('PackChanged: plugin "' .. plugin_name .. '" not found in specs', vim.log.levels.WARN)
        return
      end

      -- Remove build marker
      if build.has_marker(plugin_path) then
        build.remove_marker(plugin_path)
      end

      -- If plugin has a build command, run it immediately
      if entry.build then
        vim.notify('Plugin ' .. plugin_name .. ' updated, rebuilding...', vim.log.levels.INFO)

        local on_success = function()
          -- Run config after successful build
          if entry.config and type(entry.config) == 'function' then
            entry.config()
          end
          loader.setup_keymaps(entry.keys)
          vim.notify('Plugin ' .. plugin_name .. ' rebuilt successfully', vim.log.levels.INFO)
        end

        build.execute(entry.build, plugin_name, plugin_path, on_success)
      else
        vim.notify('Plugin ' .. plugin_name .. ' updated', vim.log.levels.INFO)
      end
    end,
  })

  -- Run configs for plugins that don't need building immediately
  vim.api.nvim_create_autocmd('VimEnter', {
    callback = function()
      -- Process non-build plugins first
      for _, entry in ipairs(no_build_queue) do
        if entry.config and type(entry.config) == 'function' then
          entry.config()
        end
        loader.setup_keymaps(entry.keys)
      end

      -- Process build plugins
      for _, entry in ipairs(build_queue) do
        local plugin_name = entry.pack_spec.name or entry.pack_spec.src:match('([^/]+)$'):gsub('%.git$', '')
        local plugin_path = loader.get_plugin_path(entry.pack_spec)

        if vim.fn.isdirectory(plugin_path) == 0 then
          vim.notify('Plugin directory not found: ' .. plugin_path, vim.log.levels.WARN)
        else
          -- Check if already built
          if build.has_marker(plugin_path) then
            -- Already built, just run config and setup keymaps
            if entry.config and type(entry.config) == 'function' then
              entry.config()
            end
            loader.setup_keymaps(entry.keys)
          else
            -- Need to build
            local on_success = function()
              if entry.config and type(entry.config) == 'function' then
                entry.config()
              end
              loader.setup_keymaps(entry.keys)
            end

            build.execute(entry.build, plugin_name, plugin_path, on_success)
          end
        end
      end
    end,
    once = true,
  })
end

return M
