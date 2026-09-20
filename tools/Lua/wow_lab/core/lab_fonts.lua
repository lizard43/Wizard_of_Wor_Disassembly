-- core/lab_fonts.lua
-- Wizard of Wor Lab private UI fonts.
--
-- Install this file as core/lab_fonts.lua.  These glyphs are Lab-owned assets;
-- they do not replace or patch Wizard of Wor CHRTBL.  Modules may continue to
-- call resident WoW text routines whenever the original game renderer is the
-- behavior being studied.
--
-- Font storage is intentionally address-independent.  A module can request a
-- readable one-byte-per-row table or a dense bit-packed asset and place it in
-- whichever part of its disposable $D400-$DFFF application image is available.

local M = {}
M.VERSION = '1.0.1-20260820-0825'
M.ASCII_FIRST = 0x20
M.ASCII_LAST = 0x5F
M.FALLBACK_CODE = 0x3F -- '?'

M.symbol_code = {
  UP = 0x80,
  DOWN = 0x81,
  LEFT = 0x82,
  RIGHT = 0x83,
  SELECT = 0x84,
  BULLET = 0x85,
}

local GLYPHS_TINY = {
  [string.char(0x20)] = { "000", "000", "000", "000", "000" },
  [string.char(0x21)] = { "010", "010", "010", "000", "010" },
  [string.char(0x22)] = { "101", "101", "000", "000", "000" },
  [string.char(0x23)] = { "101", "111", "101", "111", "101" },
  [string.char(0x24)] = { "010", "111", "110", "011", "010" },
  [string.char(0x25)] = { "101", "001", "010", "100", "101" },
  [string.char(0x26)] = { "010", "101", "010", "101", "011" },
  [string.char(0x27)] = { "010", "010", "000", "000", "000" },
  [string.char(0x28)] = { "001", "010", "010", "010", "001" },
  [string.char(0x29)] = { "100", "010", "010", "010", "100" },
  [string.char(0x2A)] = { "101", "010", "111", "010", "101" },
  [string.char(0x2B)] = { "000", "010", "111", "010", "000" },
  [string.char(0x2C)] = { "000", "000", "000", "010", "100" },
  [string.char(0x2D)] = { "000", "000", "111", "000", "000" },
  [string.char(0x2E)] = { "000", "000", "000", "000", "010" },
  [string.char(0x2F)] = { "001", "001", "010", "100", "100" },
  [string.char(0x30)] = { "111", "101", "101", "101", "111" },
  [string.char(0x31)] = { "010", "110", "010", "010", "111" },
  [string.char(0x32)] = { "110", "001", "010", "100", "111" },
  [string.char(0x33)] = { "110", "001", "010", "001", "110" },
  [string.char(0x34)] = { "101", "101", "111", "001", "001" },
  [string.char(0x35)] = { "111", "100", "110", "001", "110" },
  [string.char(0x36)] = { "011", "100", "111", "101", "111" },
  [string.char(0x37)] = { "111", "001", "010", "010", "010" },
  [string.char(0x38)] = { "111", "101", "111", "101", "111" },
  [string.char(0x39)] = { "111", "101", "111", "001", "110" },
  [string.char(0x3A)] = { "000", "010", "000", "010", "000" },
  [string.char(0x3B)] = { "000", "010", "000", "010", "100" },
  [string.char(0x3C)] = { "001", "010", "100", "010", "001" },
  [string.char(0x3D)] = { "000", "111", "000", "111", "000" },
  [string.char(0x3E)] = { "100", "010", "001", "010", "100" },
  [string.char(0x3F)] = { "110", "001", "010", "000", "010" },
  [string.char(0x40)] = { "111", "101", "111", "100", "011" },
  [string.char(0x41)] = { "010", "101", "111", "101", "101" },
  [string.char(0x42)] = { "110", "101", "110", "101", "110" },
  [string.char(0x43)] = { "011", "100", "100", "100", "011" },
  [string.char(0x44)] = { "110", "101", "101", "101", "110" },
  [string.char(0x45)] = { "111", "100", "110", "100", "111" },
  [string.char(0x46)] = { "111", "100", "110", "100", "100" },
  [string.char(0x47)] = { "011", "100", "101", "101", "011" },
  [string.char(0x48)] = { "101", "101", "111", "101", "101" },
  [string.char(0x49)] = { "111", "010", "010", "010", "111" },
  [string.char(0x4A)] = { "001", "001", "001", "101", "010" },
  [string.char(0x4B)] = { "101", "101", "110", "101", "101" },
  [string.char(0x4C)] = { "100", "100", "100", "100", "111" },
  [string.char(0x4D)] = { "101", "111", "111", "101", "101" },
  [string.char(0x4E)] = { "101", "111", "111", "111", "101" },
  [string.char(0x4F)] = { "010", "101", "101", "101", "010" },
  [string.char(0x50)] = { "110", "101", "110", "100", "100" },
  [string.char(0x51)] = { "010", "101", "101", "111", "011" },
  [string.char(0x52)] = { "110", "101", "110", "101", "101" },
  [string.char(0x53)] = { "011", "100", "010", "001", "110" },
  [string.char(0x54)] = { "111", "010", "010", "010", "010" },
  [string.char(0x55)] = { "101", "101", "101", "101", "111" },
  [string.char(0x56)] = { "101", "101", "101", "101", "010" },
  [string.char(0x57)] = { "101", "101", "111", "111", "010" },
  [string.char(0x58)] = { "101", "101", "010", "101", "101" },
  [string.char(0x59)] = { "101", "101", "010", "010", "010" },
  [string.char(0x5A)] = { "111", "001", "010", "100", "111" },
  [string.char(0x5B)] = { "110", "100", "100", "100", "110" },
  [string.char(0x5C)] = { "100", "100", "010", "001", "001" },
  [string.char(0x5D)] = { "011", "001", "001", "001", "011" },
  [string.char(0x5E)] = { "010", "101", "000", "000", "000" },
  [string.char(0x5F)] = { "000", "000", "000", "000", "111" },
  [string.char(0x80)] = { "010", "111", "010", "010", "010" }, -- UP
  [string.char(0x81)] = { "010", "010", "010", "111", "010" }, -- DOWN
  [string.char(0x82)] = { "010", "100", "111", "100", "010" }, -- LEFT
  [string.char(0x83)] = { "010", "001", "111", "001", "010" }, -- RIGHT
  [string.char(0x84)] = { "010", "111", "111", "111", "010" }, -- SELECT
  [string.char(0x85)] = { "000", "000", "111", "111", "000" }, -- BULLET
}

