-- Build management for plugins
local M = {}

--- Check if build marker exists for a plugin
---@param plugin_path string Path to the plugin directory
---@return boolean
function M.has_marker(plugin_path)
  local build_marker = plugin_path .. '/.build_complete'
  return vim.fn.filereadable(build_marker) == 1
end

--- Create build marker for a plugin
---@param plugin_path string Path to the plugin directory
function M.create_marker(plugin_path)
  local build_marker = plugin_path .. '/.build_complete'
  vim.fn.writefile({}, build_marker)
end

--- Remove build marker for a plugin
---@param plugin_path string Path to the plugin directory
function M.remove_marker(plugin_path)
  local build_marker = plugin_path .. '/.build_complete'
  if vim.fn.filereadable(build_marker) == 1 then
    vim.fn.delete(build_marker)
  end
end

--- Execute build command for a plugin
---@param build string|function Build command or function
---@param plugin_name string Plugin name for logging
---@param plugin_path string Plugin path for shell builds
---@param on_success? function Callback on successful build
function M.execute(build, plugin_name, plugin_path, on_success)
  if type(build) == 'string' then
    -- Shell command build
    vim.notify('Building ' .. plugin_name .. ' in background...', vim.log.levels.INFO)

    vim.system({ 'sh', '-c', 'cd ' .. vim.fn.shellescape(plugin_path) .. ' && ' .. build }, {
      text = true,
      stdout = function(_, data)
        if data then
          vim.schedule(function()
            vim.notify('[' .. plugin_name .. '] ' .. data, vim.log.levels.INFO)
          end)
        end
      end,
      stderr = function(_, data)
        if data then
          vim.schedule(function()
            vim.notify('[' .. plugin_name .. '] ' .. data, vim.log.levels.WARN)
          end)
        end
      end,
    }, function(obj)
      if obj.code == 0 then
        vim.schedule(function()
          -- Create build marker
          M.create_marker(plugin_path)
          vim.notify('Build succeeded for ' .. plugin_name, vim.log.levels.INFO)

          -- Run success callback
          if on_success then
            on_success()
          end
        end)
      else
        vim.schedule(function()
          vim.notify('Build failed for ' .. plugin_name .. ' (exit code: ' .. obj.code .. ')', vim.log.levels.ERROR)
        end)
      end
    end)
  elseif type(build) == 'function' then
    -- Function build
    build()
    M.create_marker(plugin_path)

    if on_success then
      on_success()
    end
  end
end

return M
