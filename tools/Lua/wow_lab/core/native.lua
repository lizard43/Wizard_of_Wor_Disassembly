-- core/native.lua
-- Native Z80 supervisor and WoW text renderer for the Wizard of Wor Lab.
--
-- The resident Lua supervisor owns lifecycle and module loading.  This native
-- controller owns cabinet input, menu selection, frame cadence, display calls,
-- and the request mailbox while the lab menu is active.

local Native = {}
Native.__index = Native
Native.VERSION = '1.0.8-20260816-1847'

local C = {
  PRINT_STRING_COLOR  = 0x03B5,
  SOUND_SERVICE       = 0x8000,
  SOUND_RESET         = 0x8006,

  COINPORT            = 0x10,
  P2PORT              = 0x11,
  P1PORT              = 0x12,
  INFBK               = 0x0D,
  INMOD               = 0x0E,
  INLIN               = 0x0F,

  SOUND_ENABLED       = 0xD244,
  SPEECH_ACTIVE       = 0xD245,
  SPEECH_QUEUE_BUFFER = 0xD2BE,
  SPEECH_REMAINING    = 0xD2D0,
  SPEECH_INFLECTION   = 0xD2D1,
  QUEUE_WRITE         = 0xD2D2,
  QUEUE_READ          = 0xD2D4,
  GAME_MODE           = 0xD303,
  DUNGEON_CLASS       = 0xD350,

  XPAND_BLUE          = 0x04,
  XPAND_YELLOW        = 0x08,
  XPAND_RED           = 0x0C,

  REPEAT_INITIAL      = 15,
  REPEAT_RATE         = 4,
}

