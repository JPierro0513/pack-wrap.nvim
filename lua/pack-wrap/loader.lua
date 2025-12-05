-- Plugin spec transformation and loading
local M = {}

--- Transform lazy.nvim-style spec to vim.pack spec
---@param spec table The lazy.nvim-style plugin spec
---@return table? pack_spec, table? metadata Returns pack_spec and metadata (config, keys, build) or nil
function M.transform_spec(spec)
  local pack_spec = {}
  local metadata = {
    config = spec.config,
    keys = spec.keys,
    build = spec.build,
  }

  -- Handle string format: 'author/repo' -> full GitHub URL
  if type(spec) == 'string' then
    pack_spec.src = 'https://github.com/' .. spec
  elseif type(spec[1]) == 'string' then
    pack_spec.src = 'https://github.com/' .. spec[1]
    pack_spec.name = spec.name
    pack_spec.version = spec.version
    pack_spec.data = spec.data
  elseif spec.src then
    pack_spec = { src = spec.src, name = spec.name, version = spec.version, data = spec.data }
  end

  if pack_spec.src then
    return pack_spec, metadata
  end

  return nil, nil
end

--- Load plugins using vim.pack.add
---@param specs table|table[] Single spec or array of pack specs
function M.load_plugins(specs)
  if type(specs) == 'table' and not specs.src then
    -- Array of specs
    vim.pack.add(specs)
  else
    -- Single spec
    vim.pack.add({ specs })
  end
end

--- Get plugin path from pack spec
---@param spec table Pack spec with name or src
---@return string Plugin path
function M.get_plugin_path(spec)
  local plugin_name = spec.name or spec.src:match('([^/]+)$'):gsub('%.git$', '')
  return vim.fn.stdpath('data') .. '/site/pack/core/opt/' .. plugin_name
end

--- Setup keymaps from plugin keys spec
---@param keys table Array of keymap specs
function M.setup_keymaps(keys)
  if not keys then
    return
  end

  for _, keymap in ipairs(keys) do
    local key = keymap[1]
    local action = keymap[2]
    local mode = keymap.mode or 'n'
    local desc = keymap.desc
    vim.keymap.set(mode, key, action, { desc = desc })
  end
end

--- Load plugin specs from a folder
---@param folder string Path to folder containing plugin spec files
---@return table[] Array of processed plugin specs
function M.load_specs_from_folder(folder)
  local specs = {}

  -- Get all .lua files in the folder
  local files = vim.fn.glob(folder .. '/*.lua', false, true)

  for _, file in ipairs(files) do
    local filename = vim.fn.fnamemodify(file, ':t:r')

    -- Skip init.lua to avoid circular dependencies
    if filename ~= 'init' then
      -- Convert file path to module path
      local module_path = folder:gsub(vim.fn.stdpath('config') .. '/lua/', ''):gsub('/', '.') .. '.' .. filename

      local ok, spec = pcall(require, module_path)
      if ok and spec then
        -- Check if spec is an array of specs
        local is_array = type(spec) == 'table' and type(spec[1]) == 'table'

        if is_array then
          -- Handle array of specs: { { 'plugin1' }, { 'plugin2' } }
          for _, single_spec in ipairs(spec) do
            local pack_spec, metadata = M.transform_spec(single_spec)
            if pack_spec then
              table.insert(specs, {
                pack_spec = pack_spec,
                config = metadata.config,
                keys = metadata.keys,
                build = metadata.build,
              })
            end
          end
        else
          -- Handle single spec: { 'plugin' } or 'plugin'
          local pack_spec, metadata = M.transform_spec(spec)
          if pack_spec then
            table.insert(specs, {
              pack_spec = pack_spec,
              config = metadata.config,
              keys = metadata.keys,
              build = metadata.build,
            })
          end
        end
      end
    end
  end

  return specs
end

--- Process and load a list of plugin specs
---@param raw_specs table[] Array of lazy.nvim-style specs
---@return table[] Array of processed plugin specs
function M.process_specs(raw_specs)
  local specs = {}

  for _, spec in ipairs(raw_specs) do
    -- Check if it's an array of specs
    local is_array = type(spec) == 'table' and type(spec[1]) == 'table'

    if is_array then
      for _, single_spec in ipairs(spec) do
        local pack_spec, metadata = M.transform_spec(single_spec)
        if pack_spec then
          table.insert(specs, {
            pack_spec = pack_spec,
            config = metadata.config,
            keys = metadata.keys,
            build = metadata.build,
          })
        end
      end
    else
      local pack_spec, metadata = M.transform_spec(spec)
      if pack_spec then
        table.insert(specs, {
          pack_spec = pack_spec,
          config = metadata.config,
          keys = metadata.keys,
          build = metadata.build,
        })
      end
    end
  end

  return specs
end

return M
