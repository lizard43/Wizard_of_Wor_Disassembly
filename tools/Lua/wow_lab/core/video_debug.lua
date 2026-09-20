-- core/video_debug.lua
-- Reusable Wizard of Wor Lab video-memory capture and comparison service.
--
-- The service deliberately knows nothing about sprites, menus, or Magic RAM.
-- A module supplies a rectangular video-memory region and, when comparing it,
-- an optional expected-write rectangle.  Results are returned as structured
-- Lua tables so each module can apply its own terminology and logging policy.

local M = {}
M.__index = M
M.VERSION = '1.0.0-20260817-1645'

local DEFAULT_VIDEO_BASE = 0x4000
local DEFAULT_STRIDE_BYTES = 80

local function integer(value, name, minimum)
  value = tonumber(value)
  assert(value and value == math.floor(value), name .. ' must be an integer')
  if minimum ~= nil then assert(value >= minimum, name .. ' is out of range') end
  return value
end

local function copy_table(source)
  local out = {}
  for key, value in pairs(source or {}) do out[key] = value end
  return out
end

local function normalize_region(region)
  region = region or {}
  local out = {
    base = integer(region.base or DEFAULT_VIDEO_BASE, 'region.base', 0),
    stride_bytes = integer(region.stride_bytes or DEFAULT_STRIDE_BYTES,
      'region.stride_bytes', 1),
    x_byte = integer(region.x_byte or 0, 'region.x_byte', 0),
    y = integer(region.y or 0, 'region.y', 0),
    width_bytes = integer(region.width_bytes or DEFAULT_STRIDE_BYTES,
      'region.width_bytes', 1),
    height = integer(region.height or 1, 'region.height', 1),
  }
  assert(out.x_byte + out.width_bytes <= out.stride_bytes,
    'video region crosses its row stride')
  return out
end

local function normalize_expected(region, expected)
  if expected == nil then return nil end
  expected = expected or {}
  local out = {
    x_byte = integer(expected.x_byte, 'expected.x_byte', 0),
    y = integer(expected.y, 'expected.y', 0),
    width_bytes = integer(expected.width_bytes, 'expected.width_bytes', 1),
    height = integer(expected.height, 'expected.height', 1),
  }
  assert(out.x_byte + out.width_bytes <= region.stride_bytes,
    'expected-write region crosses the video row stride')
  return out
end

local function fnv1a(bytes)
  local hash = 0x811C9DC5
  for _, byte in ipairs(bytes) do
    hash = ((hash ~ byte) * 0x01000193) & 0xFFFFFFFF
  end
  return hash
end

local function update_bounds(bounds, address, x_byte, y)
  bounds.min_address = math.min(bounds.min_address or address, address)
  bounds.max_address = math.max(bounds.max_address or address, address)
  bounds.min_x_byte = math.min(bounds.min_x_byte or x_byte, x_byte)
  bounds.max_x_byte = math.max(bounds.max_x_byte or x_byte, x_byte)
  bounds.min_y = math.min(bounds.min_y or y, y)
  bounds.max_y = math.max(bounds.max_y or y, y)
end

function M.new(program_space)
  assert(program_space and type(program_space.read_u8) == 'function',
    'video debug requires a program space with read_u8')
  return setmetatable({
    program = program_space,
    snapshots = {},
  }, M)
end

-- Capture a row-major copy of a rectangular video-memory region.  Metadata is
-- copied shallowly and remains diagnostic context; it never affects comparison.
function M:capture(name, region, metadata)
  assert(type(name) == 'string' and name ~= '', 'snapshot name is required')
  region = normalize_region(region)
  local bytes = {}
  for row = 0, region.height - 1 do
    local address = region.base + (region.y + row) * region.stride_bytes
      + region.x_byte
    for column = 0, region.width_bytes - 1 do
      bytes[#bytes + 1] = self.program:read_u8(address + column)
    end
  end

  local snapshot = {
    name = name,
    region = region,
    metadata = copy_table(metadata),
    bytes = bytes,
    byte_count = #bytes,
    hash = fnv1a(bytes),
  }
  self.snapshots[name] = snapshot
  return snapshot
end

-- Compare a named capture with current memory.  Every changed byte contributes
-- to global bounds; bytes outside expected_write are counted separately.
function M:compare(name, expected_write)
  local snapshot = self.snapshots[name]
  if not snapshot then return nil, 'snapshot not found: ' .. tostring(name) end

  local region = snapshot.region
  local expected = normalize_expected(region, expected_write)
  local changed = {}
  local bounds = {}
  local outside_bounds = {}
  local outside_count = 0
  local current_bytes = {}
  local byte_index = 0

  for row = 0, region.height - 1 do
    local y = region.y + row
    local row_address = region.base + y * region.stride_bytes + region.x_byte
    for column = 0, region.width_bytes - 1 do
      byte_index = byte_index + 1
      local x_byte = region.x_byte + column
      local address = row_address + column
      local before = snapshot.bytes[byte_index]
      local after = self.program:read_u8(address)
      current_bytes[byte_index] = after
      if before ~= after then
        changed[#changed + 1] = {
          address = address,
          x_byte = x_byte,
          y = y,
          before = before,
          after = after,
        }
        update_bounds(bounds, address, x_byte, y)

        local inside = not expected
          or (x_byte >= expected.x_byte
            and x_byte < expected.x_byte + expected.width_bytes
            and y >= expected.y
            and y < expected.y + expected.height)
        if not inside then
          outside_count = outside_count + 1
          update_bounds(outside_bounds, address, x_byte, y)
        end
      end
    end
  end

  return {
    name = name,
    region = copy_table(region),
    expected_write = expected and copy_table(expected) or nil,
    metadata = copy_table(snapshot.metadata),
    snapshot_hash = snapshot.hash,
    current_hash = fnv1a(current_bytes),
    changed_count = #changed,
    changed = changed,
    bounds = bounds,
    outside_count = outside_count,
    outside_bounds = outside_bounds,
  }
end

function M:status(name)
  local snapshot = self.snapshots[name]
  if not snapshot then return nil end
  return {
    name = snapshot.name,
    region = copy_table(snapshot.region),
    metadata = copy_table(snapshot.metadata),
    byte_count = snapshot.byte_count,
    hash = snapshot.hash,
  }
end

function M:clear(name)
  local existed = self.snapshots[name] ~= nil
  self.snapshots[name] = nil
  return existed
end

function M:clear_all()
  local count = 0
  for name in pairs(self.snapshots) do
    self.snapshots[name] = nil
    count = count + 1
  end
  return count
end

return M
