-- modules/astrocade_info.lua
-- Astrocade Lab hardware / ROM information module.
--
-- The current host is Wizard of Wor Lab, but this module deliberately keeps
-- game-specific knowledge at the edges.  It reports observed Astrocade I/O
-- latches, mapped ROM bytes, audio state, and Lab/runtime data.
-- Native Z80 owns the visible screen and cabinet navigation.  Lua supplies the
-- display-list data and hardware/ROM interpretation.
--
-- Screen rendering is Lab-private: the compact font supplies the title bitmap
-- and the tiny font supplies dense 80-column text. No WoW CHRTBL or printstr
-- call is used. The PALETTE tab temporarily moves HORCB so both physical color
-- banks can be displayed together; the captured game value is restored on exit.

local M = {}
M.VERSION = '1.2.0-20260820-0925'

local C = {
  P2PORT               = 0x11,
  P1PORT               = 0x12,
  HORCB_PORT            = 0x09,

  VIDEO_START          = 0x4000,
  VISIBLE_VIDEO_END    = 0x7FBF,
  SCREEN_STRIDE_BYTES  = 80,

  NATIVE_CODE          = 0xD400,
  NATIVE_CODE_END      = 0xD7FF,
  FONT_TINY            = 0xD800,
  FONT_TINY_END        = 0xD95D, -- 350 bytes
  COLOR_LUT            = 0xD960,
  COLOR_LUT_END        = 0xD97B, -- 24 text masks + 4 solid-pixel bytes
  HEADER_BITMAP        = 0xD980,
  HEADER_BITMAP_END    = 0xDA27, -- 21 x 8 = 168 bytes
  PAGE_BUFFER          = 0xDA40,
  PAGE_BUFFER_END      = 0xDEFF,

  STATE_BASE           = 0xDF00,
  STATE_SELECTED_TAB   = 0xDF00,
  STATE_DIRECTION      = 0xDF01,
  STATE_LAST_DIRECTION = 0xDF02,
  STATE_EVENT_SEQUENCE = 0xDF03,
  STATE_EVENT_TYPE     = 0xDF04, -- 1 = tab changed
  STATE_PAGE_REQUEST   = 0xDF05,
  STATE_REDRAW_REQUEST = 0xDF06,
  STATE_REDRAW_SEQUENCE= 0xDF07,
  STATE_INPUT_P2       = 0xDF08,
  STATE_INPUT_P1       = 0xDF09,
  STATE_TEXT_COLOR     = 0xDF0A,
  STATE_END            = 0xDF0A,
  STACK_TOP            = 0xDFE0,

  INPUT_DIRECTION_MASK = 0x0F,
  INPUT_UP             = 0x01,
  INPUT_DOWN           = 0x02,
  INPUT_LEFT           = 0x04,
  INPUT_RIGHT          = 0x08,

  TAB_COUNT            = 6,
  PALETTE_TAB          = 2, -- zero-based

  HEADER_WIDTH_BYTES   = 21,
  HEADER_HEIGHT        = 8,
  HEADER_X_BYTE        = 29,
  HEADER_Y             = 1,
}

local TAB_NAMES = { 'SYSTEM', 'VIDEO', 'PALETTE', 'ROM', 'AUDIO', 'LAB' }
local TAB_X = { 2, 14, 24, 39, 50, 64 }

local KNOWN_ROM_CRC = {
  [0xC1295786] = 'WOW.X1',
  [0x9BE93215] = 'WOW.X2',
  [0x75E5A22E] = 'WOW.X3',
  [0xEF28EB84] = 'WOW.X4',
  [0x16912C2B] = 'WOW.X5',
  [0x35797F82] = 'WOW.X6',
  [0xCE404305] = 'WOW.X7',
  [0x16F84D73] = 'GERMAN.X11',
}

local ROM_WINDOWS = {
  { address=0x0000, label='$0000-$0FFF' },
  { address=0x1000, label='$1000-$1FFF' },
  { address=0x2000, label='$2000-$2FFF' },
  { address=0x3000, label='$3000-$3FFF' },
  { address=0x8000, label='$8000-$8FFF' },
  { address=0x9000, label='$9000-$9FFF' },
  { address=0xA000, label='$A000-$AFFF' },
  { address=0xB000, label='$B000-$BFFF' },
  { address=0xC000, label='$C000-$CFFF' },
}

local S = {
  active = false,
  lab = nil,
  program = nil,
  io_space = nil,
  probe = nil,
  takeover = nil,
  entry_snapshot = nil,
  machine_info = nil,
  roms = nil,
  code_labels = nil,
  last_event_sequence = 0,
  original_horcb = nil,
  palette_view_horcb = nil,
  shortcuts = {},
}

local function printf(fmt, ...)
  print(string.format('[ASTRO INFO] ' .. fmt, ...))
end

local function hex2(value)
  return string.format('$%02X', (tonumber(value) or 0) & 0xFF)
end

local function hex4(value)
  return string.format('$%04X', (tonumber(value) or 0) & 0xFFFF)
end

local function safe_property(object, name, fallback)
  local ok, value = pcall(function() return object and object[name] end)
  if ok and value ~= nil then return tostring(value) end
  return tostring(fallback or '?')
end

local function safe_call(fn, fallback)
  local ok, value = pcall(fn)
  if ok and value ~= nil then return tostring(value) end
  return tostring(fallback or '?')
end

local function compact_text(text, limit)
  text = tostring(text or '?'):upper():gsub('[\r\n\t]', ' ')
  text = text:gsub('%s+', ' ')
  if limit and #text > limit then text = text:sub(1, limit) end
  return text
end

