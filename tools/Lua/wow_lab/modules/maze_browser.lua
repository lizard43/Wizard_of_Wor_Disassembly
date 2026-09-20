-- modules/maze_browser.lua
-- Wizard of Wor Lab native maze browser.
--
-- Install this file as modules/maze_browser.lua.  Native Z80 selects each
-- resident ROM maze through WoW's $1AED pointer table, expands it with the
-- game's $1A7D decoder, and draws it with the complete $17AA maze path.  Lua
-- remains the Lab lifecycle supervisor and decodes native diagnostic records.

local M = {}
M.VERSION = '1.1.0-20260817-1623'

local C = {
  -- Resident Wizard of Wor code, data, and cabinet ports.
  PRINT_STRING_COLOR       = 0x03B5,
  DRAW_MAZE_WITH_GATES     = 0x17AA,
  EXPAND_SELECTED_MAZE     = 0x1A7D,
  UPDATE_WORLUK_FLASH      = 0x075B,
  MAZE_POINTER_TABLE       = 0x1AED,
  MAZE_INDEX               = 0xD318,
  MAZE_COLOR_SELECTOR      = 0xD1EB,
  WORLUK_FLASH_COUNT       = 0xD1BD,
  WORLUK_FLASH_DIVIDER     = 0xD1BE,
  COINPORT                 = 0x10,
  P2PORT                   = 0x11,
  P1PORT                   = 0x12,

  -- Native application workspace.  $D380-$D3FF remains Lab-owned.
  NATIVE_CODE              = 0xD400,
  NATIVE_CODE_END          = 0xD6FF,
  STATE_BASE               = 0xD700,
  STATE_SELECTED           = 0xD700,
  STATE_INPUT_CURRENT      = 0xD701,
  STATE_HOLD_DIRECTION     = 0xD702,
  STATE_HOLD_COUNTDOWN     = 0xD703,
  STATE_EVENT_SEQUENCE     = 0xD704,
  STATE_EVENT_TYPE         = 0xD705, -- 1 selection, 2 requested redraw
  STATE_REDRAW_SEQUENCE    = 0xD706,
  STATE_ADDRESS            = 0xD707, -- little-endian selected ROM address
  STATE_REDRAW_REQUEST     = 0xD709,
  STATE_2P_START_LAST      = 0xD70A,
  STATE_FLASH_PHASE        = 0xD70B,
  STATE_FLASH_SEQUENCE     = 0xD70C,
  STATE_END                = 0xD70C,
  STACK_TOP                = 0xDFE0,

  VIDEO_START              = 0x4000,
  VISIBLE_VIDEO_END        = 0x7FBF,
  SCREEN_STRIDE_BYTES      = 80,

  MAZE_COUNT               = 24,
  PACKED_MAZE_BYTES        = 18,
  EXPANDED_COLUMNS         = 11,
  EXPANDED_ROWS            = 6,

  INPUT_DIRECTION_MASK     = 0x0F,
  INPUT_UP                 = 0x01,
  INPUT_DOWN               = 0x02,
  INPUT_LEFT               = 0x04,
  INPUT_RIGHT              = 0x08,
  REPEAT_INITIAL           = 12,
  REPEAT_RATE              = 3,
  P1_START_MASK            = 0x20,
  P2_START_MASK            = 0x40,
  WORLUK_FLASH_TICKS       = 0x20,

  TEXT_BLUE                = 0x04,
  TEXT_YELLOW              = 0x08,
  VERSION_DEST             = 74,
  INFO_DEST                = 152 * 80 + 28,
  INSTRUCTION_DEST         = 12 * 16 * 80 + 4,
}

-- Expected pointer-table order from the labeled WoW disassembly.  Rendering
-- never depends on this copy: native code reads the live ROM table directly.
local EXPECTED_ADDRESSES = {
  0x1B1D, 0x1C19, 0x1B2F, 0x1B41, 0x1B53, 0x1B65,
  0x1B77, 0x1B89, 0x1B9B, 0x1BAD, 0x1BBF, 0x1BD1,
  0x1BE3, 0x1BF5, 0x1C07, 0x1C2B, 0x1C3D, 0x1C4F,
  0x1C61, 0x1C73, 0x1C85, 0x1C97, 0x1CA9, 0x1CBB,
}