local GLYPHS_COMPACT = {
  [string.char(0x20)] = { "00000", "00000", "00000", "00000", "00000", "00000", "00000" },
  [string.char(0x21)] = { "00100", "00100", "00100", "00100", "00100", "00000", "00100" },
  [string.char(0x22)] = { "01010", "01010", "01010", "00000", "00000", "00000", "00000" },
  [string.char(0x23)] = { "01010", "11111", "01010", "01010", "11111", "01010", "00000" },
  [string.char(0x24)] = { "00100", "01111", "10100", "01110", "00101", "11110", "00100" },
  [string.char(0x25)] = { "11001", "11010", "00100", "01000", "10110", "00110", "00000" },
  [string.char(0x26)] = { "01100", "10010", "10100", "01000", "10101", "10010", "01101" },
  [string.char(0x27)] = { "00100", "00100", "01000", "00000", "00000", "00000", "00000" },
  [string.char(0x28)] = { "00010", "00100", "01000", "01000", "01000", "00100", "00010" },
  [string.char(0x29)] = { "01000", "00100", "00010", "00010", "00010", "00100", "01000" },
  [string.char(0x2A)] = { "00000", "10101", "01110", "11111", "01110", "10101", "00000" },
  [string.char(0x2B)] = { "00000", "00100", "00100", "11111", "00100", "00100", "00000" },
  [string.char(0x2C)] = { "00000", "00000", "00000", "00000", "00110", "00100", "01000" },
  [string.char(0x2D)] = { "00000", "00000", "00000", "11111", "00000", "00000", "00000" },
  [string.char(0x2E)] = { "00000", "00000", "00000", "00000", "00000", "00110", "00110" },
  [string.char(0x2F)] = { "00001", "00010", "00100", "00100", "01000", "10000", "00000" },
  [string.char(0x30)] = { "01110", "10001", "10011", "10101", "11001", "10001", "01110" },
  [string.char(0x31)] = { "00100", "01100", "00100", "00100", "00100", "00100", "01110" },
  [string.char(0x32)] = { "01110", "10001", "00001", "00010", "00100", "01000", "11111" },
  [string.char(0x33)] = { "11110", "00001", "00001", "01110", "00001", "00001", "11110" },
  [string.char(0x34)] = { "00010", "00110", "01010", "10010", "11111", "00010", "00010" },
  [string.char(0x35)] = { "11111", "10000", "10000", "11110", "00001", "00001", "11110" },
  [string.char(0x36)] = { "01110", "10000", "10000", "11110", "10001", "10001", "01110" },
  [string.char(0x37)] = { "11111", "00001", "00010", "00100", "01000", "01000", "01000" },
  [string.char(0x38)] = { "01110", "10001", "10001", "01110", "10001", "10001", "01110" },
  [string.char(0x39)] = { "01110", "10001", "10001", "01111", "00001", "00001", "01110" },
  [string.char(0x3A)] = { "00000", "00110", "00110", "00000", "00110", "00110", "00000" },
  [string.char(0x3B)] = { "00000", "00110", "00110", "00000", "00110", "00100", "01000" },
  [string.char(0x3C)] = { "00010", "00100", "01000", "10000", "01000", "00100", "00010" },
  [string.char(0x3D)] = { "00000", "11111", "00000", "11111", "00000", "00000", "00000" },
  [string.char(0x3E)] = { "01000", "00100", "00010", "00001", "00010", "00100", "01000" },
  [string.char(0x3F)] = { "01110", "10001", "00001", "00010", "00100", "00000", "00100" },
  [string.char(0x40)] = { "01110", "10001", "10111", "10101", "10111", "10000", "01110" },
  [string.char(0x41)] = { "01110", "10001", "10001", "11111", "10001", "10001", "10001" },
  [string.char(0x42)] = { "11110", "10001", "10001", "11110", "10001", "10001", "11110" },
  [string.char(0x43)] = { "01111", "10000", "10000", "10000", "10000", "10000", "01111" },
  [string.char(0x44)] = { "11110", "10001", "10001", "10001", "10001", "10001", "11110" },
  [string.char(0x45)] = { "11111", "10000", "10000", "11110", "10000", "10000", "11111" },
  [string.char(0x46)] = { "11111", "10000", "10000", "11110", "10000", "10000", "10000" },
  [string.char(0x47)] = { "01111", "10000", "10000", "10111", "10001", "10001", "01111" },
  [string.char(0x48)] = { "10001", "10001", "10001", "11111", "10001", "10001", "10001" },
  [string.char(0x49)] = { "01110", "00100", "00100", "00100", "00100", "00100", "01110" },
  [string.char(0x4A)] = { "00111", "00010", "00010", "00010", "00010", "10010", "01100" },
  [string.char(0x4B)] = { "10001", "10010", "10100", "11000", "10100", "10010", "10001" },
  [string.char(0x4C)] = { "10000", "10000", "10000", "10000", "10000", "10000", "11111" },
  [string.char(0x4D)] = { "10001", "11011", "10101", "10101", "10001", "10001", "10001" },
  [string.char(0x4E)] = { "10001", "11001", "11001", "10101", "10011", "10011", "10001" },
  [string.char(0x4F)] = { "01110", "10001", "10001", "10001", "10001", "10001", "01110" },
  [string.char(0x50)] = { "11110", "10001", "10001", "11110", "10000", "10000", "10000" },
  [string.char(0x51)] = { "01110", "10001", "10001", "10001", "10101", "10010", "01101" },
  [string.char(0x52)] = { "11110", "10001", "10001", "11110", "10100", "10010", "10001" },
  [string.char(0x53)] = { "01111", "10000", "10000", "01110", "00001", "00001", "11110" },
  [string.char(0x54)] = { "11111", "00100", "00100", "00100", "00100", "00100", "00100" },
  [string.char(0x55)] = { "10001", "10001", "10001", "10001", "10001", "10001", "01110" },
  [string.char(0x56)] = { "10001", "10001", "10001", "10001", "10001", "01010", "00100" },
  [string.char(0x57)] = { "10001", "10001", "10001", "10101", "10101", "11011", "10001" },
  [string.char(0x58)] = { "10001", "10001", "01010", "00100", "01010", "10001", "10001" },
  [string.char(0x59)] = { "10001", "10001", "01010", "00100", "00100", "00100", "00100" },
  [string.char(0x5A)] = { "11111", "00001", "00010", "00100", "01000", "10000", "11111" },
  [string.char(0x5B)] = { "01110", "01000", "01000", "01000", "01000", "01000", "01110" },
  [string.char(0x5C)] = { "10000", "01000", "00100", "00100", "00010", "00001", "00000" },
  [string.char(0x5D)] = { "01110", "00010", "00010", "00010", "00010", "00010", "01110" },
  [string.char(0x5E)] = { "00100", "01010", "10001", "00000", "00000", "00000", "00000" },
  [string.char(0x5F)] = { "00000", "00000", "00000", "00000", "00000", "00000", "11111" },
  [string.char(0x80)] = { "00100", "01110", "10101", "00100", "00100", "00100", "00000" }, -- UP
  [string.char(0x81)] = { "00100", "00100", "00100", "10101", "01110", "00100", "00000" }, -- DOWN
  [string.char(0x82)] = { "00100", "01000", "11111", "01000", "00100", "00000", "00000" }, -- LEFT
  [string.char(0x83)] = { "00100", "00010", "11111", "00010", "00100", "00000", "00000" }, -- RIGHT
  [string.char(0x84)] = { "00100", "01110", "11111", "11111", "11111", "01110", "00100" }, -- SELECT
  [string.char(0x85)] = { "00000", "00000", "01110", "01110", "01110", "00000", "00000" }, -- BULLET
}

