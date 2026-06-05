local M = {}

local util = require('pack-wrap.utils')

local function _load(plugin)
  vim.cmd.packadd(plugin.spec.name)

  local data = plugin.spec.data

  if data.opts ~= nil then
    local mod = require(data.module_name or plugin.spec.name:gsub('%.nvim$', ''))
    local opts = type(data.opts) == 'function' and data.opts() or data.opts
    mod.setup(opts or {})
  end

  if data.config then
    data.config()
  end

  if data.keys then
    util.setup_keybinds(data.keys)
  end
end

local function _setup_build(plugin_name, cmd)
  vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(args)
      if args.data.spec.name == plugin_name and (args.data.kind == 'install' or args.data.kind == 'update') then
        if not args.data.active then
          vim.cmd.packadd(plugin_name)
        end
        if type(cmd) == 'string' then
          if cmd:sub(1, 1) == ':' then
            vim.cmd(cmd:sub(2))
          else
            vim.system(vim.split(cmd, ' '), { cwd = args.data.path })
          end
        else
          vim.schedule(function()
            cmd(args.data.path)
          end)
        end
      end
    end,
  })
end

---@param spec PluginSpec|PluginSpec[]
function M.add(spec)
  ---@type PluginSpec[]
  spec = util.normalize(spec)
  local immediate = {}
  -- key: "event\0pattern" -> { pack_specs }
  local by_event = {}
  local event_order = {}

  for _, s in ipairs(spec) do
    local name = s.name or (s.src or s[1] or ''):match('/([^/]+)$')

    if s.build then
      _setup_build(name, s.build)
    end

    if s.event ~= nil then
      local pattern = type(s.pattern) == 'table' and s.pattern or { s.pattern or '*' }
      ---@cast pattern string[]
      -- normalise both to strings for keying; arrays become comma-joined
      local event = type(s.event) == 'table' and s.event or { s.event }
      ---@cast event string[]
      local event_key = table.concat(event, ',')
      local pattern_key = table.concat(pattern, ',')
      local key = event_key .. '\0' .. pattern_key
      if not by_event[key] then
        by_event[key] = { event = event, pattern = pattern, specs = {} }
        table.insert(event_order, key)
      end
      table.insert(by_event[key].specs, util.configure_spec(s))
    else
      table.insert(immediate, s)
    end
  end

  for _, key in ipairs(event_order) do
    local entry = by_event[key]
    local pack_specs = entry.specs
    vim.api.nvim_create_autocmd(entry.event, {
      pattern = entry.pattern,
      once = true,
      callback = function()
        vim.pack.add(pack_specs, { confirm = false, load = _load })
      end,
    })
  end

  if #immediate > 0 then
    vim.pack.add(vim.tbl_map(util.configure_spec, immediate), { confirm = false, load = _load })
  end
end

return M
