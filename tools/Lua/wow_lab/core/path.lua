-- core/path.lua
-- Path helpers for the Wizard of Wor Lab supervisor.

local M = {}
M.VERSION = '1.0.5-20260816-1814'

local function normalize(path)
  return (path:gsub('\\', '/'))
end

function M.dirname(path)
  path = normalize(path)
  local dir = path:match('^(.*)/[^/]*$')
  if not dir or dir == '' then return '.' end
  return dir
end

function M.join(a, b)
  a = normalize(a)
  b = normalize(b)
  if a:sub(-1) == '/' then return a .. b end
  return a .. '/' .. b
end

function M.script_path(level)
  local info = debug.getinfo(level or 2, 'S')
  local source = info and info.source or ''
  if source:sub(1, 1) == '@' then source = source:sub(2) end
  return normalize(source)
end

function M.script_dir(level)
  return M.dirname(M.script_path((level or 2) + 1))
end

return M