local FACE_DEFS = {
  tiny = {
    id = 'tiny',
    label = 'LAB TINY 3X5',
    glyph_width = 3,
    glyph_height = 5,
    cell_width = 4,
    cell_height = 6,
    glyphs = GLYPHS_TINY,
  },
  compact = {
    id = 'compact',
    label = 'LAB COMPACT 5X7',
    glyph_width = 5,
    glyph_height = 7,
    cell_width = 6,
    cell_height = 8,
    glyphs = GLYPHS_COMPACT,
  },
}

local ORDER = {}
for code = M.ASCII_FIRST, M.ASCII_LAST do ORDER[#ORDER + 1] = code end
for code = 0x80, 0x85 do ORDER[#ORDER + 1] = code end

local function copy_array(source)
  local out = {}
  for i, value in ipairs(source or {}) do out[i] = value end
  return out
end

local function row_value(bits, width)
  assert(type(bits) == 'string' and #bits == width,
    string.format('font row must be %d bits, got %s', width, tostring(bits)))
  local value = 0
  for i = 1, width do
    local ch = bits:sub(i, i)
    assert(ch == '0' or ch == '1', 'font rows may contain only 0 and 1')
    value = (value << 1) | (ch == '1' and 1 or 0)
  end
  return value
end

local function normalize_code(code)
  code = tonumber(code) or M.FALLBACK_CODE
  code = code & 0xFF
  if code >= 0x61 and code <= 0x7A then code = code - 0x20 end
  if (code >= M.ASCII_FIRST and code <= M.ASCII_LAST)
      or (code >= 0x80 and code <= 0x85) then
    return code
  end
  return M.FALLBACK_CODE
end

local function compile_face(def)
  local face = {}
  for key, value in pairs(def) do face[key] = value end
  face.order = copy_array(ORDER)
  face.rows = {}
  face.index_by_code = {}

  for index, code in ipairs(face.order) do
    local glyph = assert(face.glyphs[string.char(code)],
      string.format('%s missing glyph $%02X', face.label, code))
    assert(#glyph == face.glyph_height,
      string.format('%s glyph $%02X must have %d rows', face.label, code, face.glyph_height))
    local compiled = {}
    for row, bits in ipairs(glyph) do compiled[row] = row_value(bits, face.glyph_width) end
    face.rows[index] = compiled
    face.index_by_code[code] = index - 1 -- native-friendly zero-based index
  end

  face.glyph_count = #face.order
  face.row_table_bytes = face.glyph_count * face.glyph_height
  face.packed_bits = face.glyph_count * face.glyph_width * face.glyph_height
  face.packed_bytes = math.floor((face.packed_bits + 7) / 8)
  return face
end

local FACES = {
  tiny = compile_face(FACE_DEFS.tiny),
  compact = compile_face(FACE_DEFS.compact),
}

function M.normalize_code(value)
  if type(value) == 'string' then
    if value == '' then return M.FALLBACK_CODE end
    value = string.byte(value, 1)
  end
  return normalize_code(value)
end

function M.face(name)
  name = tostring(name or 'compact'):lower()
  local face = FACES[name]
  assert(face, 'unknown Lab font face: ' .. tostring(name))
  return face
end

function M.glyph(name, value)
  local face = M.face(name)
  local code = normalize_code(type(value) == 'string' and string.byte(value, 1) or value)
  local index = assert(face.index_by_code[code], string.format('no glyph index for $%02X', code))
  return copy_array(face.rows[index + 1]), code, index
end

-- Native row-table representation: one byte per glyph row, left-aligned so a
-- Z80 renderer can shift bit 7 first.  The inter-character/inter-line blank
-- column/row are cell metrics and are not stored in the glyph table.
function M.row_bytes(name)
  local face = M.face(name)
  local bytes = {}
  local shift = 8 - face.glyph_width
  for _, rows in ipairs(face.rows) do
    for _, value in ipairs(rows) do bytes[#bytes + 1] = (value << shift) & 0xFF end
  end
  return bytes
end

-- Dense representation used when a module is short on application RAM.  Bits
-- are concatenated glyph-major, row-major, left to right; the final byte is
-- zero-padded in its least-significant bits.  lab_text.unpack_packed_glyph()
-- provides the reference decoder used by tests and by native-emitter work.
function M.packed_bytes(name)
  local face = M.face(name)
  local bytes = {}
  local accumulator, bit_count = 0, 0
  for _, rows in ipairs(face.rows) do
    for _, value in ipairs(rows) do
      for bit = face.glyph_width - 1, 0, -1 do
        accumulator = (accumulator << 1) | ((value >> bit) & 1)
        bit_count = bit_count + 1
        if bit_count == 8 then
          bytes[#bytes + 1] = accumulator & 0xFF
          accumulator, bit_count = 0, 0
        end
      end
    end
  end
  if bit_count ~= 0 then bytes[#bytes + 1] = (accumulator << (8 - bit_count)) & 0xFF end
  assert(#bytes == face.packed_bytes,
    string.format('%s packed-size mismatch: %d != %d', face.label, #bytes, face.packed_bytes))
  return bytes
end

function M.encode(text)
  text = tostring(text or '')
  local bytes = {}
  for i = 1, #text do bytes[#bytes + 1] = normalize_code(text:byte(i)) end
  return bytes
end

function M.symbol(name)
  local code = assert(M.symbol_code[tostring(name or ''):upper()], 'unknown Lab font symbol')
  return string.char(code)
end

function M.preview(name, text, on, off)
  local face = M.face(name)
  local codes = M.encode(text)
  on, off = tostring(on or '#'), tostring(off or '.')
  local lines = {}
  for row = 1, face.glyph_height do
    local parts = {}
    for _, code in ipairs(codes) do
      local index = face.index_by_code[code]
      local value = face.rows[index + 1][row]
      local glyph = {}
      for bit = face.glyph_width - 1, 0, -1 do
        glyph[#glyph + 1] = ((value >> bit) & 1) ~= 0 and on or off
      end
      parts[#parts + 1] = table.concat(glyph) .. off
    end
    lines[#lines + 1] = table.concat(parts)
  end
  lines[#lines + 1] = string.rep(off, #codes * face.cell_width)
  return table.concat(lines, '\n')
end

function M.audit()
  local report = {}
  for _, name in ipairs({ 'tiny', 'compact' }) do
    local face = M.face(name)
    assert(face.cell_width > face.glyph_width, face.label .. ' requires a blank cell column')
    assert(face.cell_height > face.glyph_height, face.label .. ' requires a blank cell row')
    assert(face.glyph_count == 70, face.label .. ' glyph count must be 70')
    local rows = M.row_bytes(name)
    local packed = M.packed_bytes(name)
    assert(#rows == face.row_table_bytes)
    assert(#packed == face.packed_bytes)
    report[#report + 1] = {
      id = face.id,
      label = face.label,
      glyphs = face.glyph_count,
      glyph_width = face.glyph_width,
      glyph_height = face.glyph_height,
      cell_width = face.cell_width,
      cell_height = face.cell_height,
      row_table_bytes = #rows,
      packed_bytes = #packed,
    }
  end
  return report
end

M.faces = FACES
M.order = copy_array(ORDER)
M.audit()

return M
