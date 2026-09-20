-- core/lab_text.lua
-- Wizard of Wor Lab text/font support shared by native-screen modules.
--
-- Install this file as core/lab_text.lua.  It deliberately does not draw from
-- Lua and does not replace WoW's resident $03B5 renderer.  Instead it provides
-- font metrics, layout validation, native string encoding, and address-neutral
-- font/data emitters.  Individual modules remain responsible for installing and
-- executing their native Z80 renderer inside their disposable application RAM.

local M = {}
M.VERSION = '1.0.0-20260819-2213'

M.SCREEN_WIDTH_PIXELS = 320
M.SCREEN_HEIGHT_PIXELS = 204
M.SCREEN_STRIDE_BYTES = 80
M.VIDEO_START = 0x4000
M.VISIBLE_VIDEO_END = 0x7FBF

-- Keep the existing WOW Lab color convention.  These are XPAND-style values;
-- a direct packed-pixel renderer obtains the 2-bit pixel value with >> 2.
M.colors = {
  BLACK = 0x00,
  BLUE = 0x04,
  YELLOW = 0x08,
  RED = 0x0C,
}

local function integer(value, label, minimum, maximum)
  value = tonumber(value)
  assert(value and value == math.floor(value), tostring(label) .. ' must be an integer')
  if minimum ~= nil then assert(value >= minimum, tostring(label) .. ' is below range') end
  if maximum ~= nil then assert(value <= maximum, tostring(label) .. ' is above range') end
  return value
end

local function require_fonts(fonts)
  assert(fonts and type(fonts.face) == 'function' and type(fonts.encode) == 'function',
    'LabFonts API is required')
  return fonts
end

function M.pixel_color(xpand)
  xpand = integer(xpand or 0, 'XPAND color', 0, 0xFF)
  if xpand == 0 then return 0 end
  assert(xpand == M.colors.BLUE or xpand == M.colors.YELLOW or xpand == M.colors.RED,
    string.format('unsupported Lab text color $%02X', xpand))
  return (xpand >> 2) & 0x03
end

function M.metrics(fonts, face_name)
  local face = require_fonts(fonts).face(face_name)
  return {
    id = face.id,
    label = face.label,
    glyph_width = face.glyph_width,
    glyph_height = face.glyph_height,
    cell_width = face.cell_width,
    cell_height = face.cell_height,
    columns = math.floor(M.SCREEN_WIDTH_PIXELS / face.cell_width),
    rows = math.floor(M.SCREEN_HEIGHT_PIXELS / face.cell_height),
  }
end

function M.measure(fonts, face_name, text)
  local face = require_fonts(fonts).face(face_name)
  local count = #fonts.encode(text)
  return count * face.cell_width, face.cell_height, count
end

function M.center_x(fonts, face_name, text)
  local width = M.measure(fonts, face_name, text)
  return math.max(0, math.floor((M.SCREEN_WIDTH_PIXELS - width) / 2))
end

function M.right_x(fonts, face_name, text, margin)
  local width = M.measure(fonts, face_name, text)
  margin = integer(margin or 0, 'right margin', 0, M.SCREEN_WIDTH_PIXELS)
  return math.max(0, M.SCREEN_WIDTH_PIXELS - margin - width)
end

function M.validate_box(fonts, face_name, x, y, text)
  local width, height = M.measure(fonts, face_name, text)
  x = integer(x, 'x', 0, M.SCREEN_WIDTH_PIXELS - 1)
  y = integer(y, 'y', 0, M.SCREEN_HEIGHT_PIXELS - 1)
  assert(x + width <= M.SCREEN_WIDTH_PIXELS,
    string.format('%s text crosses right edge: x=%d width=%d', tostring(face_name), x, width))
  assert(y + height <= M.SCREEN_HEIGHT_PIXELS,
    string.format('%s text crosses bottom edge: y=%d height=%d', tostring(face_name), y, height))
  return { x=x, y=y, width=width, height=height }
end

