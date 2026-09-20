-- core/module_loader.lua
-- Dynamic module discovery and lifecycle loading.
--
-- Every visible module is a .lua file in the modules directory.  Discovery
-- reads filenames plus a bounded VERSION metadata scan; module code is executed
-- only when selected.
-- Menu labels come from filenames and entries sort alphabetically.  An optional
-- numeric prefix can be used when an explicit ordering is desired; the prefix is
-- not shown in the menu.
--
--   speech_browser.lua      ->  SPEECH BROWSER
--   sound_browser.lua       ->  SOUND BROWSER
--   010_sprite_lab.lua      ->  SPRITE LAB

local M = {}
M.__index = M
M.VERSION = '1.1.1-20260817-0848'

local function filesystem()
  local ok, lib = pcall(require, 'lfs')
  if ok and lib then return lib end
  if _G.lfs then return _G.lfs end
  error('LuaFileSystem (lfs) is required for dynamic module discovery')
end


local function compact_version(version)
  local major, minor, patch = tostring(version or ''):match('^(%d+)%.(%d+)%.(%d+)')
  if not major then return 'V---' end
  return 'V' .. major .. minor .. patch
end

local function version_from_source(path)
  local file = io.open(path, 'r')
  if not file then return nil end

  local version
  local bytes = 0
  local lines = 0
  for line in file:lines() do
    lines = lines + 1
    bytes = bytes + #line + 1
    version = line:match("^%s*[%a_][%w_]*%.VERSION%s*=%s*'([^']+)'")
        or line:match('^%s*[%a_][%w_]*%.VERSION%s*=%s*"([^"]+)"')
        or line:match("^%s*VERSION%s*=%s*'([^']+)'")
        or line:match('^%s*VERSION%s*=%s*"([^"]+)"')
    if version or lines >= 96 or bytes >= 16384 then break end
  end
  file:close()
  return version
end

local function label_from_filename(filename)
  local stem = filename:gsub('%.lua$', '')
  local order, label = stem:match('^(%d+)[_%-](.+)$')
  if not label then label = stem end
  label = label:gsub('[_%-]+', ' '):upper()
  return tonumber(order) or 1000000, label
end

function M.new(path, path_api)
  return setmetatable({
    path = path,
    path_api = path_api,
    entries = {},
  }, M)
end

function M:scan()
  local lfs = filesystem()
  local entries = {}

  for filename in lfs.dir(self.path) do
    if filename ~= '.' and filename ~= '..'
        and filename:match('%.lua$')
        and filename:sub(1, 1) ~= '_' then
      local order, label = label_from_filename(filename)
      local path = self.path_api.join(self.path, filename)
      local version = version_from_source(path)
      entries[#entries + 1] = {
        filename = filename,
        path = path,
        order = order,
        label = label,
        version = version,
        version_tag = compact_version(version),
      }
    end
  end

  table.sort(entries, function(a, b)
    if a.order ~= b.order then return a.order < b.order end
    if a.label ~= b.label then return a.label < b.label end
    return a.filename < b.filename
  end)

  self.entries = entries
  return entries
end

local function validate(module, entry)
  if type(module) ~= 'table' then
    return nil, entry.filename .. ' must return a module table'
  end
  if module.start ~= nil and type(module.start) ~= 'function' then
    return nil, entry.filename .. ': start must be a function'
  end
  if module.update ~= nil and type(module.update) ~= 'function' then
    return nil, entry.filename .. ': update must be a function'
  end
  if module.stop ~= nil and type(module.stop) ~= 'function' then
    return nil, entry.filename .. ': stop must be a function'
  end
  return module
end

function M:load(index)
  local entry = self.entries[index]
  if not entry then return nil, 'module index is out of range' end

  local chunk, err = loadfile(entry.path)
  if not chunk then return nil, err end

  local ok, module = pcall(chunk)
  if not ok then return nil, module end

  module, err = validate(module, entry)
  if not module then return nil, err end

  if module.VERSION ~= nil then
    entry.version = tostring(module.VERSION)
    entry.version_tag = compact_version(entry.version)
  end
  module.__entry = entry
  return module
end

return M