-- Small label-aware emitter keeps the injected controller readable and
-- symbolic without requiring an assembler at runtime.
local function assembler(origin)
  local a = { origin = origin, bytes = {}, labels = {}, fixups = {} }

  function a:pc() return self.origin + #self.bytes end
  function a:b(v) self.bytes[#self.bytes + 1] = v & 0xFF end
  function a:w(v) self:b(v); self:b(v >> 8) end
  function a:label(name) self.labels[name] = self:pc() end
  function a:word(target)
    if type(target) == 'number' then
      self:w(target)
    else
      local pos = #self.bytes + 1
      self:w(0)
      self.fixups[#self.fixups + 1] = { kind = 'abs', pos = pos, target = target }
    end
  end
  function a:abs(opcode, target)
    self:b(opcode)
    self:word(target)
  end
  function a:jr(opcode, target)
    self:b(opcode)
    local pos = #self.bytes + 1
    self:b(0)
    self.fixups[#self.fixups + 1] = { kind = 'rel', pos = pos, target = target }
  end
  function a:finish()
    for _, f in ipairs(self.fixups) do
      local target = assert(self.labels[f.target], 'undefined native label: ' .. f.target)
      if f.kind == 'abs' then
        self.bytes[f.pos] = target & 0xFF
        self.bytes[f.pos + 1] = (target >> 8) & 0xFF
      else
        local operand_address = self.origin + f.pos - 1
        local displacement = target - (operand_address + 1)
        assert(displacement >= -128 and displacement <= 127,
          'JR target out of range: ' .. f.target)
        self.bytes[f.pos] = displacement & 0xFF
      end
    end
    return self.bytes, self.labels
  end

  return a
end

local function emit_ld_mem_a(a, address) a:b(0x32); a:w(address) end
local function emit_ld_a_mem(a, address) a:b(0x3A); a:w(address) end
local function emit_ld_mem_hl(a, address) a:b(0x22); a:w(address) end
local function emit_call(a, target) a:abs(0xCD, target) end
local function emit_jp(a, target) a:abs(0xC3, target) end

function Native.new(machine, memory)
  local cpu = assert(machine.devices[':maincpu'], 'main CPU :maincpu was not found')
  local program = assert(cpu.spaces['program'], 'main CPU program space was not found')

  return setmetatable({
    machine = machine,
    cpu = cpu,
    program = program,
    memory = memory,
    labels = {},
    installed = false,
  }, Native)
end

function Native:_build_controller()
  local A = self.memory.addr
  local B = self.memory.abi
  local a = assembler(A.MENU_CODE_START)

  a:label('entry')
  a:b(0xF3)                                      -- DI
  a:b(0x31); a:w(A.STACK_TOP)                    -- LD SP,$8000

  -- Clear the visible bitmap.
  a:b(0xAF)                                      -- XOR A
  a:b(0x21); a:w(A.VIDEO_START)                  -- LD HL,$4000
  a:b(0x11); a:w(A.VIDEO_START + 1)              -- LD DE,$4001
  a:b(0x01); a:w(A.VISIBLE_VIDEO_END - A.VIDEO_START) -- preserve $7FC0-$7FFF stack margin
  a:b(0x77)                                      -- LD (HL),A
  a:b(0xED); a:b(0xB0)                           -- LDIR

  -- Install the lab IM 2 vector and board interrupt mode.
  a:b(0x21); a:word('interrupt')                  -- LD HL,interrupt
  emit_ld_mem_hl(a, A.IM2_VECTOR)
  a:b(0x3E); a:b(0xD3)                           -- LD A,$D3
  a:b(0xED); a:b(0x47)                           -- LD I,A
  a:b(0xED); a:b(0x5E)                           -- IM 2
  a:b(0x3E); a:b(0xCA); a:b(0xD3); a:b(C.INFBK) -- OUT ($0D),A
  a:b(0x3E); a:b(0xA8); a:b(0xD3); a:b(C.INLIN) -- OUT ($0F),A
  a:b(0x3E); a:b(0x08); a:b(0xD3); a:b(C.INMOD) -- OUT ($0E),A

  -- Put resident sound/speech services in a defined idle state.  An invalid
  -- queue write pointer deliberately selects WoW's validation/reset path.
  a:b(0xAF)                                      -- XOR A
  emit_ld_mem_a(a, C.SPEECH_ACTIVE)
  emit_ld_mem_a(a, C.SPEECH_REMAINING)
  emit_ld_mem_a(a, C.SPEECH_INFLECTION)
  a:b(0x67); a:b(0x6F)                           -- LD H,A / LD L,A
  emit_ld_mem_hl(a, C.QUEUE_WRITE)
  a:b(0x21); a:w(C.SPEECH_QUEUE_BUFFER)
  emit_ld_mem_hl(a, C.QUEUE_READ)
  emit_call(a, C.SOUND_RESET)
  a:b(0x3E); a:b(0x01)
  emit_ld_mem_a(a, C.SOUND_ENABLED)
  emit_ld_mem_a(a, C.GAME_MODE)
  a:b(0xAF); emit_ld_mem_a(a, C.DUNGEON_CLASS)

  -- Reset supervisor input/request state but preserve Lua-supplied menu count.
  a:b(0xAF)
  for _, address in ipairs({
    B.REQUEST, B.HEARTBEAT, B.INPUT_CURRENT,
    B.INPUT_PRESSED, B.INPUT_LAST, B.START_LAST, B.HOLD_DIRECTION,
    B.HOLD_COUNTDOWN, B.MODULE_EVENT, B.MODULE_ARG0, B.MODULE_ARG1,
    B.MODULE_ARG2, B.MODULE_ARG3,
  }) do emit_ld_mem_a(a, address) end

  -- Prime edge-detection state from the cabinet before accepting input.
  -- Controls held during takeover are ignored until released and pressed again.
  emit_call(a, 'prime_controls')

  a:label('main')
  a:b(0xFB)                                      -- EI
  a:b(0x76)                                      -- HALT
  emit_call(a, 'service_draw')
  emit_call(a, 'read_controls')
  emit_jp(a, 'main')

  -- IM 2 frame service.  The ROM sound service remains the clock source for
  -- speech and music used by lab modules.
  a:label('interrupt')
  for _, op in ipairs({0xF5,0xC5,0xD5,0xE5,0xDD,0xE5,0xFD,0xE5}) do a:b(op) end
  a:b(0x08); a:b(0xF5); a:b(0xD9)
  a:b(0xC5); a:b(0xD5); a:b(0xE5)
  emit_call(a, C.SOUND_SERVICE)
  a:b(0x21); a:w(B.HEARTBEAT); a:b(0x34)        -- INC (HL)
  a:b(0xE1); a:b(0xD1); a:b(0xC1); a:b(0xD9)
  a:b(0xF1); a:b(0x08)
  for _, op in ipairs({0xFD,0xE1,0xDD,0xE1,0xE1,0xD1,0xC1,0xF1}) do a:b(op) end
  a:b(0xFB); a:b(0xC9)                           -- EI / RET

  a:label('service_draw')
  emit_ld_a_mem(a, B.DRAW_PENDING)
  a:b(0xB7)                                      -- OR A
  a:b(0xC8)                                      -- RET Z
  a:b(0xAF); emit_ld_mem_a(a, B.DRAW_PENDING)
  emit_call(a, A.DRAW_CODE_START)
  a:b(0xC9)

  a:label('prime_controls')
  a:b(0xDB); a:b(C.P1PORT); a:b(0x2F); a:b(0xE6); a:b(0x3F); a:b(0x47) -- B=P1
  a:b(0xDB); a:b(C.P2PORT); a:b(0x2F); a:b(0xE6); a:b(0x3F); a:b(0xB0) -- OR B
  emit_ld_mem_a(a, B.INPUT_CURRENT)
  emit_ld_mem_a(a, B.INPUT_LAST)
  a:b(0xAF); emit_ld_mem_a(a, B.INPUT_PRESSED)
  a:b(0xDB); a:b(C.COINPORT); a:b(0x2F); a:b(0xE6); a:b(0x60)
  emit_ld_mem_a(a, B.START_LAST)
  a:b(0xC9)                                      -- RET

  a:label('read_controls')
  a:b(0xDB); a:b(C.P1PORT); a:b(0x2F); a:b(0xE6); a:b(0x3F); a:b(0x47) -- B=P1
  a:b(0xDB); a:b(C.P2PORT); a:b(0x2F); a:b(0xE6); a:b(0x3F); a:b(0xB0) -- OR B
  a:b(0x47)                                      -- LD B,A
  emit_ld_mem_a(a, B.INPUT_CURRENT)
  emit_ld_a_mem(a, B.INPUT_LAST); a:b(0x2F); a:b(0xA0); a:b(0x4F)     -- C=new presses
  emit_ld_mem_a(a, B.INPUT_PRESSED)
  a:b(0x78); emit_ld_mem_a(a, B.INPUT_LAST)

  -- Start buttons are edge detected separately from joystick/fire.
  a:b(0xDB); a:b(C.COINPORT); a:b(0x2F); a:b(0xE6); a:b(0x60); a:b(0x47)
  emit_ld_a_mem(a, B.START_LAST); a:b(0x2F); a:b(0xA0); a:b(0x57)     -- D=new starts
  a:b(0x78); emit_ld_mem_a(a, B.START_LAST)

  emit_ld_a_mem(a, B.MODE); a:b(0xB7)
  a:jr(0x20, 'module_controls')                  -- JR NZ,module_controls

  -- Menu mode: 1P exits immediately.  When modules are present, vertical
  -- movement selects a discovered module and FIRE launches it.
  a:b(0x7A); a:b(0xE6); a:b(0x20)                 -- A=new starts & 1P
  a:jr(0x20, 'request_exit')                       -- JR NZ,request_exit
  emit_ld_a_mem(a, B.ITEM_COUNT); a:b(0xB7); a:b(0xC8) -- no modules: RET Z
  emit_call(a, 'vertical')
  emit_ld_a_mem(a, B.INPUT_PRESSED); a:b(0xE6); a:b(0x30); a:b(0xC8) -- RET Z
  a:b(0x3E); a:b(0x01); emit_ld_mem_a(a, B.REQUEST); a:b(0xC9)

  a:label('request_exit')
  a:b(0x3E); a:b(0x03); emit_ld_mem_a(a, B.REQUEST); a:b(0xC9)

  a:label('module_controls')
  a:b(0x7A); a:b(0xE6); a:b(0x20); a:b(0xC8)    -- 1P Start only; RET Z
  a:b(0x3E); a:b(0x02); emit_ld_mem_a(a, B.REQUEST); a:b(0xC9)

  a:label('vertical')
  emit_ld_a_mem(a, B.INPUT_CURRENT); a:b(0xE6); a:b(0x03)
  a:jr(0x28, 'vertical_release')                 -- JR Z
  a:b(0xFE); a:b(0x03); a:jr(0x28, 'vertical_release')
  a:b(0x47)                                      -- B=direction
  emit_ld_a_mem(a, B.HOLD_DIRECTION); a:b(0xB8) -- CP B
  a:jr(0x20, 'vertical_new')
  a:b(0x21); a:w(B.HOLD_COUNTDOWN); a:b(0x35)   -- DEC (HL)
  a:b(0xC0)                                      -- RET NZ
  a:b(0x36); a:b(C.REPEAT_RATE)                  -- LD (HL),rate
  a:jr(0x18, 'vertical_move')

  a:label('vertical_new')
  a:b(0x78); emit_ld_mem_a(a, B.HOLD_DIRECTION)
  a:b(0x3E); a:b(C.REPEAT_INITIAL); emit_ld_mem_a(a, B.HOLD_COUNTDOWN)

  a:label('vertical_move')
  a:b(0xCB); a:b(0x40)                           -- BIT 0,B
  a:jr(0x20, 'move_up')
  emit_jp(a, 'move_down')

  a:label('vertical_release')
  a:b(0xAF); emit_ld_mem_a(a, B.HOLD_DIRECTION); emit_ld_mem_a(a, B.HOLD_COUNTDOWN)
  a:b(0xC9)

  a:label('move_down')
  emit_ld_a_mem(a, B.SELECTED); a:b(0x3C)        -- INC A
  a:b(0x47)                                      -- B=candidate
  emit_ld_a_mem(a, B.ITEM_COUNT); a:b(0xB8)      -- CP B
  a:jr(0x28, 'move_down_wrap')                   -- candidate == count
  a:jr(0x30, 'store_b')                          -- candidate < count
  a:label('move_down_wrap')
  a:b(0x06); a:b(0x00)                           -- LD B,0
  a:jr(0x18, 'store_b')

  a:label('move_up')
  emit_ld_a_mem(a, B.SELECTED); a:b(0xB7)
  a:jr(0x20, 'move_up_dec')
  emit_ld_a_mem(a, B.ITEM_COUNT); a:b(0x3D); a:b(0x47)
  a:jr(0x18, 'store_b')
  a:label('move_up_dec')
  a:b(0x3D); a:b(0x47)

  a:label('store_b')
  a:b(0x78); emit_ld_mem_a(a, B.SELECTED); a:b(0xC9)

  local bytes, labels = a:finish()

  assert(A.MENU_CODE_START + #bytes - 1 <= A.MENU_CODE_END,
    string.format('native menu controller exceeds reserved range: %d bytes', #bytes))

  return bytes, labels
end

function Native:install(item_count)
  local A = self.memory.addr
  local B = self.memory.abi
  local p = self.program

  local bytes, labels = self:_build_controller()
  self.memory.fill(p, A.ABI_START, A.ABI_END, 0)
  self.memory.write_bytes(p, B.SIGNATURE, { string.byte('W'), string.byte('L'), string.byte('A'), string.byte('B') })
  p:write_u8(B.MODE, 0)
  p:write_u8(B.SELECTED, 0)
  p:write_u8(B.ITEM_COUNT, item_count & 0xFF)
  p:write_u8(B.REQUEST, 0)
  self.memory.write_bytes(p, A.MENU_CODE_START, bytes)

  self.labels = labels
  self.installed = true

  if self.cpu.state['SP'] then self.cpu.state['SP'].value = A.STACK_TOP end
  if self.cpu.state['HALT'] then self.cpu.state['HALT'].value = 0 end
  self.cpu.state['PC'].value = labels.entry
end

function Native:set_mode(mode)
  self.program:write_u8(self.memory.abi.MODE, mode & 0xFF)
  self.program:write_u8(self.memory.abi.REQUEST, 0)
end

function Native:set_item_count(count)
  self.program:write_u8(self.memory.abi.ITEM_COUNT, count & 0xFF)
  local selected = self:selected()
  if selected >= count then self.program:write_u8(self.memory.abi.SELECTED, math.max(0, count - 1)) end
end

function Native:selected() return self.program:read_u8(self.memory.abi.SELECTED) end
function Native:request() return self.program:read_u8(self.memory.abi.REQUEST) end
function Native:clear_request() self.program:write_u8(self.memory.abi.REQUEST, 0) end

local function transliterate_for_wow(text)
  local s = tostring(text or '')
  local replacements = {
    ['Ä']='AE', ['Ö']='OE', ['Ü']='UE', ['ẞ']='SS',
    ['ä']='AE', ['ö']='OE', ['ü']='UE', ['ß']='SS',
  }
  for from, to in pairs(replacements) do s = s:gsub(from, to) end
  s = s:upper()

  local out = {}
  for i = 1, #s do
    local ch = s:sub(i, i)
    local byte = ch:byte()
    if (byte >= 0x30 and byte <= 0x39) or (byte >= 0x41 and byte <= 0x5A) then
      out[#out + 1] = ch
    elseif ch == ' ' then
      out[#out + 1] = '@'                    -- resident CHRTBL blank glyph
    elseif ch == '-' then
      out[#out + 1] = '_'                    -- resident CHRTBL dash glyph
    elseif ch == "'" then
      out[#out + 1] = '`'                    -- resident CHRTBL apostrophe glyph
    elseif ch == '>' then
      out[#out + 1] = 'a'                    -- resident CHRTBL right-arrow glyph
    elseif ch == ']' then
      out[#out + 1] = ']'                    -- resident CHRTBL up-arrow glyph
    elseif ch == '^' then
      out[#out + 1] = '^'                    -- resident CHRTBL down-arrow glyph
    else
      out[#out + 1] = '@'
    end
  end
  return table.concat(out)
end

local function native_text(text, width)
  local s = transliterate_for_wow(text)
  width = width or #s
  if #s > width then s = s:sub(1, width) end
  if #s < width then s = s .. string.rep('@', width - #s) end
  return s
end

local function screen_de(row, col)
  -- WoW native text coordinates advance by five in D per text row and two
  -- bytes in E per 8-pixel character column.
  return ((((row or 0) * 5) & 0xFF) << 8) | ((((col or 0) * 2) & 0xFF))
end

function Native:draw(lines, clear_screen)
  local A = self.memory.addr
  local p = self.program
  local data = A.UI_DATA_START
  local code = {}
  local function b(v) code[#code + 1] = v & 0xFF end
  local function w(v) b(v); b(v >> 8) end

  b(0xF3)                                         -- DI
  if clear_screen ~= false then
    b(0xAF)                                       -- XOR A
    b(0x21); w(A.VIDEO_START)
    b(0x11); w(A.VIDEO_START + 1)
    b(0x01); w(A.VISIBLE_VIDEO_END - A.VIDEO_START)
    b(0x77); b(0xED); b(0xB0)                    -- clear visible bitmap; preserve stack margin
  end

  for _, line in ipairs(lines) do
    local text = native_text(line.text, line.width)
    -- printstr uses DJNZ.  B=0 means 256 iterations, not an empty string, so
    -- blank logical lines must not call the ROM renderer.
    if #text > 0 then
      assert(#text <= 255, 'native UI line exceeds 255-character renderer limit')
      local address = data
      for i = 1, #text do
        p:write_u8(data, text:byte(i)); data = data + 1
      end

      assert(data - 1 <= A.UI_DATA_END, 'native UI text exceeds reserved buffer')

      b(0x21); w(address)                         -- LD HL,text
      b(0x11); w(screen_de(line.row, line.col))
      b(0x06); b(#text)                           -- LD B,length (1..255)
      b(0x3E); b(line.color or C.XPAND_RED)
      b(0xCD); w(C.PRINT_STRING_COLOR)
    end
  end

  b(0xFB); b(0xC9)                               -- EI / RET
  assert(A.DRAW_CODE_START + #code - 1 <= A.DRAW_CODE_END,
    'native draw program exceeds reserved range')
  self.memory.write_bytes(p, A.DRAW_CODE_START, code)
  p:write_u8(self.memory.abi.DRAW_PENDING, 1)
end

Native.colors = {
  BLUE = C.XPAND_BLUE,
  YELLOW = C.XPAND_YELLOW,
  RED = C.XPAND_RED,
}

return Native