local TEXT = {
  VERSION = 'V11',
  INFO_PREFIX = 'MAZE ',
  INFO_MIDDLE = ' ',
  INSTRUCTION = 'JOY UR NEXT DL PREV 2P FLASH 1P EXIT',
}
TEXT.INFO_LENGTH = #TEXT.INFO_PREFIX + 2 + #TEXT.INFO_MIDDLE + 4

local S = {
  active = false,
  lab = nil,
  program = nil,
  controller_labels = nil,
  last_event_sequence = 0,
  last_redraw_sequence = 0,
  last_flash_sequence = 0,
  shortcuts = {},
}

local function printf(fmt, ...)
  print(string.format(fmt, ...))
end

local function hex2(value)
  return string.format('$%02X', (value or 0) & 0xFF)
end

local function hex4(value)
  return string.format('$%04X', (value or 0) & 0xFFFF)
end

-- Small label-aware emitter keeps the injected controller symbolic without an
-- external assembler at runtime.
local function assembler(origin)
  local a = { origin = origin, bytes = {}, labels = {}, fixups = {} }

  function a:pc() return self.origin + #self.bytes end
  function a:b(value) self.bytes[#self.bytes + 1] = value & 0xFF end
  function a:w(value) self:b(value); self:b(value >> 8) end
  function a:label(name) self.labels[name] = self:pc() end
  function a:word(target)
    if type(target) == 'number' then
      self:w(target)
    else
      local position = #self.bytes + 1
      self:w(0)
      self.fixups[#self.fixups + 1] = {
        kind = 'abs', position = position, target = target,
      }
    end
  end
  function a:abs(opcode, target)
    self:b(opcode)
    self:word(target)
  end
  function a:jr(opcode, target)
    self:b(opcode)
    local position = #self.bytes + 1
    self:b(0)
    self.fixups[#self.fixups + 1] = {
      kind = 'rel', position = position, target = target,
    }
  end
  function a:finish()
    for _, fixup in ipairs(self.fixups) do
      local target = assert(self.labels[fixup.target],
        'undefined native label: ' .. tostring(fixup.target))
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

local function build_controller()
  assert(C.VERSION_DEST + #TEXT.VERSION * 2 <= C.SCREEN_STRIDE_BYTES,
    'maze version text exceeds the right screen margin')
  local info_x_byte = C.INFO_DEST % C.SCREEN_STRIDE_BYTES
  assert(info_x_byte >= 13 and info_x_byte + TEXT.INFO_LENGTH * 2 - 1 <= 66,
    'maze information text overlaps a lower boundary cell')
  assert((C.INSTRUCTION_DEST % C.SCREEN_STRIDE_BYTES) + #TEXT.INSTRUCTION * 2 <=
    C.SCREEN_STRIDE_BYTES, 'maze instruction text exceeds the screen width')

  local a = assembler(C.NATIVE_CODE)

  a:label('entry')
  a:b(0xF3)                                      -- DI
  a:b(0x31); a:w(C.STACK_TOP)                    -- LD SP,$DFE0

  -- Clear module state without touching the permanent Lab ABI/kernel.
  a:b(0xAF)                                      -- XOR A
  a:b(0x21); a:w(C.STATE_BASE)                   -- LD HL,state
  a:b(0x11); a:w(C.STATE_BASE + 1)               -- LD DE,state+1
  a:b(0x01); a:w(C.STATE_END - C.STATE_BASE)     -- LD BC,size-1
  a:b(0x77); a:b(0xED); a:b(0xB0)               -- LD (HL),A / LDIR

  -- The resident flash state is game-owned RAM below the Lab workspace.  Seed
  -- it to idle, then prime the active-low 2P Start edge detector.
  emit_ld_mem_a(a, C.WORLUK_FLASH_COUNT)
  emit_ld_mem_a(a, C.WORLUK_FLASH_DIVIDER)
  emit_call(a, 'prime_2p_start')

  emit_call(a, 'draw_selected_maze')
  a:b(0x3E); a:b(0x01); emit_ld_mem_a(a, C.STATE_EVENT_TYPE)
  a:b(0x21); a:w(C.STATE_EVENT_SEQUENCE); a:b(0x34)

  a:label('main')
  a:b(0xFB); a:b(0x76)                           -- EI / HALT
  emit_ld_a_mem(a, C.STATE_REDRAW_REQUEST)
  a:b(0xB7); a:jr(0x28, 'main_read_controls')   -- OR A / JR Z
  a:b(0xAF); emit_ld_mem_a(a, C.STATE_REDRAW_REQUEST)
  emit_call(a, 'draw_selected_maze')
  a:b(0x3E); a:b(0x02); emit_ld_mem_a(a, C.STATE_EVENT_TYPE)
  a:b(0x21); a:w(C.STATE_EVENT_SEQUENCE); a:b(0x34)
  a:label('main_read_controls')
  emit_call(a, 'read_2p_start')
  emit_call(a, 'service_worluk_flash')
  emit_call(a, 'read_controls')
  emit_jp(a, 'main')

  a:label('prime_2p_start')
  a:b(0xDB); a:b(C.COINPORT); a:b(0x2F); a:b(0xE6); a:b(C.P2_START_MASK)
  emit_ld_mem_a(a, C.STATE_2P_START_LAST)
  a:b(0xC9)

  -- COINPORT bit 6 is 2P Start (active low).  A new edge reproduces the exact
  -- game command at $1291: write $20 to $D1BD.  1P remains Lab-owned; if it is
  -- pressed during a flash, finish the resident cycle before the menu returns.
  a:label('read_2p_start')
  a:b(0xDB); a:b(C.COINPORT); a:b(0x2F); a:b(0xE6); a:b(C.P1_START_MASK)
  a:jr(0x28, 'read_2p_edge')
  emit_ld_a_mem(a, C.WORLUK_FLASH_COUNT); a:b(0xB7)
  a:jr(0x28, 'read_2p_edge')
  a:b(0x3E); a:b(0x01); emit_ld_mem_a(a, C.WORLUK_FLASH_COUNT)
  a:b(0xAF); emit_ld_mem_a(a, C.WORLUK_FLASH_DIVIDER)
  emit_call(a, C.UPDATE_WORLUK_FLASH)

  a:label('read_2p_edge')
  a:b(0xDB); a:b(C.COINPORT); a:b(0x2F); a:b(0xE6); a:b(C.P2_START_MASK)
  a:b(0x47)                                      -- LD B,current
  emit_ld_a_mem(a, C.STATE_2P_START_LAST); a:b(0x2F); a:b(0xA0)
  a:jr(0x28, 'store_2p_start')                  -- no new active-high edge
  a:b(0x3E); a:b(C.WORLUK_FLASH_TICKS)
  emit_ld_mem_a(a, C.WORLUK_FLASH_COUNT)
  a:b(0x21); a:w(C.STATE_FLASH_SEQUENCE); a:b(0x34)
  a:label('store_2p_start')
  a:b(0x78); emit_ld_mem_a(a, C.STATE_2P_START_LAST)
  a:b(0xC9)

  -- WoW calls $075B on alternating frame-service phases.  Keep that cadence so
  -- its $D1BD/$D1BE countdown and palette toggles run at original speed.
  a:label('service_worluk_flash')
  emit_ld_a_mem(a, C.STATE_FLASH_PHASE); a:b(0xEE); a:b(0x01)
  emit_ld_mem_a(a, C.STATE_FLASH_PHASE)
  a:b(0xC0)                                      -- RET NZ
  emit_jp(a, C.UPDATE_WORLUK_FLASH)

  -- Read both player joystick ports.  The permanent Lab kernel owns 1P Start,
  -- so returning to the menu remains independent of this application image.
  a:label('read_controls')
  a:b(0xDB); a:b(C.P1PORT); a:b(0x2F); a:b(0xE6); a:b(C.INPUT_DIRECTION_MASK); a:b(0x47)
  a:b(0xDB); a:b(C.P2PORT); a:b(0x2F); a:b(0xE6); a:b(C.INPUT_DIRECTION_MASK); a:b(0xB0)
  a:b(0x47)                                      -- LD B,A
  emit_ld_mem_a(a, C.STATE_INPUT_CURRENT)

  -- Only exact cardinal states navigate.  Up/Right advance and Down/Left
  -- retreat through the circular 24-entry maze table.
  for _, direction in ipairs({C.INPUT_UP, C.INPUT_DOWN, C.INPUT_LEFT, C.INPUT_RIGHT}) do
    a:b(0xFE); a:b(direction); a:jr(0x28, 'direction_valid')
  end
  emit_jp(a, 'direction_release')

  a:label('direction_valid')
  emit_ld_a_mem(a, C.STATE_HOLD_DIRECTION); a:b(0xB8) -- CP B
  a:jr(0x20, 'direction_new')
  a:b(0x21); a:w(C.STATE_HOLD_COUNTDOWN); a:b(0x35) -- DEC (HL)
  a:b(0xC0)                                      -- RET NZ
  a:b(0x36); a:b(C.REPEAT_RATE)                  -- LD (HL),rate
  a:b(0x78); emit_jp(a, 'move_direction')        -- LD A,B

  a:label('direction_new')
  a:b(0x78); emit_ld_mem_a(a, C.STATE_HOLD_DIRECTION)
  a:b(0x3E); a:b(C.REPEAT_INITIAL); emit_ld_mem_a(a, C.STATE_HOLD_COUNTDOWN)
  a:b(0x78); emit_jp(a, 'move_direction')

  a:label('direction_release')
  a:b(0xAF)
  emit_ld_mem_a(a, C.STATE_HOLD_DIRECTION)
  emit_ld_mem_a(a, C.STATE_HOLD_COUNTDOWN)
  a:b(0xC9)

  a:label('move_direction')
  a:b(0xFE); a:b(C.INPUT_UP); a:abs(0xCA, 'maze_next')
  a:b(0xFE); a:b(C.INPUT_RIGHT); a:abs(0xCA, 'maze_next')
  emit_jp(a, 'maze_previous')

  a:label('maze_next')
  emit_ld_a_mem(a, C.STATE_SELECTED); a:b(0x3C)  -- INC A
  a:b(0xFE); a:b(C.MAZE_COUNT); a:jr(0x38, 'store_selection')
  a:b(0xAF)                                      -- wrap 23 -> 0
  a:jr(0x18, 'store_selection')

  a:label('maze_previous')
  emit_ld_a_mem(a, C.STATE_SELECTED); a:b(0xB7)
  a:jr(0x20, 'maze_previous_decrement')
  a:b(0x3E); a:b(C.MAZE_COUNT)
  a:label('maze_previous_decrement')
  a:b(0x3D)                                      -- DEC A; wraps 0 -> 23

  a:label('store_selection')
  emit_ld_mem_a(a, C.STATE_SELECTED)
  emit_call(a, 'draw_selected_maze')
  a:b(0x3E); a:b(0x01); emit_ld_mem_a(a, C.STATE_EVENT_TYPE)
  a:b(0x21); a:w(C.STATE_EVENT_SEQUENCE); a:b(0x34)
  a:b(0xC9)

  a:label('draw_selected_maze')
  a:b(0xF3)                                      -- DI

  -- Clear the visible 320x204 bitmap.  The non-visible stack margin remains
  -- untouched, matching the Lab menu's screen ownership rule.
  a:b(0xAF)
  a:b(0x21); a:w(C.VIDEO_START)
  a:b(0x11); a:w(C.VIDEO_START + 1)
  a:b(0x01); a:w(C.VISIBLE_VIDEO_END - C.VIDEO_START)
  a:b(0x77); a:b(0xED); a:b(0xB0)

  -- Resolve the selected record through the live ROM pointer table and retain
  -- the address for the visible native status line and Lua diagnostics.
  emit_ld_a_mem(a, C.STATE_SELECTED)
  emit_ld_mem_a(a, C.MAZE_INDEX)
  a:b(0x87); a:b(0x5F); a:b(0x16); a:b(0x00)    -- *2 / LD E,A / LD D,0
  a:b(0x21); a:w(C.MAZE_POINTER_TABLE); a:b(0x19)
  a:b(0x5E); a:b(0x23); a:b(0x56)               -- LD E,(HL)/INC/LD D,(HL)
  a:b(0xED); a:b(0x53); a:w(C.STATE_ADDRESS)    -- LD (address),DE

  -- Select WoW's normal blue maze expansion color.  $17AA draws the maze and
  -- overlays the two red portal gates with the game's original routines.
  a:b(0xAF); emit_ld_mem_a(a, C.MAZE_COLOR_SELECTOR)
  emit_call(a, C.EXPAND_SELECTED_MAZE)
  emit_call(a, C.DRAW_MAZE_WITH_GATES)

  emit_call(a, 'update_info_text')
  emit_call(a, 'draw_text')
  a:b(0x21); a:w(C.STATE_REDRAW_SEQUENCE); a:b(0x34)
  a:b(0xFB); a:b(0xC9)                           -- EI / RET

  -- Patch the selected decimal index and its four-digit ROM address into the
  -- resident native text record.
  a:label('update_info_text')
  emit_ld_a_mem(a, C.STATE_SELECTED)
  a:b(0x06); a:b(string.byte('0'))               -- LD B,'0'
  a:label('decimal_tens_loop')
  a:b(0xFE); a:b(10); a:jr(0x38, 'decimal_ready')
  a:b(0xD6); a:b(10); a:b(0x04)                 -- SUB 10 / INC B
  a:jr(0x18, 'decimal_tens_loop')
  a:label('decimal_ready')
  a:b(0xC6); a:b(string.byte('0'))
  a:abs(0x32, 'info_index_ones')
  a:b(0x78); a:abs(0x32, 'info_index_tens')

  emit_ld_a_mem(a, C.STATE_ADDRESS + 1)
  a:b(0x0F); a:b(0x0F); a:b(0x0F); a:b(0x0F)
  emit_call(a, 'nibble_to_ascii'); a:abs(0x32, 'info_address_0')
  emit_ld_a_mem(a, C.STATE_ADDRESS + 1)
  emit_call(a, 'nibble_to_ascii'); a:abs(0x32, 'info_address_1')
  emit_ld_a_mem(a, C.STATE_ADDRESS)
  a:b(0x0F); a:b(0x0F); a:b(0x0F); a:b(0x0F)
  emit_call(a, 'nibble_to_ascii'); a:abs(0x32, 'info_address_2')
  emit_ld_a_mem(a, C.STATE_ADDRESS)
  emit_call(a, 'nibble_to_ascii'); a:abs(0x32, 'info_address_3')
  a:b(0xC9)

  a:label('nibble_to_ascii')
  a:b(0xE6); a:b(0x0F); a:b(0xC6); a:b(0x30)
  a:b(0xFE); a:b(0x3A); a:b(0xD8)               -- RET C for 0-9
  a:b(0xC6); a:b(0x07); a:b(0xC9)               -- A-F

  a:label('draw_text')
  a:b(0x21); a:word('version_text')
  a:b(0x11); a:w(C.VERSION_DEST)
  a:b(0x06); a:b(#TEXT.VERSION); a:b(0x3E); a:b(C.TEXT_YELLOW)
  emit_call(a, C.PRINT_STRING_COLOR)

  a:b(0x21); a:word('info_line')
  a:b(0x11); a:w(C.INFO_DEST)
  a:b(0x06); a:b(TEXT.INFO_LENGTH); a:b(0x3E); a:b(C.TEXT_BLUE)
  emit_call(a, C.PRINT_STRING_COLOR)

  a:b(0x21); a:word('instruction_text')
  a:b(0x11); a:w(C.INSTRUCTION_DEST)
  a:b(0x06); a:b(#TEXT.INSTRUCTION); a:b(0x3E); a:b(C.TEXT_YELLOW)
  emit_call(a, C.PRINT_STRING_COLOR)
  a:b(0xC9)

  local function emit_native_text(text)
    text = text:gsub(' ', '@'):gsub('%-', '_')
    for index = 1, #text do a:b(text:byte(index)) end
  end

  a:label('version_text')
  emit_native_text(TEXT.VERSION)
  a:label('info_line')
  emit_native_text(TEXT.INFO_PREFIX)
  a:label('info_index_tens'); a:b(string.byte('0'))
  a:label('info_index_ones'); a:b(string.byte('0'))
  emit_native_text(TEXT.INFO_MIDDLE)
  a:label('info_address_0'); a:b(string.byte('0'))
  a:label('info_address_1'); a:b(string.byte('0'))
  a:label('info_address_2'); a:b(string.byte('0'))
  a:label('info_address_3'); a:b(string.byte('0'))
  a:label('instruction_text')
  emit_native_text(TEXT.INSTRUCTION)

  local bytes, labels = a:finish()
  assert(C.NATIVE_CODE + #bytes - 1 <= C.NATIVE_CODE_END,
    string.format('maze native controller exceeds reserved range: %d bytes', #bytes))
  return bytes, labels
end

local function read_word(address)
  local low = S.program:read_u8(address)
  local high = S.program:read_u8(address + 1)
  return low | (high << 8)
end

local function live_maze_address(index)
  return read_word(C.MAZE_POINTER_TABLE + index * 2)
end

local function maze_name(index)
  return string.format('MAZE_%02d_DATA', index)
end

local function fnv1a_maze(address)
  local hash = 0x811C9DC5
  for offset = 0, C.PACKED_MAZE_BYTES - 1 do
    hash = ((hash ~ S.program:read_u8(address + offset)) * 0x01000193) & 0xFFFFFFFF
  end
  return hash
end

local function maze_bytes_text(address)
  local values = {}
  for offset = 0, C.PACKED_MAZE_BYTES - 1 do
    values[#values + 1] = string.format('%02X', S.program:read_u8(address + offset))
  end
  return table.concat(values, ' ')
end

local function selected_index()
  if not S.active or not S.program then return nil end
  local index = S.program:read_u8(C.STATE_SELECTED)
  if index >= C.MAZE_COUNT then return nil end
  return index
end

local function print_selected(prefix)
  if not S.active or not S.program then
    print('[WOW MAZE] maze browser is not active')
    return nil
  end
  local index = selected_index()
  if index == nil then
    printf('[WOW MAZE] %s native selection is out of range', prefix or 'CURRENT')
    return nil
  end
  local address = live_maze_address(index)
  printf('[WOW MAZE] %s index=%02d/23 pointer=%s ROM=%s bytes=%d hash=$%08X %s',
    prefix or 'CURRENT', index,
    hex4(C.MAZE_POINTER_TABLE + index * 2), hex4(address),
    C.PACKED_MAZE_BYTES, fnv1a_maze(address), maze_name(index))
  printf('[WOW MAZE] DATA %s', maze_bytes_text(address))
  return {
    index = index,
    name = maze_name(index),
    pointer = C.MAZE_POINTER_TABLE + index * 2,
    address = address,
    hash = fnv1a_maze(address),
  }
end

local function audit_catalog(verbose)
  if not S.active or not S.program then
    print('[WOW MAZE] wmzaudit(): module is not active')
    return false
  end

  local mismatches, duplicates, invalid = 0, 0, 0
  local seen = {}
  for index = 0, C.MAZE_COUNT - 1 do
    local address = live_maze_address(index)
    if address ~= EXPECTED_ADDRESSES[index + 1] then mismatches = mismatches + 1 end
    if seen[address] then duplicates = duplicates + 1 else seen[address] = true end
    if address < 0 or address + C.PACKED_MAZE_BYTES - 1 > 0x3FFF then
      invalid = invalid + 1
    end
    if verbose then
      printf('[WOW MAZE] %02d PTR=%s ROM=%s HASH=$%08X %s',
        index, hex4(C.MAZE_POINTER_TABLE + index * 2), hex4(address),
        fnv1a_maze(address), maze_name(index))
    end
  end

  printf('[WOW MAZE] catalog audit: pointers=%d mismatches=%d duplicates=%d invalid=%d',
    C.MAZE_COUNT, mismatches, duplicates, invalid)
  return mismatches == 0 and duplicates == 0 and invalid == 0
end

local function print_list(first, count)
  if not S.active or not S.program then
    print('[WOW MAZE] wmzlist(): module is not active')
    return false
  end
  first = math.floor(tonumber(first) or 0)
  count = math.floor(tonumber(count) or C.MAZE_COUNT)
  if first < 0 then first = 0 end
  if count < 1 then count = 1 end
  local last = math.min(C.MAZE_COUNT - 1, first + count - 1)
  if first >= C.MAZE_COUNT then
    print('[WOW MAZE] wmzlist(): first index is out of range')
    return false
  end
  for index = first, last do
    local address = live_maze_address(index)
    printf('[WOW MAZE] %02d PTR=%s ROM=%s HASH=$%08X %s',
      index, hex4(C.MAZE_POINTER_TABLE + index * 2), hex4(address),
      fnv1a_maze(address), maze_name(index))
  end
  return true
end

local function print_status()
  if not S.active or not S.program then
    print('[WOW MAZE] maze browser is not active')
    return nil
  end
  local pc = S.lab.native.cpu.state['PC'] and S.lab.native.cpu.state['PC'].value or 0
  local sp = S.lab.native.cpu.state['SP'] and S.lab.native.cpu.state['SP'].value or 0
  printf('[WOW MAZE] version=%s PC=%s SP=%s selected=%d address=%s input=%s hold=%s/%d event=%d/%d redraw=%d 2P=%s flash=$%02X/$%02X seq=%d',
    M.VERSION, hex4(pc), hex4(sp),
    S.program:read_u8(C.STATE_SELECTED), hex4(read_word(C.STATE_ADDRESS)),
    hex2(S.program:read_u8(C.STATE_INPUT_CURRENT)),
    hex2(S.program:read_u8(C.STATE_HOLD_DIRECTION)),
    S.program:read_u8(C.STATE_HOLD_COUNTDOWN),
    S.program:read_u8(C.STATE_EVENT_TYPE),
    S.program:read_u8(C.STATE_EVENT_SEQUENCE),
    S.program:read_u8(C.STATE_REDRAW_SEQUENCE),
    hex2(S.program:read_u8(C.STATE_2P_START_LAST)),
    S.program:read_u8(C.WORLUK_FLASH_COUNT),
    S.program:read_u8(C.WORLUK_FLASH_DIVIDER),
    S.program:read_u8(C.STATE_FLASH_SEQUENCE))
  return true
end

local function request_redraw()
  if not S.active or not S.program then
    print('[WOW MAZE] wmzredraw(): module is not active')
    return false
  end
  S.program:write_u8(C.STATE_REDRAW_REQUEST, 1)
  print('[WOW MAZE] native maze redraw requested')
  return true
end

local function install_shortcut(name, handler)
  local previous = rawget(_G, name)
  S.shortcuts[name] = {
    handler = handler,
    previous = previous,
    restore = previous ~= nil,
  }
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

local function print_help()
  print('[WOW MAZE] console commands:')
  print('[WOW MAZE]   wmzinfo()          selected maze, ROM address, bytes and hash')
  print('[WOW MAZE]   wmzstatus()        native controller/input/flash state')
  print('[WOW MAZE]   wmzlist([n],[c])   list from zero-based maze index n')
  print('[WOW MAZE]   wmzaudit([detail]) audit live ROM pointers; true lists all')
  print('[WOW MAZE]   wmzredraw()        request a native redraw')
  print('[WOW MAZE]   wmzhelp()          command summary')
end

local function install_shortcuts()
  install_shortcut('wmzinfo', function() return print_selected('CURRENT') end)
  install_shortcut('wmzstatus', print_status)
  install_shortcut('wmzlist', print_list)
  install_shortcut('wmzaudit', function(detail) return audit_catalog(detail == true) end)
  install_shortcut('wmzredraw', request_redraw)
  install_shortcut('wmzhelp', print_help)
end

function M.start(lab)
  S.lab = lab
  S.program = lab.native.program
  S.active = true

  local code, labels = build_controller()
  S.controller_labels = labels

  -- The module replaces only the disposable application image.  The resident
  -- Lab ABI/kernel and WoW sound/speech work area stay intact.
  lab.memory.fill(S.program, lab.memory.addr.APPLICATION_START,
    lab.memory.addr.APPLICATION_END, 0)
  lab.memory.write_bytes(S.program, C.NATIVE_CODE, code)

  S.last_event_sequence = 0
  S.last_redraw_sequence = 0
  S.last_flash_sequence = 0
  install_shortcuts()

  printf('[WOW MAZE] MAZE BROWSER MODULE %s', M.VERSION)
  printf('[WOW MAZE] catalog=%d resident packed mazes; record=%d bytes; expanded=%dx%d cells',
    C.MAZE_COUNT, C.PACKED_MAZE_BYTES, C.EXPANDED_COLUMNS, C.EXPANDED_ROWS)
  printf('[WOW MAZE] native controller %s-%s; state %s-%s; stack %s',
    hex4(C.NATIVE_CODE), hex4(C.NATIVE_CODE + #code - 1),
    hex4(C.STATE_BASE), hex4(C.STATE_END), hex4(C.STACK_TOP))
  printf('[WOW MAZE] native ROM path: table %s -> decoder %s -> complete draw %s',
    hex4(C.MAZE_POINTER_TABLE), hex4(C.EXPAND_SELECTED_MAZE),
    hex4(C.DRAW_MAZE_WITH_GATES))
  printf('[WOW MAZE] text: WoW Print_String_With_Color %s; version top right',
    hex4(C.PRINT_STRING_COLOR))
  print('[WOW MAZE] controls: Up/Right next; Down/Left previous; 2P Worluk-death flash; 1P Exit')
  printf('[WOW MAZE] flash path: 2P edge writes %s=$20; resident service %s runs every other frame',
    hex4(C.WORLUK_FLASH_COUNT), hex4(C.UPDATE_WORLUK_FLASH))
  audit_catalog(false)
  print_help()
  print('[WOW MAZE] initial native selection: maze index 00')

  lab.native:handoff(C.NATIVE_CODE, C.STACK_TOP)
end

function M.update(_lab)
  if not S.active or not S.program then return end

  local redraw = S.program:read_u8(C.STATE_REDRAW_SEQUENCE)
  if redraw ~= S.last_redraw_sequence then
    S.last_redraw_sequence = redraw
    printf('[WOW MAZE] REDRAW seq=%d index=%02d ROM=%s', redraw,
      S.program:read_u8(C.STATE_SELECTED), hex4(read_word(C.STATE_ADDRESS)))
  end

  local event = S.program:read_u8(C.STATE_EVENT_SEQUENCE)
  if event ~= S.last_event_sequence then
    S.last_event_sequence = event
    local event_type = S.program:read_u8(C.STATE_EVENT_TYPE)
    if event_type == 1 then
      print_selected('SELECT')
    elseif event_type == 2 then
      print_selected('REDRAW')
    else
      printf('[WOW MAZE] native event seq=%d type=%d', event, event_type)
    end
  end

  local flash = S.program:read_u8(C.STATE_FLASH_SEQUENCE)
  if flash ~= S.last_flash_sequence then
    S.last_flash_sequence = flash
    printf('[WOW MAZE] FLASH seq=%d trigger=2P count=%s service=%s', flash,
      hex2(S.program:read_u8(C.WORLUK_FLASH_COUNT)), hex4(C.UPDATE_WORLUK_FLASH))
  end
end

function M.stop(_lab)
  if not S.active then return end
  S.active = false
  restore_shortcuts()
  print('[WOW MAZE] return to Wizard of Wor Lab')
  S.controller_labels = nil
  S.program = nil
  S.lab = nil
end

return M