local function assembler(origin)
  local a = { origin=origin, bytes={}, labels={}, fixups={} }
  function a:pc() return self.origin + #self.bytes end
  function a:b(value) self.bytes[#self.bytes + 1] = value & 0xFF end
  function a:w(value) self:b(value); self:b(value >> 8) end
  function a:label(name) self.labels[name] = self:pc() end
  function a:word(target)
    if type(target) == 'number' then self:w(target); return end
    local position = #self.bytes + 1
    self:w(0)
    self.fixups[#self.fixups + 1] = { kind='abs', position=position, target=target }
  end
  function a:abs(opcode, target) self:b(opcode); self:word(target) end
  function a:jr(opcode, target)
    self:b(opcode)
    local position = #self.bytes + 1
    self:b(0)
    self.fixups[#self.fixups + 1] = { kind='rel', position=position, target=target }
  end
  function a:finish()
    for _, fixup in ipairs(self.fixups) do
      local target = type(fixup.target) == 'number' and fixup.target or self.labels[fixup.target]
      assert(target, 'unresolved native label: ' .. tostring(fixup.target))
      if fixup.kind == 'abs' then
        self.bytes[fixup.position] = target & 0xFF
        self.bytes[fixup.position + 1] = (target >> 8) & 0xFF
      else
        local operand_address = self.origin + fixup.position - 1
        local displacement = target - (operand_address + 1)
        assert(displacement >= -128 and displacement <= 127,
          'JR target out of range: ' .. tostring(fixup.target))
        self.bytes[fixup.position] = displacement & 0xFF
      end
    end
    return self.bytes, self.labels
  end
  return a
end

local function emit_ld_mem_a(a, address) a:b(0x32); a:w(address) end
local function emit_ld_a_mem(a, address) a:b(0x3A); a:w(address) end
local function emit_call(a, target) a:abs(0xCD, target) end
local function emit_jp(a, target) a:abs(0xC3, target) end

local function build_controller(original_horcb, palette_view_horcb)
  local a = assembler(C.NATIVE_CODE)

  a:label('entry')
  a:b(0xF3)                                      -- DI
  a:b(0x31); a:w(C.STACK_TOP)                    -- LD SP,$DFE0

  -- Clear state only. Font assets and page data are installed by Lua.
  a:b(0xAF)
  a:b(0x21); a:w(C.STATE_BASE)
  a:b(0x11); a:w(C.STATE_BASE + 1)
  a:b(0x01); a:w(C.STATE_END - C.STATE_BASE)
  a:b(0x77); a:b(0xED); a:b(0xB0)               -- LD (HL),A / LDIR
  emit_call(a, 'apply_tab_horcb')
  emit_call(a, 'sample_inputs')
  emit_call(a, 'draw_screen')

  a:label('main')
  a:b(0xFB); a:b(0x76)                           -- EI / HALT
  emit_call(a, 'sample_inputs')
  emit_ld_a_mem(a, C.STATE_REDRAW_REQUEST); a:b(0xB7)
  a:jr(0x28, 'main_controls')
  a:b(0xAF); emit_ld_mem_a(a, C.STATE_REDRAW_REQUEST)
  emit_call(a, 'draw_screen')
  a:label('main_controls')
  emit_call(a, 'read_controls')
  emit_jp(a, 'main')

  a:label('sample_inputs')
  a:b(0xDB); a:b(C.P2PORT); emit_ld_mem_a(a, C.STATE_INPUT_P2)
  a:b(0xDB); a:b(C.P1PORT); emit_ld_mem_a(a, C.STATE_INPUT_P1)
  a:b(0xC9)

  -- Merge the active-low low-nibble directions from both player control ports.
  -- Navigation is edge-triggered so one physical joystick action changes one tab.
  a:label('read_controls')
  emit_ld_a_mem(a, C.STATE_INPUT_P2); a:b(0x2F); a:b(0xE6); a:b(C.INPUT_DIRECTION_MASK); a:b(0x47)
  emit_ld_a_mem(a, C.STATE_INPUT_P1); a:b(0x2F); a:b(0xE6); a:b(C.INPUT_DIRECTION_MASK); a:b(0xB0)
  a:b(0x47); emit_ld_mem_a(a, C.STATE_DIRECTION) -- B=current
  emit_ld_a_mem(a, C.STATE_LAST_DIRECTION); a:b(0xB8); a:b(0xC8) -- CP B / RET Z
  a:b(0x78); emit_ld_mem_a(a, C.STATE_LAST_DIRECTION); a:b(0xB7); a:b(0xC8) -- store / OR / RET Z

  a:b(0xFE); a:b(C.INPUT_LEFT); a:abs(0xCA, 'tab_previous')
  a:b(0xFE); a:b(C.INPUT_UP);   a:abs(0xCA, 'tab_previous')
  a:b(0xFE); a:b(C.INPUT_RIGHT);a:abs(0xCA, 'tab_next')
  a:b(0xFE); a:b(C.INPUT_DOWN); a:abs(0xCA, 'tab_next')
  a:b(0xC9)                                      -- non-cardinal state

  a:label('tab_previous')
  emit_ld_a_mem(a, C.STATE_SELECTED_TAB); a:b(0xB7)
  a:jr(0x20, 'tab_previous_dec')
  a:b(0x3E); a:b(C.TAB_COUNT)
  a:label('tab_previous_dec')
  a:b(0x3D); emit_jp(a, 'tab_commit')

  a:label('tab_next')
  emit_ld_a_mem(a, C.STATE_SELECTED_TAB); a:b(0x3C)
  a:b(0xFE); a:b(C.TAB_COUNT); a:jr(0x38, 'tab_commit')
  a:b(0xAF)

  a:label('tab_commit')
  emit_ld_mem_a(a, C.STATE_SELECTED_TAB)
  emit_call(a, 'apply_tab_horcb')
  emit_ld_a_mem(a, C.STATE_SELECTED_TAB)
  emit_ld_mem_a(a, C.STATE_PAGE_REQUEST)
  a:b(0x3E); a:b(0x01); emit_ld_mem_a(a, C.STATE_EVENT_TYPE)
  a:b(0x21); a:w(C.STATE_EVENT_SEQUENCE); a:b(0x34)
  a:b(0xC9)

  -- Palette view temporarily moves HORCB on the PALETTE tab so the physical
  -- left and right color-register banks are visible at the same time. Other
  -- tabs retain the captured game boundary.
  a:label('apply_tab_horcb')
  if original_horcb ~= nil and palette_view_horcb ~= nil then
    emit_ld_a_mem(a, C.STATE_SELECTED_TAB)
    a:b(0xFE); a:b(C.PALETTE_TAB)
    a:jr(0x28, 'apply_palette_horcb')
    a:b(0x3E); a:b(original_horcb & 0xFF)
    a:b(0xD3); a:b(C.HORCB_PORT)
    a:b(0xC9)
    a:label('apply_palette_horcb')
    a:b(0x3E); a:b(palette_view_horcb & 0xFF)
    a:b(0xD3); a:b(C.HORCB_PORT)
  end
  a:b(0xC9)

  -- Clear only the visible 320x204 bitmap. The Lab stack margin remains intact.
  a:label('draw_screen')
  a:b(0xF3)                                      -- DI
  a:b(0xAF)
  a:b(0x21); a:w(C.VIDEO_START)
  a:b(0x11); a:w(C.VIDEO_START + 1)
  a:b(0x01); a:w(C.VISIBLE_VIDEO_END - C.VIDEO_START)
  a:b(0x77); a:b(0xED); a:b(0xB0)
  emit_call(a, 'draw_header')
  emit_call(a, 'draw_page_buffer')
  a:b(0x21); a:w(C.STATE_REDRAW_SEQUENCE); a:b(0x34)
  a:b(0xFB); a:b(0xC9)                           -- EI / RET

  -- Copy the compact-font title bitmap. It is generated by Lua from LabFonts,
  -- not from WoW CHRTBL, and it writes packed pixels directly to VRAM.
  a:label('draw_header')
  a:b(0x21); a:w(C.HEADER_BITMAP)
  a:b(0x11); a:w(C.VIDEO_START + C.HEADER_Y * C.SCREEN_STRIDE_BYTES + C.HEADER_X_BYTE)
  a:b(0x3E); a:b(C.HEADER_HEIGHT)                 -- A=row count
  a:label('header_row')
  a:b(0xF5)                                      -- PUSH AF
  a:b(0x01); a:w(C.HEADER_WIDTH_BYTES)
  a:b(0xED); a:b(0xB0)                           -- LDIR
  a:b(0xE5)                                      -- PUSH HL source
  a:b(0x21); a:w(C.SCREEN_STRIDE_BYTES - C.HEADER_WIDTH_BYTES)
  a:b(0x19); a:b(0xEB)                           -- ADD HL,DE / EX DE,HL
  a:b(0xE1); a:b(0xF1)                           -- POP HL / POP AF
  a:b(0x3D); a:jr(0x20, 'header_row')
  a:b(0xC9)

  -- Page buffer records:
  --   text   destination word, logical color 1..3, zero-terminated tiny string
  --   swatch destination word, $80|logical pixel 0..3
  -- A zero destination word terminates the display list.
  a:label('draw_page_buffer')
  a:b(0x21); a:w(C.PAGE_BUFFER)
  a:label('page_record')
  a:b(0x5E); a:b(0x23); a:b(0x56); a:b(0x23)    -- LD E,(HL)/INC/LD D,(HL)/INC
  a:b(0x7A); a:b(0xB3); a:b(0xC8)               -- LD A,D / OR E / RET Z
  a:b(0x4E); a:b(0x23)                           -- LD C,(HL) / INC HL
  a:b(0xCB); a:b(0x79)                           -- BIT 7,C: swatch record?
  a:jr(0x20, 'page_swatch')
  emit_call(a, 'draw_tiny_string')
  a:jr(0x18, 'page_record')

  a:label('page_swatch')
  a:b(0x79); a:b(0xE6); a:b(0x03)               -- A = logical pixel 0..3
  a:b(0x4F); a:b(0x06); a:b(0x00)               -- BC = LUT index
  a:b(0xE5)                                      -- preserve page-buffer HL
  a:b(0x21); a:w(C.COLOR_LUT + 24); a:b(0x09)
  a:b(0x7E)                                      -- A = packed 4-pixel solid byte
  emit_call(a, 'draw_swatch')
  a:b(0xE1)                                      -- restore page-buffer HL
  a:jr(0x18, 'page_record')

  -- A=packed solid pixel byte, DE=VRAM destination. Draw a 6-byte x 8-line
  -- hardware swatch. Palette-bank selection is controlled separately by HORCB.
  a:label('draw_swatch')
  a:b(0x06); a:b(0x08)                           -- B=8 rows
  a:label('swatch_row')
  a:b(0x0E); a:b(0x06)                           -- C=6 bytes
  a:label('swatch_byte')
  a:b(0x12); a:b(0x13)                           -- LD (DE),A / INC DE
  a:b(0x0D); a:jr(0x20, 'swatch_byte')           -- DEC C / JR NZ
  a:b(0xC5)                                      -- preserve row counter
  a:b(0xEB); a:b(0x01); a:w(C.SCREEN_STRIDE_BYTES - 6); a:b(0x09); a:b(0xEB)
  a:b(0xC1); a:jr(0x10, 'swatch_row')            -- POP BC / DJNZ
  a:b(0xC9)

  -- HL=string, DE=VRAM destination, C=logical pixel color 1..3.
  -- Return HL at the first byte after the string terminator.  Tiny's 4x6 cell is
  -- exactly one packed Astrocade video byte wide, so each character advances DE
  -- by one byte and each glyph row advances by the 80-byte scanline stride.
  a:label('draw_tiny_string')
  a:b(0x79); emit_ld_mem_a(a, C.STATE_TEXT_COLOR) -- LD A,C
  a:b(0xDD); a:b(0xE5)                           -- PUSH IX
  a:b(0xE5); a:b(0xDD); a:b(0xE1)               -- PUSH HL / POP IX
  a:label('tiny_char')
  a:b(0xDD); a:b(0x7E); a:b(0x00)               -- LD A,(IX+0)
  a:b(0xDD); a:b(0x23)                           -- INC IX
  a:b(0xB7); a:jr(0x28, 'tiny_done')             -- OR A
  a:b(0xD6); a:b(0x20)                           -- SUB ' '
  a:b(0xFE); a:b(0x40); a:jr(0x38, 'tiny_index_ok')
  a:b(0x3E); a:b(0x1F)                           -- fallback '?' index
  a:label('tiny_index_ok')
  a:b(0x4F); a:b(0x06); a:b(0x00)               -- LD C,A / LD B,0
  a:b(0x69); a:b(0x60)                           -- LD L,C / LD H,B
  a:b(0x29); a:b(0x29); a:b(0x09)               -- index * 5
  a:b(0x01); a:w(C.FONT_TINY); a:b(0x09)         -- + font base
  a:b(0xD5)                                      -- PUSH DE char destination
  a:b(0x06); a:b(0x05)                           -- B=5 glyph rows
  a:label('tiny_row')
  a:b(0x7E); a:b(0x23)                           -- LD A,(HL) / INC HL
  for _ = 1, 5 do a:b(0x0F) end                  -- RRCA x5 -> 3-bit row mask
  a:b(0xE6); a:b(0x07); a:b(0x4F)               -- AND 7 / LD C,A
  a:b(0xE5); a:b(0xC5)                           -- PUSH HL / PUSH BC
  emit_ld_a_mem(a, C.STATE_TEXT_COLOR)
  a:b(0x3D); a:b(0x87); a:b(0x87); a:b(0x87)    -- (color-1)*8
  a:b(0x81)                                      -- ADD A,C
  a:b(0x4F); a:b(0x06); a:b(0x00)               -- BC=LUT index
  a:b(0x21); a:w(C.COLOR_LUT); a:b(0x09)
  a:b(0x7E)                                      -- LD A,(HL)
  a:b(0xC1); a:b(0xE1)                           -- POP BC / POP HL glyph
  a:b(0x12)                                      -- LD (DE),A
  a:b(0xE5); a:b(0xC5)                           -- preserve glyph / row counter
  a:b(0x21); a:w(C.SCREEN_STRIDE_BYTES); a:b(0x19); a:b(0xEB)
  a:b(0xC1); a:b(0xE1)                           -- restore BC / glyph
  a:jr(0x10, 'tiny_row')                         -- DJNZ
  a:b(0xD1); a:b(0x13)                           -- POP DE / INC DE
  a:jr(0x18, 'tiny_char')
  a:label('tiny_done')
  a:b(0xDD); a:b(0xE5); a:b(0xE1)               -- PUSH IX / POP HL
  a:b(0xDD); a:b(0xE1); a:b(0xC9)               -- POP IX / RET

  local bytes, labels = a:finish()
  assert(C.NATIVE_CODE + #bytes - 1 <= C.NATIVE_CODE_END,
    string.format('Astrocade info controller exceeds reserved range: %d bytes', #bytes))
  return bytes, labels
end

local function color_lut_bytes()
  local bytes = {}
  for color = 1, 3 do
    for mask = 0, 7 do
      local value = 0
      if (mask & 0x04) ~= 0 then value = value | (color << 6) end
      if (mask & 0x02) ~= 0 then value = value | (color << 4) end
      if (mask & 0x01) ~= 0 then value = value | (color << 2) end
      bytes[#bytes + 1] = value & 0xFF
    end
  end
  -- Solid packed bytes for logical pixel values 0,1,2,3.
  bytes[#bytes + 1] = 0x00
  bytes[#bytes + 1] = 0x55
  bytes[#bytes + 1] = 0xAA
  bytes[#bytes + 1] = 0xFF
  assert(#bytes == 28)
  return bytes
end

local function compact_header_bitmap(fonts, text, color)
  local face = fonts.face('compact')
  local codes = fonts.encode(text)
  local width_pixels = #codes * face.cell_width
  assert(width_pixels == C.HEADER_WIDTH_BYTES * 4,
    string.format('header must be %d pixels, got %d', C.HEADER_WIDTH_BYTES * 4, width_pixels))
  local bytes = {}
  for row = 1, face.cell_height do
    local pixels = {}
    for _, code in ipairs(codes) do
      local glyph = fonts.glyph('compact', code)
      local bits = row <= face.glyph_height and glyph[row] or 0
      for bit = face.glyph_width - 1, 0, -1 do
        pixels[#pixels + 1] = ((bits >> bit) & 1) ~= 0 and color or 0
      end
      pixels[#pixels + 1] = 0
    end
    for x = 1, #pixels, 4 do
      bytes[#bytes + 1] = ((pixels[x] or 0) << 6)
        | ((pixels[x + 1] or 0) << 4)
        | ((pixels[x + 2] or 0) << 2)
        | (pixels[x + 3] or 0)
    end
  end
  assert(#bytes == C.HEADER_WIDTH_BYTES * C.HEADER_HEIGHT)
  return bytes
end

local function read_direct(program, address)
  if program.read_direct_u8 then
    local ok, value = pcall(function() return program:read_direct_u8(address) end)
    if ok and value ~= nil then return value & 0xFF end
  end
  return program:read_u8(address) & 0xFF
end

local function crc32_window(program, address, length)
  local crc = 0xFFFFFFFF
  local all_ff, all_zero = true, true
  for offset = 0, length - 1 do
    local byte = read_direct(program, address + offset)
    if byte ~= 0xFF then all_ff = false end
    if byte ~= 0x00 then all_zero = false end
    crc = (crc ~ byte) & 0xFFFFFFFF
    for _ = 1, 8 do
      if (crc & 1) ~= 0 then
        crc = ((crc >> 1) ~ 0xEDB88320) & 0xFFFFFFFF
      else
        crc = (crc >> 1) & 0xFFFFFFFF
      end
    end
  end
  return (~crc) & 0xFFFFFFFF, all_ff, all_zero
end

local function scan_roms(program)
  local rows = {}
  for _, window in ipairs(ROM_WINDOWS) do
    local crc, all_ff, all_zero = crc32_window(program, window.address, 0x1000)
    local identity = KNOWN_ROM_CRC[crc]
    if all_ff then identity = 'EMPTY/FF'
    elseif all_zero then identity = 'EMPTY/00'
    elseif not identity then identity = 'UNIDENTIFIED' end
    rows[#rows + 1] = {
      address = window.address,
      label = window.label,
      crc = crc,
      identity = identity,
    }
  end
  return rows
end

local function machine_info(lab)
  local system = lab.machine and lab.machine.system
  local cpu = lab.native and lab.native.cpu
  return {
    name = compact_text(safe_property(system, 'name', '?'), 24),
    description = compact_text(safe_property(system, 'description', '?'), 50),
    year = compact_text(safe_property(system, 'year', '?'), 12),
    manufacturer = compact_text(safe_property(system, 'manufacturer', '?'), 32),
    cpu = compact_text(safe_property(cpu, 'shortname', safe_property(cpu, 'name', 'Z80')), 24),
    mame = compact_text(safe_call(function() return emu.app_version() end, '?'), 24),
  }
end

local function write_value(snapshot, port)
  local entry = snapshot and snapshot.writes and snapshot.writes[port]
  return entry and entry.value or nil, entry and entry.count or 0
end

local function read_value(snapshot, port)
  local entry = snapshot and snapshot.reads and snapshot.reads[port]
  return entry and entry.value or nil, entry and entry.count or 0
end

local function value_text(value)
  return value == nil and '--' or string.format('%02X', value & 0xFF)
end

local function add_line(lines, row, text, color, col)
  lines[#lines + 1] = {
    kind='text', row=row, col=col or 1,
    text=compact_text(text, 78 - (col or 1)), color=color,
  }
end

local function add_swatch(lines, row, col, pixel)
  lines[#lines + 1] = { kind='swatch', row=row, col=col, pixel=(tonumber(pixel) or 0) & 3 }
end

local function version_tag(version)
  local major, minor, patch = tostring(version or ''):match('^(%d+)%.(%d+)%.(%d+)')
  return major and ('V' .. major .. minor .. patch) or 'VER'
end

local function add_chrome(lines, selected, colors)
  add_line(lines, 2, version_tag(M.VERSION), colors.YELLOW, 74)
  for index, name in ipairs(TAB_NAMES) do
    add_line(lines, 12, name, (index - 1) == selected and colors.YELLOW or colors.BLUE, TAB_X[index])
  end
  add_line(lines, 194, 'JOYSTICK: TAB    1P: RETURN', colors.YELLOW, 2)
end

local function wow_program_loaded()
  local expected = { 'WOW.X1','WOW.X2','WOW.X3','WOW.X4','WOW.X5','WOW.X6','WOW.X7' }
  if not S.roms or #S.roms < #expected then return false end
  for i, name in ipairs(expected) do
    if S.roms[i].identity ~= name then return false end
  end
  return true
end

local function wow_hardware_profile()
  local name = tostring(S.machine_info and S.machine_info.name or ''):upper()
  return name:match('^WOW') ~= nil
end

local function rom_bytes_text(address, count)
  local parts = {}
  for offset = 0, count - 1 do parts[#parts + 1] = string.format('%02X', read_direct(S.program, address + offset)) end
  return table.concat(parts, ' ')
end

local function joy_text(raw)
  raw = (tonumber(raw) or 0xFF) & 0xFF
  local names = {}
  for _, item in ipairs({ {0x01,'UP'}, {0x02,'DOWN'}, {0x04,'LEFT'}, {0x08,'RIGHT'} }) do
    if (raw & item[1]) == 0 then names[#names + 1] = item[2] end
  end
  return #names == 0 and 'CENTER' or table.concat(names, '+')
end

local function bit_low(raw, mask)
  return (((tonumber(raw) or 0xFF) & mask) == 0) and 1 or 0
end

local function bit_high(raw, mask)
  return (((tonumber(raw) or 0) & mask) ~= 0) and 1 or 0
end

local function wow_player_bits(raw, with_speech)
  local text = string.format('U=%d D=%d L=%d R=%d B2=%d B1=%d',
    bit_low(raw, 0x01), bit_low(raw, 0x02), bit_low(raw, 0x04), bit_low(raw, 0x08),
    bit_high(raw, 0x10), bit_low(raw, 0x20))
  if with_speech then text = text .. string.format(' AR=%d', bit_high(raw, 0x80)) end
  return text
end

local function wow_system_bits(raw)
  return string.format('C1=%d C2=%d C3=%d SVC=%d TILT=%d 1P=%d 2P=%d FLIP=%s',
    bit_low(raw, 0x01), bit_low(raw, 0x02), bit_low(raw, 0x04), bit_low(raw, 0x08),
    bit_low(raw, 0x10), bit_low(raw, 0x20), bit_low(raw, 0x40),
    ((raw & 0x80) ~= 0) and 'OFF' or 'ON')
end

local function wow_coin_b(raw)
  local values = { [0x04]='2C1C', [0x06]='1C1C', [0x02]='1C3C', [0x00]='1C5C' }
  return values[raw & 0x06] or '--'
end

local function wow_dip_lines(raw)
  local coin_a = (raw & 0x01) ~= 0 and '1C1C' or '2C1C'
  local language = (raw & 0x08) ~= 0 and 'EN' or 'FOREIGN'
  local lives = (raw & 0x10) ~= 0 and '2/5' or '3/7'
  local bonus = (raw & 0x20) ~= 0 and 'L3' or 'L4'
  local free = (raw & 0x40) ~= 0 and 'OFF' or 'ON'
  local demo = (raw & 0x80) ~= 0 and 'ALWAYS' or 'TOUCH'
  return string.format('COIN A=%s B=%s  LANG=%s', coin_a, wow_coin_b(raw), language),
    string.format('LIVES=%s  BONUS=%s  FREE=%s  DEMO=%s', lives, bonus, free, demo)
end

local function video_split(snapshot)
  local mode = select(1, write_value(snapshot, 0x08))
  local hor = select(1, write_value(snapshot, 0x09))
  if not hor then return mode, nil, nil, nil, nil end
  local split = hor & 0x3F
  local byte_boundary = ((mode or 1) & 1) ~= 0 and split * 2 or split
  local left = math.max(0, math.min(C.SCREEN_STRIDE_BYTES, byte_boundary))
  return mode, hor, split, byte_boundary, left
end

local function rom_population()
  local populated = 0
  for _, row in ipairs(S.roms or {}) do
    if row.identity ~= 'EMPTY/FF' and row.identity ~= 'EMPTY/00' then populated = populated + 1 end
  end
  return populated
end

local function palette_match_wow(regs)
  if not wow_program_loaded() then return nil end
  for i = 0, 7 do
    if regs[7 - i] ~= read_direct(S.program, 0x00C5 + i) then return false end
  end
  return true
end

local function sound_registers(snapshot, base)
  local out = {}
  for offset = 0, 7 do out[offset + 1] = select(1, write_value(snapshot, base + offset)) end
  return out
end

local function register_bytes_text(values)
  local parts = {}
  for i = 1, 8 do parts[#parts + 1] = value_text(values[i]) end
  return table.concat(parts, ' ')
end

local function page_system(selected)
  local colors = S.lab.text.colors
  local lines = {}; add_chrome(lines, selected, colors)
  add_line(lines, 26, 'SYSTEM', colors.YELLOW)
  add_line(lines, 38, string.format('MACHINE  %s  %s', S.machine_info.name, S.machine_info.description), colors.BLUE)
  add_line(lines, 44, string.format('MAME %s   CPU %s', S.machine_info.mame, S.machine_info.cpu), colors.BLUE)
  add_line(lines, 50, string.format('%s   %s', S.machine_info.year, S.machine_info.manufacturer), colors.BLUE)

  local wow_hw = wow_hardware_profile()
  add_line(lines, 62, wow_hw and 'CPU MEMORY MAP - WOW' or 'CPU MEMORY MAP', colors.YELLOW)
  add_line(lines, 74, '$0000-$3FFF  LOW ROM READ / MAGIC WRITE WINDOW', colors.BLUE)
  add_line(lines, 80, '$4000-$7FFF  VIDEO RAM', colors.BLUE)
  if wow_hw then
    add_line(lines, 86, '$8000-$AFFF  HIGH ROM', colors.BLUE)
    add_line(lines, 92, '$B000-$BFFF  UNMAPPED   $C000-$CFFF  OPTIONAL X11 ROM', colors.BLUE)
    add_line(lines, 98, '$D000-$D03F  PROTECTED RAM   $D040-$DFFF  WORK RAM', colors.BLUE)
  else
    add_line(lines, 86, '$8000-$DFFF  GAME / BOARD-SPECIFIC MAP', colors.BLUE)
  end

  local mode, hor, split, byte_boundary, left = video_split(S.takeover)
  local ver = select(1, write_value(S.takeover, 0x0A))
  add_line(lines, 112, string.format('ROM WINDOWS POPULATED=%d/9  PROFILE=%s', rom_population(),
    wow_hw and 'WOW HW' or 'GENERIC'), colors.BLUE)
  if mode ~= nil then
    local resolution = (mode & 1) ~= 0 and '320X204' or '160X102'
    add_line(lines, 124, string.format('VIDEO $08=%02X  %s  %s', mode,
      (mode & 1) ~= 0 and 'COMMERCIAL' or 'CONSUMER', resolution), colors.BLUE)
  else
    add_line(lines, 124, 'VIDEO $08=--', colors.RED)
  end
  if hor and ver then
    add_line(lines, 130, string.format('HORCB=$%02X SPLIT=%d BYTE=%d   VERBL=$%02X LINE=%d',
      hor, split, byte_boundary, ver, ver), colors.BLUE)
  end
  return lines
end

local function page_video(selected)
  local colors = S.lab.text.colors
  local lines = {}; add_chrome(lines, selected, colors)
  add_line(lines, 26, 'VIDEO', colors.YELLOW)
  local mode, hor, split, byte_boundary = video_split(S.takeover)
  local ver = select(1, write_value(S.takeover, 0x0A))
  local magic, magic_count = write_value(S.takeover, 0x0C)
  local vec = select(1, write_value(S.takeover, 0x0D))
  local intm = select(1, write_value(S.takeover, 0x0E))
  local scan = select(1, write_value(S.takeover, 0x0F))
  local xpand, xpand_count = write_value(S.takeover, 0x19)

  add_line(lines, 38, string.format('$08 CONCM=%s  %s', value_text(mode),
    mode and ((mode & 1) ~= 0 and 'COMMERCIAL 320X204' or 'CONSUMER 160X102') or ''),
    mode ~= nil and colors.BLUE or colors.RED)
  if hor then
    add_line(lines, 44, string.format('$09 HORCB=%02X  SPLIT=%d  BYTE=%d  BG=P%d',
      hor, split, byte_boundary, (hor >> 6) & 3), colors.BLUE)
  else
    add_line(lines, 44, '$09 HORCB=--', colors.RED)
  end
  add_line(lines, 50, string.format('$0A VERBL=%s  LINE=%s', value_text(ver), ver and tostring(ver) or '--'),
    ver ~= nil and colors.BLUE or colors.RED)
  add_line(lines, 56, string.format('IRQ  VECTOR=$%s  MODE=$%s  SCANLINE=$%s',
    value_text(vec), value_text(intm), value_text(scan)), colors.BLUE)

  add_line(lines, 70, 'MAGIC / XPAND - LAST WRITE', colors.YELLOW)
  if magic then
    add_line(lines, 82, string.format('$0C MAGIC=%02X N=%d  SHIFT=%d ROT=%d EXP=%d OR=%d XOR=%d FLOP=%d B7=%d',
      magic, magic_count, magic & 3, (magic >> 2) & 1, (magic >> 3) & 1,
      (magic >> 4) & 1, (magic >> 5) & 1, (magic >> 6) & 1, (magic >> 7) & 1), colors.BLUE)
  else
    add_line(lines, 82, '$0C MAGIC=--', colors.RED)
  end
  if xpand then
    add_line(lines, 88, string.format('$19 XPAND=%02X N=%d  ZERO=P%d  ONE=P%d',
      xpand, xpand_count, xpand & 3, (xpand >> 2) & 3), colors.BLUE)
  else
    add_line(lines, 88, '$19 XPAND=--', colors.RED)
  end

  add_line(lines, 102, 'PATTERN BOARD - LAST WRITE', colors.YELLOW)
  local pb = {}
  for port = 0x78, 0x7E do pb[port] = select(1, write_value(S.takeover, port)) end
  add_line(lines, 114, string.format('SRC $78=%s $79=%s   MODE $7A=%s',
    value_text(pb[0x78]), value_text(pb[0x79]), value_text(pb[0x7A])), colors.BLUE)
  add_line(lines, 120, string.format('DST $7B=%s $7C=%s   WIDTH $7D=%s   HEIGHT $7E=%s',
    value_text(pb[0x7B]), value_text(pb[0x7C]), value_text(pb[0x7D]), value_text(pb[0x7E])), colors.BLUE)
  return lines
end

local function page_palette(selected)
  local colors = S.lab.text.colors
  local lines = {}; add_chrome(lines, selected, colors)
  add_line(lines, 26, 'PALETTE', colors.YELLOW)

  local regs = {}
  for reg = 0, 7 do regs[reg] = select(1, write_value(S.takeover, reg)) end
  local _, colbx_count = write_value(S.takeover, 0x0B)

  if wow_program_loaded() then
    local match = palette_match_wow(regs)
    add_line(lines, 38, 'DEFPALETTE ROM  ' .. rom_bytes_text(0x00C5, 8), colors.BLUE)
    add_line(lines, 44, 'LATCH REG 7..0  ' .. string.format('%s %s %s %s %s %s %s %s',
      value_text(regs[7]), value_text(regs[6]), value_text(regs[5]), value_text(regs[4]),
      value_text(regs[3]), value_text(regs[2]), value_text(regs[1]), value_text(regs[0])), colors.BLUE)
    add_line(lines, 50, string.format('MATCH=%s   COLBX $0B WRITES=%d', match and 'YES' or 'NO', colbx_count),
      match and colors.YELLOW or colors.RED)
  else
    add_line(lines, 38, 'LATCH REG 7..0  ' .. string.format('%s %s %s %s %s %s %s %s',
      value_text(regs[7]), value_text(regs[6]), value_text(regs[5]), value_text(regs[4]),
      value_text(regs[3]), value_text(regs[2]), value_text(regs[1]), value_text(regs[0])), colors.BLUE)
    add_line(lines, 44, string.format('COLBX $0B WRITES=%d', colbx_count), colors.BLUE)
  end

  add_line(lines, 64, 'LEFT  REG 4 5 6 7', colors.YELLOW, 2)
  add_line(lines, 64, 'RIGHT REG 0 1 2 3', colors.YELLOW, 53)
  add_line(lines, 72, string.format('      %s %s %s %s',
    value_text(regs[4]), value_text(regs[5]), value_text(regs[6]), value_text(regs[7])), colors.BLUE, 2)
  add_line(lines, 72, string.format('      %s %s %s %s',
    value_text(regs[0]), value_text(regs[1]), value_text(regs[2]), value_text(regs[3])), colors.BLUE, 53)

  local left_cols = {2, 11, 20, 29}
  local right_cols = {52, 59, 66, 73}
  for p = 0, 3 do
    add_line(lines, 82, 'P' .. tostring(p), colors.BLUE, left_cols[p + 1] + 1)
    add_swatch(lines, 90, left_cols[p + 1], p)
    add_line(lines, 82, 'P' .. tostring(p), colors.BLUE, right_cols[p + 1] + 1)
    add_swatch(lines, 90, right_cols[p + 1], p)
  end

  local _, hor, split, byte_boundary = video_split(S.takeover)
  if hor then
    add_line(lines, 112, string.format('CAPTURE $09=%02X  SPLIT=%d  BYTE=%d  BG=P%d',
      hor, split, byte_boundary, (hor >> 6) & 3), colors.BLUE)
    local view_split = (S.palette_view_horcb or 0) & 0x3F
    local mode = select(1, write_value(S.takeover, 0x08)) or 1
    local view_byte = (mode & 1) ~= 0 and view_split * 2 or view_split
    add_line(lines, 118, string.format('PALETTE VIEW $09=%02X  SPLIT=%d  BYTE=%d',
      S.palette_view_horcb or hor, view_split, view_byte), colors.BLUE)
  end
  if wow_hardware_profile() then
    add_line(lines, 132, 'WOW/GORF STAR CIRCUIT: P0 DISPLAYS BLACK', colors.YELLOW)
  end
  return lines
end

local function page_rom(selected)
  local colors = S.lab.text.colors
  local lines = {}; add_chrome(lines, selected, colors)
  add_line(lines, 26, 'ROM / CRC32', colors.YELLOW)
  add_line(lines, 38, 'CPU WINDOW       CRC32      ID', colors.BLUE)
  local known = 0
  for index, row in ipairs(S.roms or {}) do
    if row.identity:match('^WOW%.X[1-7]$') then known = known + 1 end
    add_line(lines, 50 + (index - 1) * 12,
      string.format('%s  %08X  %s', row.label, row.crc, row.identity), colors.BLUE)
  end
  add_line(lines, 164, string.format('POPULATED=%d/9   WOW PROGRAM=%d/7%s', rom_population(), known,
    known == 7 and ' CANONICAL' or ''), known == 7 and colors.YELLOW or colors.BLUE)
  return lines
end

local function sound_detail(values, prefix)
  local v15, v16, v17 = values[6], values[7], values[8]
  if v15 == nil or v16 == nil or v17 == nil then
    return prefix .. ' VOL A=-- B=-- C=-- MOD=-- NOISE=--'
  end
  return string.format('%s VOL A=%d B=%d C=%d MOD=%s NOISE EN=%d LVL=%d MASK=%02X', prefix,
    v16 & 0x0F, (v16 >> 4) & 0x0F, v15 & 0x0F,
    (v15 & 0x10) ~= 0 and 'NOISE' or 'VIB', (v15 >> 5) & 1,
    (v17 >> 4) & 0x0F, v17)
end

local function page_audio(selected)
  local colors = S.lab.text.colors
  local lines = {}; add_chrome(lines, selected, colors)
  add_line(lines, 26, 'AUDIO', colors.YELLOW)
  local p = sound_registers(S.entry_snapshot, 0x10)
  local q = sound_registers(S.entry_snapshot, 0x50)
  add_line(lines, 38, 'PRIMARY $10-$17   ' .. register_bytes_text(p), colors.BLUE)
  add_line(lines, 50, string.format('P MASTER=%s  TONE A=%s B=%s C=%s  VIB=%s',
    value_text(p[1]), value_text(p[2]), value_text(p[3]), value_text(p[4]), value_text(p[5])), colors.BLUE)
  add_line(lines, 56, sound_detail(p, 'P'), colors.BLUE)

  add_line(lines, 74, 'SECONDARY $50-$57 ' .. register_bytes_text(q), colors.BLUE)
  add_line(lines, 86, string.format('S MASTER=%s  TONE A=%s B=%s C=%s  VIB=%s',
    value_text(q[1]), value_text(q[2]), value_text(q[3]), value_text(q[4]), value_text(q[5])), colors.BLUE)
  add_line(lines, 92, sound_detail(q, 'S'), colors.BLUE)

  local _, b1c = write_value(S.entry_snapshot, 0x18)
  local _, b2c = write_value(S.entry_snapshot, 0x58)
  add_line(lines, 110, string.format('BLOCK $18 N=%d   $58 N=%d', b1c, b2c), colors.BLUE)
  if S.entry_snapshot and S.entry_snapshot.speech then
    local speech = S.entry_snapshot.speech
    add_line(lines, 122, string.format('SC01 RAW=$%04X  CMD=$%02X  READS=%d',
      speech.raw_address or 0, speech.value or 0, speech.count or 0), colors.YELLOW)
  else
    add_line(lines, 122, 'SC01 RAW=----  CMD=--  READS=0', colors.BLUE)
  end
  return lines
end

local function core_version(object)
  return tostring(object and object.VERSION or '?')
end

local function page_lab(selected)
  local colors = S.lab.text.colors
  local lines = {}; add_chrome(lines, selected, colors)
  add_line(lines, 26, 'LAB', colors.YELLOW)
  add_line(lines, 38, 'CORE VERSIONS', colors.YELLOW)
  add_line(lines, 50, 'LAB ' .. core_version(S.lab) .. '   INFO ' .. M.VERSION, colors.BLUE)
  add_line(lines, 56, 'NATIVE ' .. core_version(S.lab.native) .. '   MEMORY ' .. core_version(S.lab.memory), colors.BLUE)
  add_line(lines, 62, 'LOADER ' .. core_version(S.lab.loader) .. '   VIDEO ' .. core_version(S.lab.video_debug), colors.BLUE)
  add_line(lines, 68, 'FONT ' .. core_version(S.lab.fonts) .. '   TEXT ' .. core_version(S.lab.text), colors.BLUE)
  add_line(lines, 74, 'PROBE ' .. tostring(S.takeover and S.takeover.version or 'UNAVAILABLE'), colors.BLUE)

  local tiny = S.lab.text.metrics(S.lab.fonts, 'tiny')
  local compact = S.lab.text.metrics(S.lab.fonts, 'compact')
  add_line(lines, 88, 'FONT GEOMETRY', colors.YELLOW)
  add_line(lines, 100, string.format('TINY %dX%d GLYPH  %dX%d CELL  %dX%d GRID',
    tiny.glyph_width, tiny.glyph_height, tiny.cell_width, tiny.cell_height, tiny.columns, tiny.rows), colors.BLUE)
  add_line(lines, 106, string.format('COMPACT %dX%d GLYPH  %dX%d CELL  %dX%d GRID',
    compact.glyph_width, compact.glyph_height, compact.cell_width, compact.cell_height, compact.columns, compact.rows), colors.BLUE)

  local snap = S.probe and S.probe:snapshot() or nil
  if snap then
    add_line(lines, 120, string.format('PROBE ACTIVE=%s  SEQ=%d  W=%d  R=%d',
      snap.active and 'YES' or 'NO', snap.sequence or 0, snap.write_count or 0, snap.read_count or 0),
      snap.active and colors.BLUE or colors.RED)
  else
    add_line(lines, 120, 'PROBE ACTIVE=NO', colors.RED)
  end
  add_line(lines, 126, string.format('TAKEOVER SEQ=%d  W=%d  R=%d',
    S.takeover and S.takeover.sequence or 0, S.takeover and S.takeover.write_count or 0,
    S.takeover and S.takeover.read_count or 0), colors.BLUE)
  add_line(lines, 140, string.format('CODE %s-%s  PAGE %s-%s',
    hex4(C.NATIVE_CODE), hex4(C.NATIVE_CODE_END), hex4(C.PAGE_BUFFER), hex4(C.PAGE_BUFFER_END)), colors.BLUE)
  add_line(lines, 146, string.format('STATE %s-%s  STACK %s',
    hex4(C.STATE_BASE), hex4(C.STATE_END), hex4(C.STACK_TOP)), colors.BLUE)
  return lines
end

local PAGE_BUILDERS = { page_system, page_video, page_palette, page_rom, page_audio, page_lab }

local function encode_page(lines)
  local bytes = {}
  for _, line in ipairs(lines) do
    if line.kind == 'swatch' then
      assert(line.col >= 0 and line.col + 6 <= C.SCREEN_STRIDE_BYTES,
        string.format('info swatch crosses screen: col=%d', line.col))
      assert(line.row >= 0 and line.row + 8 <= 204,
        string.format('info swatch crosses screen bottom: row=%d', line.row))
      local dest = C.VIDEO_START + line.row * C.SCREEN_STRIDE_BYTES + line.col
      bytes[#bytes + 1] = dest & 0xFF
      bytes[#bytes + 1] = (dest >> 8) & 0xFF
      bytes[#bytes + 1] = 0x80 | (line.pixel & 0x03)
    else
      local text = S.lab.fonts.encode(line.text)
      assert(line.col >= 0 and line.col + #text <= C.SCREEN_STRIDE_BYTES,
        string.format('info line crosses screen: col=%d len=%d %s', line.col, #text, line.text))
      assert(line.row >= 0 and line.row + 5 <= 203,
        string.format('info line crosses screen bottom: row=%d', line.row))
      local dest = C.VIDEO_START + line.row * C.SCREEN_STRIDE_BYTES + line.col
      local logical = S.lab.text.pixel_color(line.color)
      assert(logical >= 1 and logical <= 3, 'info text uses foreground colors 1..3 only')
      bytes[#bytes + 1] = dest & 0xFF
      bytes[#bytes + 1] = (dest >> 8) & 0xFF
      bytes[#bytes + 1] = logical
      for _, code in ipairs(text) do bytes[#bytes + 1] = code end
      bytes[#bytes + 1] = 0
    end
  end
  bytes[#bytes + 1] = 0
  bytes[#bytes + 1] = 0
  assert(#bytes <= C.PAGE_BUFFER_END - C.PAGE_BUFFER + 1,
    string.format('info page buffer overflow: %d bytes', #bytes))
  return bytes
end

local function write_page(index)
  index = math.max(0, math.min(C.TAB_COUNT - 1, tonumber(index) or 0))
  local builder = PAGE_BUILDERS[index + 1]
  local bytes = encode_page(builder(index))
  S.lab.memory.fill(S.program, C.PAGE_BUFFER, C.PAGE_BUFFER_END, 0)
  S.lab.memory.write_bytes(S.program, C.PAGE_BUFFER, bytes)
  return #bytes
end

local function install_shortcut(name, handler)
  local previous = rawget(_G, name)
  S.shortcuts[name] = { handler=handler, previous=previous, restore=previous ~= nil }
  rawset(_G, name, handler)
end

local function restore_shortcuts()
  for name, shortcut in pairs(S.shortcuts) do
    if rawget(_G, name) == shortcut.handler then
      rawset(_G, name, shortcut.restore and shortcut.previous or nil)
    end
  end
  S.shortcuts = {}
end

local function print_status()
  if not S.active then print('[ASTRO INFO] module is not active'); return false end
  local selected = S.program:read_u8(C.STATE_SELECTED_TAB)
  local snap = S.probe and S.probe:snapshot() or nil
  printf('version=%s tab=%d/%d %s redraw=%d event=%d probe_seq=%d writes=%d reads=%d',
    M.VERSION, selected + 1, C.TAB_COUNT, TAB_NAMES[selected + 1] or '?',
    S.program:read_u8(C.STATE_REDRAW_SEQUENCE), S.program:read_u8(C.STATE_EVENT_SEQUENCE),
    snap and snap.sequence or 0, snap and snap.write_count or 0, snap and snap.read_count or 0)
  return true
end

local function print_roms()
  if not S.roms then return false end
  for _, row in ipairs(S.roms) do
    printf('%s CRC=%08X %s', row.label, row.crc, row.identity)
  end
  return true
end

local function print_help()
  print('[ASTRO INFO] console commands:')
  print('[ASTRO INFO]   ainfo()      module/tab/probe status')
  print('[ASTRO INFO]   airoms()     mapped 4K ROM CRC32 list')
  print('[ASTRO INFO]   aihelp()     command summary')
end

function M.start(lab)
  S.lab = lab
  S.program = lab.native.program
  S.io_space = lab.native.cpu and lab.native.cpu.spaces and lab.native.cpu.spaces['io'] or nil
  S.probe = lab.hardware_probe
  S.active = true
  S.machine_info = machine_info(lab)
  S.takeover = S.probe and (S.probe:frozen('takeover') or S.probe:snapshot()) or nil
  S.entry_snapshot = S.probe and S.probe:snapshot() or nil
  S.roms = scan_roms(S.program)
  S.original_horcb = select(1, write_value(S.takeover, C.HORCB_PORT))
  if S.original_horcb ~= nil then
    -- In commercial mode HORCB units are two packed bytes. Split 26 therefore
    -- places the boundary at byte 52, leaving room for four right-bank swatches
    -- while keeping the compact title entirely on the left palette.
    S.palette_view_horcb = (S.original_horcb & 0xC0) | 0x1A
  else
    S.palette_view_horcb = nil
  end

  local code, labels = build_controller(S.original_horcb, S.palette_view_horcb)
  S.code_labels = labels
  local font_bytes = lab.fonts.row_bytes('tiny')
  local lut = color_lut_bytes()
  local header = compact_header_bitmap(lab.fonts, 'ASTROCADE INFO', lab.text.pixel_color(lab.text.colors.BLUE))

  assert(#font_bytes == C.FONT_TINY_END - C.FONT_TINY + 1)
  assert(#lut == C.COLOR_LUT_END - C.COLOR_LUT + 1)
  assert(#header == C.HEADER_BITMAP_END - C.HEADER_BITMAP + 1)

  -- Replace only the disposable Lab application image. Text and swatches are
  -- written directly to VRAM; the native controller changes only HORCB when the
  -- PALETTE tab needs both physical color banks visible at once.
  lab.memory.fill(S.program, lab.memory.addr.APPLICATION_START, lab.memory.addr.APPLICATION_END, 0)
  lab.memory.write_bytes(S.program, C.NATIVE_CODE, code)
  lab.memory.write_bytes(S.program, C.FONT_TINY, font_bytes)
  lab.memory.write_bytes(S.program, C.COLOR_LUT, lut)
  lab.memory.write_bytes(S.program, C.HEADER_BITMAP, header)
  local page_bytes = write_page(0)

  S.last_event_sequence = 0
  install_shortcut('ainfo', print_status)
  install_shortcut('airoms', print_roms)
  install_shortcut('aihelp', print_help)

  printf('ASTROCADE INFO MODULE %s', M.VERSION)
  printf('native controller %s-%s (%d bytes); tiny font=%d; header=%d; page0=%d',
    hex4(C.NATIVE_CODE), hex4(C.NATIVE_CODE + #code - 1), #code,
    #font_bytes, #header, page_bytes)
  printf('probe=%s; takeover=%s seq=%d',
    S.entry_snapshot and tostring(S.entry_snapshot.detail) or 'UNAVAILABLE',
    S.takeover and 'CAPTURED' or 'UNAVAILABLE', S.takeover and S.takeover.sequence or 0)
  print('[ASTRO INFO] controls: LEFT/UP previous tab; RIGHT/DOWN next tab; 1P return')
  print_help()

  lab.native:handoff(C.NATIVE_CODE, C.STACK_TOP)
end

function M.update(_lab)
  if not S.active or not S.program then return end

  local event = S.program:read_u8(C.STATE_EVENT_SEQUENCE)
  if event ~= S.last_event_sequence then
    S.last_event_sequence = event
    local event_type = S.program:read_u8(C.STATE_EVENT_TYPE)
    if event_type == 1 then
      local selected = S.program:read_u8(C.STATE_PAGE_REQUEST)
      local bytes = write_page(selected)
      S.program:write_u8(C.STATE_REDRAW_REQUEST, 1)
      printf('TAB %d/%d %s page=%d bytes', selected + 1, C.TAB_COUNT,
        TAB_NAMES[selected + 1] or '?', bytes)
    end
  end

end

function M.stop(_lab)
  if not S.active then return end
  S.active = false

  -- The palette page moves HORCB only to expose both physical palette banks.
  -- Restore the game's captured boundary before the Lab menu is redrawn.
  if S.io_space and S.original_horcb ~= nil then
    pcall(function() S.io_space:write_u8(C.HORCB_PORT, S.original_horcb) end)
  end

  restore_shortcuts()
  print('[ASTRO INFO] return to Lab')
  S.lab, S.program, S.io_space, S.probe = nil, nil, nil, nil
  S.takeover, S.entry_snapshot, S.machine_info, S.roms = nil, nil, nil, nil
  S.code_labels = nil
  S.original_horcb, S.palette_view_horcb = nil, nil
end

return M