function M.encode_string(fonts, text, zero_terminated)
  fonts = require_fonts(fonts)
  local bytes = fonts.encode(text)
  if zero_terminated ~= false then bytes[#bytes + 1] = 0 end
  return bytes
end

local function emit_bytes(a, bytes)
  assert(a and type(a.b) == 'function', 'native emitter with :b() is required')
  for _, byte in ipairs(bytes or {}) do a:b(byte) end
end

function M.emit_string(a, fonts, label, text, zero_terminated)
  assert(type(label) == 'string' and label ~= '', 'string label is required')
  assert(type(a.label) == 'function', 'native emitter with :label() is required')
  a:label(label)
  local bytes = M.encode_string(fonts, text, zero_terminated)
  emit_bytes(a, bytes)
  return #bytes
end

-- Emits one byte per visible glyph row.  Every row is left-aligned in bit 7 so
-- native code can use SLA/RL to consume pixels from left to right.  This is the
-- simplest and fastest form for modules with enough RAM.
function M.emit_row_font(a, fonts, face_name, label)
  fonts = require_fonts(fonts)
  assert(type(label) == 'string' and label ~= '', 'font label is required')
  assert(type(a.label) == 'function', 'native emitter with :label() is required')
  local face = fonts.face(face_name)
  local bytes = fonts.row_bytes(face_name)
  a:label(label)
  emit_bytes(a, bytes)
  return {
    face = face.id,
    label = label,
    bytes = #bytes,
    encoding = 'row-byte-left-aligned',
    glyph_count = face.glyph_count,
    rows_per_glyph = face.glyph_height,
  }
end

-- Emits the dense canonical bitstream.  This is intended for RAM-constrained
-- modules; a module-specific native decoder can trade a little Z80 code/time for
-- substantially smaller glyph storage.
function M.emit_packed_font(a, fonts, face_name, label)
  fonts = require_fonts(fonts)
  assert(type(label) == 'string' and label ~= '', 'font label is required')
  assert(type(a.label) == 'function', 'native emitter with :label() is required')
  local face = fonts.face(face_name)
  local bytes = fonts.packed_bytes(face_name)
  a:label(label)
  emit_bytes(a, bytes)
  return {
    face = face.id,
    label = label,
    bytes = #bytes,
    bits = face.packed_bits,
    encoding = 'glyph-row-msb-bitstream',
    glyph_count = face.glyph_count,
    glyph_width = face.glyph_width,
    glyph_height = face.glyph_height,
  }
end

-- Reference decoder for the dense format.  It is intentionally Lua-side only:
-- screen modules can use it in audits to prove that an emitted packed asset is
-- byte/bit identical to the canonical face before native handoff.
function M.unpack_packed_glyph(fonts, face_name, packed, glyph_index)
  fonts = require_fonts(fonts)
  local face = fonts.face(face_name)
  glyph_index = integer(glyph_index, 'glyph index', 0, face.glyph_count - 1)
  assert(type(packed) == 'table', 'packed font byte table is required')
  local bit_start = glyph_index * face.glyph_width * face.glyph_height
  local rows = {}
  for row = 0, face.glyph_height - 1 do
    local value = 0
    for column = 0, face.glyph_width - 1 do
      local bit_index = bit_start + row * face.glyph_width + column
      local byte_index = math.floor(bit_index / 8) + 1
      local bit_in_byte = 7 - (bit_index % 8)
      local byte = packed[byte_index] or 0
      value = (value << 1) | ((byte >> bit_in_byte) & 1)
    end
    rows[#rows + 1] = value
  end
  return rows
end

function M.audit_font(fonts, face_name)
  fonts = require_fonts(fonts)
  local face = fonts.face(face_name)
  local packed = fonts.packed_bytes(face_name)
  for glyph = 0, face.glyph_count - 1 do
    local decoded = M.unpack_packed_glyph(fonts, face_name, packed, glyph)
    local expected = face.rows[glyph + 1]
    assert(#decoded == #expected)
    for row = 1, #expected do
      assert(decoded[row] == expected[row],
        string.format('%s packed audit failed glyph=%d row=%d', face.id, glyph, row))
    end
  end
  local metrics = M.metrics(fonts, face_name)
  return {
    face = face.id,
    glyphs = face.glyph_count,
    row_table_bytes = face.row_table_bytes,
    packed_bytes = face.packed_bytes,
    columns = metrics.columns,
    rows = metrics.rows,
  }
end

function M.audit(fonts)
  return {
    M.audit_font(fonts, 'tiny'),
    M.audit_font(fonts, 'compact'),
  }
end

return M
