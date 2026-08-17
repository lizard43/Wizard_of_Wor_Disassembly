-- modules/sound_browser.lua
-- Wizard of Wor Lab native sound browser.
--
-- This module uses Wizard of Wor's resident sound request interface and ROM
-- sound engine.  Playback, selection, stop/replacement, request dispatch, and
-- Play All are executed by injected Z80 code.  Lua installs the native image,
-- prepares the text display list, exposes diagnostic console commands, captures
-- read-only execution evidence, and participates in the Lab application lifecycle.
-- Capture taps observe WoW engine RAM and Astrocade I/O; they never synthesize
-- sound, alter stream bytes, or post sound requests.
--
-- The Lab ABI and permanent IM2 kernel remain below $D400.  1P Return is
-- therefore supervisor-owned and remains available even while this module owns
-- the complete native application workspace.

local M = {}
M.VERSION = '1.1.8-20260817-1344'

local C = {
  SOUND_REQUEST_1          = 0xD240,
  SOUND_SERVICE_ENABLED    = 0xD244,
  PRIMARY_MODULATORS       = 0xD246,
  PRIMARY_ENGINE           = 0xD270,
  SECONDARY_MODULATORS     = 0xD282,
  SECONDARY_ENGINE         = 0xD2AC,

  SOUND_REQUEST_DISPATCH   = 0x8003,
  SOUND_RESET_ALL          = 0x8006,
  PRINT_STRING_COLOR       = 0x03B5,

  NATIVE_CODE              = 0xD400,
  DRAW_CODE                = 0xD740,
  STATE_BASE               = 0xD840,
  DRAW_DATA                = 0xD900,
  REQUEST_TABLE            = 0xDB00,
  STACK_TOP                = 0xDFE0,

  STATE_SELECTION          = 0xD840,
  STATE_ACTIVE             = 0xD841,
  STATE_MODE               = 0xD842,
  STATE_LAST_CONTROLS      = 0xD843,
  STATE_LAST_STARTS        = 0xD844,
  STATE_BATCH_NEXT         = 0xD845,
  STATE_BATCH_COMPLETED    = 0xD846,
  STATE_SOUND_TIMER        = 0xD847,
  STATE_GAP_TIMER          = 0xD848,
  STATE_UI_DIRTY           = 0xD849,
  STATE_UI_READY           = 0xD84A,
  STATE_MAILBOX_CMD        = 0xD84C,
  STATE_MAILBOX_ARG        = 0xD84D,
  STATE_PLAY_SEQ           = 0xD84E,
  STATE_STOP_SEQ           = 0xD84F,
  STATE_STOP_REASON        = 0xD850,
  STATE_STOP_INDEX         = 0xD851,
  STATE_BATCH_RESULT       = 0xD852,
  STATE_DISPATCH_COUNTDOWN = 0xD853,
  STATE_DISPATCH_PERIOD    = 0xD854,
  STATE_PLAY_BEGIN_SEQ     = 0xD855,

  P1PORT                   = 0x12,
  P2PORT                   = 0x11,
  COINPORT                 = 0x10,

  XPAND_BLUE               = 0x04,
  XPAND_YELLOW             = 0x08,
  XPAND_RED                = 0x0C,

  UI_ROWS                  = 7,
  DISPATCH_PERIOD_WOW      = 4,
  DISPATCH_PERIOD_FAST     = 1,

  ASTROCADE_CLOCK_HZ       = 1789772.625,
  CAPTURE_MAX_BUS_EVENTS   = 24000,
  CAPTURE_MAX_ENGINE_WRITES= 48000,
  CAPTURE_MAX_SAMPLES      = 6000,
  CAPTURE_MAX_STEPS        = 6000,
  STREAM_MAX_COMMANDS      = 4096,
  STREAM_MAX_VISITS        = 8,
}

-- The 24 audible request selectors established by WoW's resident request
-- decoders. Event names follow static gameplay producers where proven; the few
-- remaining generic entries are left generic rather than named from sound alone.
local CATALOG = {
  { group=1, bit=0, priority=0, primary=0x89BE, secondary=0x89E5, name='WORLORD DUNGEON CUE' },
  { group=1, bit=1, priority=0, primary=0x89A0, secondary=0x89AF, name='GLOBAL EVENT 1' },
  { group=1, bit=2, priority=0, primary=0x8741, secondary=0x8772, name='RADAR CUE' },
  { group=1, bit=3, priority=0, primary=0x8981, secondary=nil,    name='ATTRACT EVENT 3' },
  { group=1, bit=4, priority=0, primary=0x8A0C, secondary=0x8A27, name='ROUND START CUE' },
  { group=1, bit=5, priority=0, primary=0x8971, secondary=nil,    name='COIN UP' },
  { group=2, bit=0, priority=1, primary=nil,    secondary=0x8928, name='PLAYER DEATH' },
  { group=2, bit=1, priority=0, primary=nil,    secondary=0x887B, name='PLAYER FIRE' },
  { group=2, bit=2, priority=1, primary=nil,    secondary=0x87EA, name='WORLUK PROXIMITY' },
  { group=2, bit=3, priority=0, primary=nil,    secondary=0x883B, name='THORWOR VISIBLE' },
  { group=2, bit=4, priority=0, primary=nil,    secondary=0x8825, name='GARWOR VISIBLE' },
  { group=2, bit=6, priority=0, primary=nil,    secondary=0x8988, name='PLAYER INPUT STATE' },
  { group=2, bit=7, priority=1, primary=0x8741, secondary=nil,    name='DUNGEON INTRO PRIMARY' },
  { group=3, bit=0, priority=1, primary=0x8AA1, secondary=0x8ADD, name='WORLUK DEATH' },
  { group=3, bit=1, priority=0, primary=nil,    secondary=0x890E, name='MONSTER DEATH' },
  { group=3, bit=2, priority=0, primary=nil,    secondary=0x8851, name='MONSTER FIRE' },
  { group=3, bit=3, priority=0, primary=nil,    secondary=0x8851, name='MONSTER FIRE ALT' },
  { group=3, bit=4, priority=0, primary=nil,    secondary=0x8A42, name='MAGIC DOOR TRANSIT' },
  { group=3, bit=5, priority=1, primary=0x8A81, secondary=0x8A6C, name='WORLUK ESCAPE' },
  { group=3, bit=7, priority=1, primary=0x877B, secondary=nil,    name='WORLUK ENTRY' },
  { group=4, bit=0, priority=2, primary=0x88E2, secondary=0x8905, name='WIZARD DEATH' },
  { group=4, bit=1, priority=1, primary=0x8AF6, secondary=0x8B1F, name='WIZARD APPEAR' },
  { group=4, bit=2, priority=1, primary=nil,    secondary=0x8AF3, name='WIZARD FIRE' },
  { group=4, bit=3, priority=1, primary=0x8B2E, secondary=0x8B5D, name='WORLUK ESCAPED' },
}

-- Two bytes per catalog entry: request-byte offset from $D240 and request mask.
local REQUEST_TABLE = {
  0x00,0x01, 0x00,0x02, 0x00,0x04, 0x00,0x08, 0x00,0x10, 0x00,0x20,
  0x01,0x01, 0x01,0x02, 0x01,0x04, 0x01,0x08, 0x01,0x10, 0x01,0x40, 0x01,0x80,
  0x02,0x01, 0x02,0x02, 0x02,0x04, 0x02,0x08, 0x02,0x10, 0x02,0x20, 0x02,0x80,
  0x03,0x01, 0x03,0x02, 0x03,0x04, 0x03,0x08,
}

local S = {
  lab = nil,
  machine = nil,
  cpu = nil,
  program = nil,
  io_space = nil,
  screen = nil,
  active = false,
  window_first = 1,
  shortcuts = {},
  last_play_seq = 0,
  last_stop_seq = 0,
  last_mode = 0,
  last_batch_result = 0,
  controller_labels = {},
  step_logging = false,
  taps = {},
  capture = {
    available = false,
    error = nil,
    next_id = 1,
    active = nil,
    pending_stop = nil,
    completed = {},
    last_begin_sequence = 0,
    last_stop_sequence = 0,
  },
}

local function printf(fmt, ...)
  print(string.format(fmt, ...))
end

local function hex2(v) return string.format('$%02X', (v or 0) & 0xFF) end
local function hex4(v) return string.format('$%04X', (v or 0) & 0xFFFF) end

local REGISTER_NAMES = {
  'MASTER_OSCILLATOR', 'TONE_A', 'TONE_B', 'TONE_C',
  'VIBRATO', 'VOLUME_C_NOISE', 'VOLUME_AB', 'NOISE_VOLUME_MASK',
}

local function machine_seconds()
  if not S.machine then return 0 end
  local ok, value = pcall(function() return S.machine.time:as_double() end)
  return ok and tonumber(value) or 0
end

local function screen_number(name, fallback)
  if not S.screen then return fallback end

  local ok, member = pcall(function() return S.screen[name] end)
  if not ok then return fallback end

  if type(member) == 'function' then
    local called, value = pcall(member, S.screen)
    if not called then called, value = pcall(member) end
    if called then return tonumber(value) or fallback end
    return fallback
  end

  return tonumber(member) or fallback
end

local function frame_number()
  return screen_number('frame_number', 0)
end

local function current_pc()
  if not S.cpu or not S.cpu.state or not S.cpu.state['PC'] then return 0 end
  local ok, value = pcall(function() return S.cpu.state['PC'].value end)
  return ok and (tonumber(value) or 0) & 0xFFFF or 0
end

local function copy_array(values)
  local result = {}
  for i, value in ipairs(values or {}) do result[i] = value end
  return result
end

local function copy_map(values)
  local result = {}
  for key, value in pairs(values or {}) do result[key] = value end
  return result
end

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
      self.fixups[#self.fixups + 1] = { kind='abs', pos=pos, target=target }
    end
  end
  function a:abs(opcode, target) self:b(opcode); self:word(target) end
  function a:jr(opcode, target)
    self:b(opcode)
    local pos = #self.bytes + 1
    self:b(0)
    self.fixups[#self.fixups + 1] = { kind='rel', pos=pos, target=target }
  end
  function a:finish()
    for _, f in ipairs(self.fixups) do
      local target = assert(self.labels[f.target], 'undefined sound label: ' .. f.target)
      if f.kind == 'abs' then
        self.bytes[f.pos] = target & 0xFF
        self.bytes[f.pos + 1] = (target >> 8) & 0xFF
      else
        local operand_address = self.origin + f.pos - 1
        local displacement = target - (operand_address + 1)
        assert(displacement >= -128 and displacement <= 127,
          'sound JR target out of range: ' .. f.target)
        self.bytes[f.pos] = displacement & 0xFF
      end
    end
    return self.bytes, self.labels
  end
  return a
end

local function ld_mem_a(a, addr) a:b(0x32); a:w(addr) end
local function ld_a_mem(a, addr) a:b(0x3A); a:w(addr) end
local function call(a, target) a:abs(0xCD, target) end
local function jp(a, target) a:abs(0xC3, target) end

-- Native controller for WoW request browsing and playback.  1P Start is not
-- consumed by the application; the permanent Lab kernel owns 1P Return while
-- this image is active.  2P Start toggles native Play All.
local function build_controller()
  local a = assembler(C.NATIVE_CODE)

  a:label('Browser_Start')
  a:b(0xF3)                                      -- DI
  a:b(0x31); a:w(C.STACK_TOP)                    -- LD SP,$DFE0
  call(a, 'ClearRequests')
  a:b(0x3E); a:b(0x01); ld_mem_a(a, C.SOUND_SERVICE_ENABLED)
  call(a, C.SOUND_RESET_ALL)

  a:b(0xAF)
  for _, addr in ipairs({
    C.STATE_SELECTION, C.STATE_MODE, C.STATE_LAST_CONTROLS, C.STATE_LAST_STARTS,
    C.STATE_BATCH_NEXT, C.STATE_BATCH_COMPLETED, C.STATE_SOUND_TIMER,
    C.STATE_GAP_TIMER, C.STATE_UI_READY, C.STATE_MAILBOX_CMD,
    C.STATE_MAILBOX_ARG, C.STATE_PLAY_SEQ, C.STATE_STOP_SEQ,
    C.STATE_STOP_REASON, C.STATE_BATCH_RESULT, C.STATE_PLAY_BEGIN_SEQ,
  }) do ld_mem_a(a, addr) end
  a:b(0x3E); a:b(0xFF)
  ld_mem_a(a, C.STATE_ACTIVE)
  ld_mem_a(a, C.STATE_LAST_CONTROLS)
  a:b(0x3E); a:b(0x01); ld_mem_a(a, C.STATE_UI_DIRTY)
  a:b(0x3E); a:b(C.DISPATCH_PERIOD_WOW)
  ld_mem_a(a, C.STATE_DISPATCH_PERIOD)
  ld_mem_a(a, C.STATE_DISPATCH_COUNTDOWN)
  jp(a, 'Main_Loop')

  a:label('Main_Loop')
  a:b(0xFB); a:b(0x76); a:b(0xF3)               -- EI / HALT / DI
  call(a, 'ServiceSoundDispatch')
  call(a, 'ServiceMailbox')
  call(a, 'PollInputs')
  call(a, 'ServiceManual')
  call(a, 'ServicePlayAll')
  ld_a_mem(a, C.STATE_UI_READY); a:b(0xB7)
  a:jr(0x28, 'Main_Loop')
  a:b(0xAF); ld_mem_a(a, C.STATE_UI_READY)
  -- The UI is published only while both software sound engines are idle.
  a:b(0xFB); call(a, C.DRAW_CODE); a:b(0xF3)
  jp(a, 'Main_Loop')

  a:label('ServiceSoundDispatch')
  ld_a_mem(a, C.STATE_DISPATCH_COUNTDOWN); a:b(0xB7)
  a:jr(0x28, 'DispatchDue')
  a:b(0x3D); ld_mem_a(a, C.STATE_DISPATCH_COUNTDOWN); a:b(0xC0) -- DEC A / RET NZ
  a:label('DispatchDue')
  call(a, 'ResetDispatchCountdown')
  jp(a, C.SOUND_REQUEST_DISPATCH)

  a:label('ResetDispatchCountdown')
  ld_a_mem(a, C.STATE_DISPATCH_PERIOD); a:b(0xB7)
  a:jr(0x20, 'DispatchPeriodValid')
  a:b(0x3C); ld_mem_a(a, C.STATE_DISPATCH_PERIOD)
  a:label('DispatchPeriodValid')
  ld_mem_a(a, C.STATE_DISPATCH_COUNTDOWN); a:b(0xC9)

  a:label('ClearRequests')
  a:b(0xAF)
  for addr = C.SOUND_REQUEST_1, C.SOUND_REQUEST_1 + 3 do ld_mem_a(a, addr) end
  a:b(0xC9)

  a:label('ResetAll')
  call(a, 'ClearRequests'); call(a, C.SOUND_RESET_ALL); a:b(0xC9)

  a:label('MarkDirty')
  a:b(0x3E); a:b(0x01); ld_mem_a(a, C.STATE_UI_DIRTY); a:b(0xC9)

  a:label('PlaySelected')
  ld_a_mem(a, C.STATE_PLAY_BEGIN_SEQ); a:b(0x3C); ld_mem_a(a, C.STATE_PLAY_BEGIN_SEQ)
  call(a, 'ResetAll')
  ld_a_mem(a, C.STATE_SELECTION); a:b(0x87); a:b(0x5F); a:b(0x16); a:b(0x00) -- ADD A,A / E=A / D=0
  a:b(0x21); a:w(C.REQUEST_TABLE); a:b(0x19)      -- HL=table + DE
  a:b(0x4E); a:b(0x23); a:b(0x46)                -- C=(HL), INC HL, B=(HL)
  a:b(0x21); a:w(C.SOUND_REQUEST_1)
  a:b(0x59); a:b(0x16); a:b(0x00); a:b(0x19)    -- E=C / D=0 / ADD HL,DE
  a:b(0x70)                                      -- LD (HL),B
  call(a, C.SOUND_REQUEST_DISPATCH)
  call(a, 'ResetDispatchCountdown')
  ld_a_mem(a, C.STATE_SELECTION); ld_mem_a(a, C.STATE_ACTIVE)
  a:b(0xAF); ld_mem_a(a, C.STATE_SOUND_TIMER)
  ld_a_mem(a, C.STATE_PLAY_SEQ); a:b(0x3C); ld_mem_a(a, C.STATE_PLAY_SEQ)
  call(a, 'MarkDirty'); a:b(0xC9)

  a:label('RecordStop')
  ld_mem_a(a, C.STATE_STOP_REASON)
  ld_a_mem(a, C.STATE_STOP_SEQ); a:b(0x3C); ld_mem_a(a, C.STATE_STOP_SEQ); a:b(0xC9)

  a:label('StopCurrent')
  ld_a_mem(a, C.STATE_ACTIVE); a:b(0xFE); a:b(0xFF); a:b(0xC8)
  ld_mem_a(a, C.STATE_STOP_INDEX)
  call(a, 'ResetAll')
  a:b(0x3E); a:b(0x02); call(a, 'RecordStop')
  a:b(0x3E); a:b(0xFF); ld_mem_a(a, C.STATE_ACTIVE)
  call(a, 'MarkDirty'); a:b(0xC9)

  a:label('ManualFire')
  ld_a_mem(a, C.STATE_MODE); a:b(0xB7); a:abs(0xC2, 'BatchFire') -- JP NZ
  ld_a_mem(a, C.STATE_ACTIVE); a:b(0x47)
  ld_a_mem(a, C.STATE_SELECTION); a:b(0xB8)
  a:abs(0xCA, 'StopCurrent')                     -- JP Z
  a:b(0x78); a:b(0xFE); a:b(0xFF)
  a:jr(0x28, 'ManualPlay')
  ld_mem_a(a, C.STATE_STOP_INDEX)
  call(a, 'ResetAll')
  a:b(0x3E); a:b(0x03); call(a, 'RecordStop')
  a:label('ManualPlay')
  jp(a, 'PlaySelected')

  a:label('MoveUp')
  ld_a_mem(a, C.STATE_SELECTION); a:b(0xB7)
  a:jr(0x28, 'MoveUpWrap')
  a:b(0x3D); a:jr(0x18, 'MoveStore')
  a:label('MoveUpWrap')
  a:b(0x3E); a:b(0x17)
  a:label('MoveStore')
  ld_mem_a(a, C.STATE_SELECTION); jp(a, 'MarkDirty')

  a:label('MoveDown')
  ld_a_mem(a, C.STATE_SELECTION); a:b(0x3C); a:b(0xFE); a:b(0x18)
  a:jr(0x38, 'MoveDownStore')
  a:b(0xAF)
  a:label('MoveDownStore')
  ld_mem_a(a, C.STATE_SELECTION); jp(a, 'MarkDirty')

  a:label('PollInputs')
  a:b(0xDB); a:b(C.P1PORT); a:b(0x2F); a:b(0xE6); a:b(0x3F); a:b(0x47)
  a:b(0xDB); a:b(C.P2PORT); a:b(0x2F); a:b(0xE6); a:b(0x3F); a:b(0xB0); a:b(0x4F)
  ld_a_mem(a, C.STATE_LAST_CONTROLS); a:b(0x2F); a:b(0xA1); a:b(0x47)
  a:b(0x79); ld_mem_a(a, C.STATE_LAST_CONTROLS)
  ld_a_mem(a, C.STATE_MODE); a:b(0xB7)
  a:jr(0x20, 'PollBatchControls')
  a:b(0xCB); a:b(0x40); a:abs(0xC4, 'MoveUp')   -- CALL NZ
  a:b(0xCB); a:b(0x48); a:abs(0xC4, 'MoveDown')
  a:b(0x78); a:b(0xE6); a:b(0x30); a:abs(0xC4, 'ManualFire')
  a:jr(0x18, 'PollStarts')
  a:label('PollBatchControls')
  a:b(0x78); a:b(0xE6); a:b(0x30); a:abs(0xC4, 'BatchFire')

  a:label('PollStarts')
  a:b(0xDB); a:b(C.COINPORT); a:b(0x2F); a:b(0xE6); a:b(0x60); a:b(0x4F)
  ld_a_mem(a, C.STATE_LAST_STARTS); a:b(0x2F); a:b(0xA1); a:b(0x47)
  a:b(0x79); ld_mem_a(a, C.STATE_LAST_STARTS)
  -- 1P is intentionally ignored here.  The resident Lab kernel owns return.
  a:b(0xCB); a:b(0x70); a:abs(0xC4, 'TogglePlayAll') -- BIT 6,B / CALL NZ
  a:b(0xC9)

  a:label('ServiceMailbox')
  ld_a_mem(a, C.STATE_MAILBOX_CMD); a:b(0xB7); a:b(0xC8); a:b(0x47)
  a:b(0xAF); ld_mem_a(a, C.STATE_MAILBOX_CMD)
  a:b(0x78); a:b(0xFE); a:b(0x01)
  a:jr(0x20, 'MailStop')
  ld_a_mem(a, C.STATE_MAILBOX_ARG); a:b(0xFE); a:b(0x18); a:b(0xD0) -- RET NC
  ld_mem_a(a, C.STATE_SELECTION)
  call(a, 'MarkDirty'); jp(a, 'ManualFire')
  a:label('MailStop')
  a:b(0xFE); a:b(0x02); a:jr(0x20, 'MailToggle')
  ld_a_mem(a, C.STATE_MODE); a:b(0xB7); a:abs(0xC2, 'StopPlayAll'); jp(a, 'StopCurrent')
  a:label('MailToggle')
  a:b(0xFE); a:b(0x03); a:b(0xC0); jp(a, 'TogglePlayAll') -- RET NZ

  a:label('ServiceManual')
  ld_a_mem(a, C.STATE_MODE); a:b(0xB7); a:b(0xC0)
  ld_a_mem(a, C.STATE_ACTIVE); a:b(0xFE); a:b(0xFF); a:b(0xC8)
  ld_mem_a(a, C.STATE_STOP_INDEX)
  call(a, 'EnginesIdle'); a:b(0xB7); a:b(0xC8)
  a:b(0x3E); a:b(0x01); call(a, 'RecordStop')
  a:b(0x3E); a:b(0xFF); ld_mem_a(a, C.STATE_ACTIVE); jp(a, 'MarkDirty')

  a:label('TogglePlayAll')
  ld_a_mem(a, C.STATE_MODE); a:b(0xB7); a:abs(0xC2, 'StopPlayAll')
  call(a, 'ResetAll')
  a:b(0x3E); a:b(0x01); ld_mem_a(a, C.STATE_MODE)
  a:b(0xAF)
  for _, addr in ipairs({C.STATE_SELECTION,C.STATE_BATCH_NEXT,C.STATE_BATCH_COMPLETED,
      C.STATE_SOUND_TIMER,C.STATE_BATCH_RESULT}) do ld_mem_a(a, addr) end
  a:b(0x3E); a:b(0x01); ld_mem_a(a, C.STATE_GAP_TIMER)
  a:b(0x3E); a:b(0xFF); ld_mem_a(a, C.STATE_ACTIVE); jp(a, 'MarkDirty')

  a:label('StopPlayAll')
  ld_a_mem(a, C.STATE_ACTIVE); a:b(0xFE); a:b(0xFF)
  a:jr(0x28, 'StopAllNoRecordReset')
  ld_mem_a(a, C.STATE_STOP_INDEX)
  call(a, 'ResetAll')
  a:b(0x3E); a:b(0x05); call(a, 'RecordStop')
  a:jr(0x18, 'StopAllNoRecord')
  a:label('StopAllNoRecordReset')
  call(a, 'ResetAll')
  a:label('StopAllNoRecord')
  a:b(0xAF); ld_mem_a(a, C.STATE_MODE); ld_mem_a(a, C.STATE_GAP_TIMER)
  a:b(0x3E); a:b(0x02); ld_mem_a(a, C.STATE_BATCH_RESULT)
  a:b(0x3E); a:b(0xFF); ld_mem_a(a, C.STATE_ACTIVE); jp(a, 'MarkDirty')

  a:label('BatchFire')
  ld_a_mem(a, C.STATE_ACTIVE); a:b(0xFE); a:b(0xFF); a:b(0xC8)
  ld_mem_a(a, C.STATE_STOP_INDEX)
  call(a, 'ResetAll')
  a:b(0x3E); a:b(0x02); call(a, 'RecordStop')
  a:b(0x3E); a:b(0x02); jp(a, 'FinishBatch')

  a:label('FinishBatch')
  a:b(0x3E); a:b(0xFF); ld_mem_a(a, C.STATE_ACTIVE)
  ld_a_mem(a, C.STATE_BATCH_COMPLETED); a:b(0x3C); ld_mem_a(a, C.STATE_BATCH_COMPLETED)
  a:b(0x3E); a:b(0x2D); ld_mem_a(a, C.STATE_GAP_TIMER); jp(a, 'MarkDirty')

  a:label('ServicePlayAll')
  ld_a_mem(a, C.STATE_MODE); a:b(0xB7); a:b(0xC8)
  ld_a_mem(a, C.STATE_ACTIVE); a:b(0xFE); a:b(0xFF)
  a:jr(0x28, 'BatchNoActive')
  ld_mem_a(a, C.STATE_STOP_INDEX)
  ld_a_mem(a, C.STATE_SOUND_TIMER); a:b(0x3C); ld_mem_a(a, C.STATE_SOUND_TIMER)
  a:b(0xFE); a:b(0xF0); a:jr(0x30, 'BatchLimit') -- JR NC
  call(a, 'EnginesIdle'); a:b(0xB7); a:b(0xC8)
  a:b(0x3E); a:b(0x01); call(a, 'RecordStop'); jp(a, 'FinishBatch')
  a:label('BatchLimit')
  call(a, 'ResetAll'); a:b(0x3E); a:b(0x04); call(a, 'RecordStop'); jp(a, 'FinishBatch')
  a:label('BatchNoActive')
  ld_a_mem(a, C.STATE_GAP_TIMER); a:b(0xB7); a:jr(0x28, 'BatchStartNext')
  a:b(0x3D); ld_mem_a(a, C.STATE_GAP_TIMER); a:b(0xC9)
  a:label('BatchStartNext')
  ld_a_mem(a, C.STATE_BATCH_NEXT); a:b(0xFE); a:b(0x18); a:jr(0x30, 'BatchComplete')
  ld_mem_a(a, C.STATE_SELECTION); a:b(0x3C); ld_mem_a(a, C.STATE_BATCH_NEXT); jp(a, 'PlaySelected')
  a:label('BatchComplete')
  a:b(0xAF); ld_mem_a(a, C.STATE_MODE)
  a:b(0x3E); a:b(0x01); ld_mem_a(a, C.STATE_BATCH_RESULT); jp(a, 'MarkDirty')

  a:label('EnginesIdle')
  a:b(0xDD); a:b(0x21); a:w(C.PRIMARY_ENGINE)   -- LD IX,primary record
  a:b(0x21); a:w(C.PRIMARY_MODULATORS)
  call(a, 'EngineIdle'); a:b(0xB7); a:b(0xC8)
  a:b(0xDD); a:b(0x21); a:w(C.SECONDARY_ENGINE)
  a:b(0x21); a:w(C.SECONDARY_MODULATORS)
  jp(a, 'EngineIdle')

  a:label('EngineIdle')
  a:b(0xDD); a:b(0x7E); a:b(0x11); a:b(0xB7); a:jr(0x20, 'EngineNotIdle')
  a:b(0xDD); a:b(0x7E); a:b(0x0D); a:b(0xB7); a:jr(0x20, 'EngineNotIdle')
  a:b(0x06); a:b(0x06)                           -- LD B,6
  a:label('EngineModLoop')
  a:b(0x7E); a:b(0xB7); a:jr(0x20, 'EngineNotIdle')
  a:b(0x11); a:w(0x0007); a:b(0x19); a:b(0x10); -- LD DE,7 / ADD HL,DE / DJNZ
  local djnz_pos = #a.bytes + 1
  a:b(0x00)
  a.fixups[#a.fixups + 1] = { kind='rel', pos=djnz_pos, target='EngineModLoop' }
  a:b(0xDD); a:b(0x7E); a:b(0x05); a:b(0xB7); a:jr(0x20, 'EngineNotIdle')
  a:b(0xDD); a:b(0x7E); a:b(0x06); a:b(0xE6); a:b(0x0F); a:jr(0x20, 'EngineNotIdle')
  a:b(0xDD); a:b(0x7E); a:b(0x06); a:b(0xE6); a:b(0x20); a:jr(0x28, 'EngineIdleYes')
  a:b(0xDD); a:b(0x7E); a:b(0x04); a:b(0xE6); a:b(0xF0); a:jr(0x20, 'EngineNotIdle')
  a:label('EngineIdleYes')
  a:b(0x3E); a:b(0x01); a:b(0xC9)
  a:label('EngineNotIdle')
  a:b(0xAF); a:b(0xC9)

  local bytes, labels = a:finish()
  assert(C.NATIVE_CODE + #bytes <= C.DRAW_CODE,
    string.format('sound controller overlaps draw program: %d bytes', #bytes))
  return bytes, labels
end

local function entry_key(e)
  return string.format('R%dB%d', e.group, e.bit)
end

local function find_entry(arg)
  if type(arg) == 'number' then
    local index = math.floor(arg)
    return index, CATALOG[index]
  end
  if type(arg) == 'string' then
    local r, b = arg:upper():match('^R(%d)B(%d)$')
    if r and b then
      r, b = tonumber(r), tonumber(b)
      for i, e in ipairs(CATALOG) do
        if e.group == r and e.bit == b then return i, e end
      end
    end
  end
  return nil, nil
end

local function engine_state(base, modulators)
  local p = S.program
  local state = {
    pointer = p:read_u8(base + 1) | (p:read_u8(base + 2) << 8),
    priority = p:read_u8(base + 3),
    noise_mask = p:read_u8(base + 4),
    volume_ab = p:read_u8(base + 5),
    volume_cn = p:read_u8(base + 6),
    vibrato = p:read_u8(base + 7),
    tone_c = p:read_u8(base + 8),
    tone_b = p:read_u8(base + 9),
    tone_a = p:read_u8(base + 10),
    master = p:read_u8(base + 11),
    flag = p:read_u8(base + 12),
    wait = p:read_u8(base + 13),
    ready = p:read_u8(base + 17),
    modulators = 0,
  }
  for slot = 0, 5 do
    if p:read_u8(modulators + slot * 7) ~= 0 then state.modulators = state.modulators + 1 end
  end
  -- Audible register state is distinct from decode/wait/modulator activity.
  -- A WoW stream can finish processing while leaving a sustained sound latched.
  state.audible = state.volume_ab ~= 0
               or (state.volume_cn & 0x0F) ~= 0
               or ((state.volume_cn & 0x20) ~= 0 and (state.noise_mask & 0xF0) ~= 0)
  return state
end

local function engine_idle(state)
  return state.ready == 0 and state.wait == 0 and state.modulators == 0 and not state.audible
end

local function engines_idle()
  return engine_idle(engine_state(C.PRIMARY_ENGINE, C.PRIMARY_MODULATORS))
     and engine_idle(engine_state(C.SECONDARY_ENGINE, C.SECONDARY_MODULATORS))
end

local function engine_phase(state)
  if state.ready ~= 0 then return 'STREAM' end
  if state.wait ~= 0 then return 'WAIT' end
  if state.modulators ~= 0 or not engine_idle(state) then return 'MOD' end
  return 'IDLE'
end

local function visible_pointer(state)
  return engine_idle(state) and nil or state.pointer
end

local function encode_native(text)
  local s = tostring(text or ''):upper()
  local out = {}
  for i = 1, #s do
    local ch = s:sub(i, i)
    local byte = ch:byte()
    if (byte >= 0x30 and byte <= 0x39) or (byte >= 0x41 and byte <= 0x5A) then
      out[#out + 1] = ch
    elseif ch == ' ' then out[#out + 1] = '@'
    elseif ch == '-' then out[#out + 1] = '_'
    elseif ch == ']' or ch == '^' then out[#out + 1] = ch
    else out[#out + 1] = '@' end
  end
  return table.concat(out)
end

local function fixed_native_text(text, width)
  local s = encode_native(text)
  if #s > width then s = s:sub(1, width) end
  if #s < width then s = s .. string.rep('@', width - #s) end
  return s
end

local function center_native_text(text, width)
  width = width or 40
  local s = encode_native(text)
  if #s > width then s = s:sub(1, width) end
  local left = math.max(0, (width - #s) // 2)
  return string.rep('@', left) .. s .. string.rep('@', width - left - #s)
end

local function screen_de(row, col)
  return (((row * 5) & 0xFF) << 8) | ((col * 2) & 0xFF)
end

local function selected_index()
  return S.program:read_u8(C.STATE_SELECTION)
end

local function active_index()
  local n = S.program:read_u8(C.STATE_ACTIVE)
  return n == 0xFF and nil or n
end

local function update_window(selection)
  local first = S.window_first
  if selection + 1 < first then first = selection + 1 end
  if selection + 1 >= first + C.UI_ROWS then first = selection - C.UI_ROWS + 2 end
  local max_first = #CATALOG - C.UI_ROWS + 1
  if first < 1 then first = 1 end
  if first > max_first then first = max_first end
  S.window_first = first
end

local function native_status_line()
  local p = engine_state(C.PRIMARY_ENGINE, C.PRIMARY_MODULATORS)
  local s = engine_state(C.SECONDARY_ENGINE, C.SECONDARY_MODULATORS)
  local pp = visible_pointer(p)
  local sp = visible_pointer(s)
  return string.format('P %-6s %4s  S %-6s %4s',
    engine_phase(p), pp and string.format('%04X', pp) or '----',
    engine_phase(s), sp and string.format('%04X', sp) or '----')
end

local function native_menu_lines()
  local selection = selected_index()
  if selection >= #CATALOG then selection = 0 end
  update_window(selection)

  local major, minor, patch = M.VERSION:match('^(%d+)%.(%d+)%.(%d+)')
  local tag = major and ('V' .. major .. minor .. patch) or 'VER'
  local tag_col = 40 - #tag
  local lines = {
    { row=0, col=0,       text=fixed_native_text(' REQ   PSTR SSTR EVENT', tag_col), color=C.XPAND_BLUE },
    { row=0, col=tag_col, text=tag,                                                color=C.XPAND_YELLOW },
  }

  for row = 0, C.UI_ROWS - 1 do
    local index = S.window_first + row
    local entry = CATALOG[index]
    local marker = ((index - 1) == selection) and 'a' or '@' -- resident right arrow / blank
    local primary = entry and entry.primary and string.format('%04X', entry.primary) or '----'
    local secondary = entry and entry.secondary and string.format('%04X', entry.secondary) or '----'
    local text = entry and string.format('%-4s  %4s %4s %s',
      entry_key(entry), primary, secondary, entry.name) or ''
    lines[#lines + 1] = { row=1+row, col=1, text=fixed_native_text(text,39), color=C.XPAND_RED }
    lines[#lines + 1] = { row=1+row, col=0, text=marker, color=C.XPAND_YELLOW }
  end

  lines[#lines + 1] = { row=9, col=1, text=fixed_native_text(native_status_line(),39), color=C.XPAND_BLUE }

  local mode = S.program:read_u8(C.STATE_MODE)
  local active = active_index()
  local footer
  if mode ~= 0 then
    footer = '] ^ - FIRE STOP - 1P LAB - 2P STOP'
  elseif active ~= nil and active == selection then
    footer = '] ^ - FIRE STOP - 1P LAB - 2P ALL'
  else
    footer = '] ^ - FIRE PLAY - 1P LAB - 2P ALL'
  end
  lines[#lines + 1] = { row=11, col=1, text=encode_native(footer), color=C.XPAND_YELLOW }
  return lines
end

local function write_native_draw_program(lines)
  local data = C.DRAW_DATA
  local code = {}
  local function b(v) code[#code + 1] = v & 0xFF end
  local function w(v) b(v); b(v >> 8) end

  for _, line in ipairs(lines) do
    local text = line.text
    if #text > 0 then
      assert(#text <= 255, 'sound UI line exceeds renderer limit')
      local address = data
      for i = 1, #text do
        S.program:write_u8(data, text:byte(i)); data = data + 1
      end
      assert(data < C.REQUEST_TABLE, 'sound UI strings overlap request table')

      b(0x21); w(address)
      b(0x11); w(screen_de(line.row, line.col))
      b(0x06); b(#text)
      b(0x3E); b(line.color)
      b(0xCD); w(C.PRINT_STRING_COLOR)
    end
  end
  b(0xC9)

  assert(C.DRAW_CODE + #code <= C.STATE_BASE, 'sound UI program overlaps browser state')
  for i, byte in ipairs(code) do S.program:write_u8(C.DRAW_CODE + i - 1, byte) end
end

local function service_ui()
  if S.program:read_u8(C.STATE_UI_DIRTY) == 0 then return end
  if S.program:read_u8(C.STATE_UI_READY) ~= 0 then return end

  -- UI publication is independent of sound-engine activity.  The native
  -- UI_READY handshake ensures that Lua only rewrites the draw program while
  -- the Z80 controller is not executing it.  Keeping redraws available during
  -- playback makes selection changes and FIRE PLAY/STOP state visible
  -- immediately, matching the standalone native browser.
  write_native_draw_program(native_menu_lines())
  S.program:write_u8(C.STATE_UI_DIRTY, 0)
  S.program:write_u8(C.STATE_UI_READY, 1)
end

local STOP_REASON = {
  [1] = 'IDLE', [2] = 'FIRE STOP', [3] = 'NEW PLAY', [4] = 'PLAY ALL LIMIT', [5] = 'PLAY ALL STOP',
}

local ENGINE_FIELDS = {
  [0] = 'SOUND_PORT', [1] = 'STREAM_POINTER_LOW', [2] = 'STREAM_POINTER_HIGH',
  [3] = 'PRIORITY', [4] = 'NOISE_VOLUME_MASK', [5] = 'VOLUME_AB',
  [6] = 'VOLUME_C_NOISE', [7] = 'VIBRATO', [8] = 'TONE_C', [9] = 'TONE_B',
  [10] = 'TONE_A', [11] = 'MASTER_OSCILLATOR', [12] = 'ENGINE_FLAG',
  [13] = 'COUNTDOWN', [14] = 'ENGINE_BYTE_0E', [15] = 'ENGINE_BYTE_0F',
  [16] = 'ENGINE_BYTE_10', [17] = 'STREAM_READY',
}

local function engine_registers(state)
  return {
    state.master, state.tone_a, state.tone_b, state.tone_c,
    state.vibrato, state.volume_cn, state.volume_ab, state.noise_mask,
  }
end

local function register_decode(registers)
  local master = registers[1] or 0
  local function hz(divider)
    return C.ASTROCADE_CLOCK_HZ / (2 * (master + 1) * ((divider or 0) + 1))
  end
  local volc = registers[6] or 0
  local volab = registers[7] or 0
  local noise = registers[8] or 0
  return {
    master_divider = master,
    tone_a_hz = hz(registers[2]),
    tone_b_hz = hz(registers[3]),
    tone_c_hz = hz(registers[4]),
    vibrato = registers[5] or 0,
    volume_a = volab & 0x0F,
    volume_b = (volab >> 4) & 0x0F,
    volume_c = volc & 0x0F,
    noise_enabled = (volc & 0x20) ~= 0,
    noise_volume = (volc & 0x20) ~= 0 and ((noise >> 4) & 0x0F) or 0,
    noise_mask = noise,
  }
end

local function capture_engine_snapshot(base, modulators)
  local state = engine_state(base, modulators)
  local pointer = visible_pointer(state)
  local registers = engine_registers(state)
  return {
    phase = engine_phase(state),
    pointer = pointer,
    pointer_hex = pointer and hex4(pointer) or nil,
    saved_pointer = state.pointer,
    saved_pointer_hex = hex4(state.pointer),
    priority = state.priority,
    wait = state.wait,
    ready = state.ready,
    modulators = state.modulators,
    audible = state.audible,
    flag = state.flag,
    registers = registers,
    register_hex = {hex2(registers[1]), hex2(registers[2]), hex2(registers[3]), hex2(registers[4]),
                    hex2(registers[5]), hex2(registers[6]), hex2(registers[7]), hex2(registers[8])},
    decoded = register_decode(registers),
  }
end

local function capture_signature(primary, secondary)
  local function one(s)
    return table.concat({
      s.phase, tostring(s.pointer or -1), tostring(s.saved_pointer or -1), tostring(s.priority),
      tostring(s.wait), tostring(s.ready), tostring(s.modulators), tostring(s.flag),
      table.concat(s.registers, ','),
    }, ':')
  end
  return one(primary) .. '|' .. one(secondary)
end

local function capture_changes(previous, current, prefix)
  local changes = {}
  if not previous then return changes end
  if previous.phase ~= current.phase then changes[#changes + 1] = prefix .. ':PHASE=' .. current.phase end
  if previous.pointer ~= current.pointer then changes[#changes + 1] = prefix .. ':PTR=' .. (current.pointer and hex4(current.pointer) or '----') end
  if previous.priority ~= current.priority then changes[#changes + 1] = prefix .. ':PRI=' .. tostring(current.priority) end
  if previous.wait ~= current.wait then changes[#changes + 1] = prefix .. ':WAIT=' .. hex2(current.wait) end
  if previous.ready ~= current.ready then changes[#changes + 1] = prefix .. ':READY=' .. hex2(current.ready) end
  if previous.modulators ~= current.modulators then changes[#changes + 1] = prefix .. ':MODS=' .. tostring(current.modulators) end
  for i = 1, 8 do
    if previous.registers[i] ~= current.registers[i] then
      changes[#changes + 1] = string.format('%s:$%02X=%s', prefix, 0x0F + i, hex2(current.registers[i]))
    end
  end
  return changes
end

local function append_all(target, source)
  for _, value in ipairs(source or {}) do target[#target + 1] = value end
end

local function relative_context(segment)
  local now, frame = machine_seconds(), frame_number()
  return now, frame, math.max(0, now - segment.start_time_seconds), math.max(0, frame - segment.start_frame)
end

local function retain_event(segment, list_name, event, limit, dropped_name)
  local list = segment[list_name]
  if #list < limit then
    list[#list + 1] = event
    segment.retained_event_count = segment.retained_event_count + 1
    return true
  end
  segment.truncated = true
  segment.dropped_events[dropped_name] = (segment.dropped_events[dropped_name] or 0) + 1
  return false
end

local function decode_stream_command(address)
  local p = S.program
  local opcode = p:read_u8(address)
  local command = {
    address = address, address_hex = hex4(address), opcode = opcode, opcode_hex = hex2(opcode),
    length = 1, next_address = (address + 1) & 0xFFFF,
  }
  local next_address = command.next_address
  if opcode == 0x00 then
    command.kind, command.name, command.yields = 'YIELD', 'YIELD', true
  elseif opcode == 0x01 then
    command.kind, command.name, command.yields = 'WAIT', 'WAIT', true
    command.wait_ticks = p:read_u8(next_address)
    command.length = 2; next_address = (address + 2) & 0xFFFF
  elseif opcode == 0x02 then
    local lo, hi = p:read_u8(next_address), p:read_u8((next_address + 1) & 0xFFFF)
    command.kind, command.name = 'JUMP', 'JUMP'
    command.target = lo | (hi << 8); command.target_hex = hex4(command.target)
    command.length = 3; next_address = command.target
  elseif opcode == 0x03 then
    command.kind, command.name, command.terminal = 'RESET_ENGINE', 'RESET_ENGINE', true
  elseif opcode == 0x04 then
    command.kind, command.name = 'LOAD_MODULATOR', 'LOAD_MODULATOR'
    local lo, hi = p:read_u8(next_address), p:read_u8((next_address + 1) & 0xFFFF)
    command.record_offset = lo | (hi << 8)
    command.data = {}
    for i = 0, 5 do command.data[#command.data + 1] = p:read_u8((next_address + 2 + i) & 0xFFFF) end
    command.length = 9; next_address = (address + 9) & 0xFFFF
  elseif opcode == 0x05 then
    command.kind, command.name = 'SET_MODULATOR_COMPLETION', 'SET_MODULATOR_COMPLETION'
    command.record_offset = p:read_u8(next_address) | (p:read_u8((next_address + 1) & 0xFFFF) << 8)
    command.value = p:read_u8((next_address + 2) & 0xFFFF)
    command.length = 4; next_address = (address + 4) & 0xFFFF
  elseif opcode == 0x06 then
    command.kind, command.name = 'ENABLE_MODULATOR', 'ENABLE_MODULATOR'
    command.record_offset = p:read_u8(next_address) | (p:read_u8((next_address + 1) & 0xFFFF) << 8)
    command.countdown = p:read_u8((next_address + 2) & 0xFFFF)
    command.length = 4; next_address = (address + 4) & 0xFFFF
  elseif opcode == 0x07 then
    command.kind, command.name = 'DISABLE_MODULATOR', 'DISABLE_MODULATOR'
    command.record_offset = p:read_u8(next_address) | (p:read_u8((next_address + 1) & 0xFFFF) << 8)
    command.length = 3; next_address = (address + 3) & 0xFFFF
  elseif opcode == 0x08 then
    command.kind, command.name = 'SET_ENGINE_FLAG', 'SET_ENGINE_FLAG'
  elseif opcode == 0x09 then
    command.kind, command.name, command.priority = 'SET_PRIORITY', 'SET_PRIORITY', 1
  elseif opcode == 0x0A then
    command.kind, command.name, command.priority = 'SET_PRIORITY', 'SET_PRIORITY', 0
  elseif opcode >= 0x0B and opcode <= 0x0F then
    command.kind, command.name, command.yields = 'YIELD', 'YIELD', true
  elseif opcode >= 0x10 and opcode <= 0x17 then
    local register = opcode - 0x10
    command.kind, command.name = 'REGISTER_WRITE', REGISTER_NAMES[register + 1]
    command.register = register
    command.port = opcode
    command.port_hex = hex2(opcode)
    command.value = p:read_u8(next_address)
    command.value_hex = hex2(command.value)
    command.length = 2; next_address = (address + 2) & 0xFFFF
  else
    command.kind, command.name = 'INVALID', 'INVALID'
    command.fallback_address = 0x8740
    command.fallback_address_hex = '$8740'
    command.terminal = true
  end
  command.next_address = next_address
  command.next_address_hex = hex4(next_address)
  return command
end

local function decode_stream_program(entry_address)
  if not entry_address then return nil end
  local result = {
    entry_address = entry_address, entry_address_hex = hex4(entry_address),
    segments = {}, termination = nil, truncated = false,
  }
  local pc = entry_address
  local visits = {}
  local command_count = 0
  local segment_number = 0
  while command_count < C.STREAM_MAX_COMMANDS do
    segment_number = segment_number + 1
    local segment = { number=segment_number, start_address=pc, start_address_hex=hex4(pc), commands={} }
    result.segments[#result.segments + 1] = segment
    while command_count < C.STREAM_MAX_COMMANDS do
      visits[pc] = (visits[pc] or 0) + 1
      if visits[pc] > C.STREAM_MAX_VISITS then
        segment.termination, result.termination = 'LOOP_GUARD', 'LOOP_GUARD'
        result.truncated = true
        return result
      end
      local command = decode_stream_command(pc)
      command_count = command_count + 1
      segment.commands[#segment.commands + 1] = command
      if command.terminal then
        segment.termination = command.kind
        result.termination = command.kind
        return result
      end
      pc = command.next_address
      if command.yields then
        segment.termination = command.kind
        segment.resume_address = pc
        segment.resume_address_hex = hex4(pc)
        break
      end
    end
  end
  result.termination = 'COMMAND_LIMIT'
  result.truncated = true
  return result
end

local function build_stream_programs(entry)
  return {
    primary = entry.primary and decode_stream_program(entry.primary) or nil,
    secondary = entry.secondary and decode_stream_program(entry.secondary) or nil,
  }
end

local function compact_phase(state)
  if state.ready ~= 0 then return 'DECODE' end
  if state.wait ~= 0 then return 'WAIT' end
  if state.modulators ~= 0 then return 'MOD' .. tostring(state.modulators) end
  if state.audible then return 'LATCH' end
  return 'IDLE'
end

local function compact_pointer(state)
  if compact_phase(state) == 'IDLE' then return nil end
  return state.pointer or state.saved_pointer
end

local function compact_state_text(label, state)
  local phase = compact_phase(state)
  local pointer = compact_pointer(state)
  if pointer then return string.format('%s %s $%04X', label, phase, pointer & 0xFFFF) end
  return string.format('%s %s ----', label, phase)
end

local function compact_signature(primary, secondary)
  return string.format('%s:%04X|%s:%04X',
    compact_phase(primary), compact_pointer(primary) or 0,
    compact_phase(secondary), compact_pointer(secondary) or 0)
end

local function trace_compact_sample(segment, primary, secondary)
  if S.step_logging or not segment.compact_trace_started then return end
  local signature = compact_signature(primary, secondary)
  if signature == segment.compact_trace_signature then return end
  segment.compact_trace_signature = signature
  printf('[WOW SOUND] TRACE %s %s  %s', segment.request.key,
    compact_state_text('P', primary), compact_state_text('S', secondary))
end

local function trace_compact_start(segment)
  if S.step_logging or not segment or segment.compact_trace_started then return end
  segment.compact_trace_started = true
  printf('[WOW SOUND] TRACE %s START entry=P%s S%s', segment.request.key,
    segment.request.primary_entry and string.format('%04X', segment.request.primary_entry) or '----',
    segment.request.secondary_entry and string.format('%04X', segment.request.secondary_entry) or '----')
end

local function trace_compact_end(segment)
  if S.step_logging or not segment then return end
  printf('[WOW SOUND] TRACE %s END %s', segment.request.key, segment.end_reason or 'UNKNOWN')
end

local function trace_step(segment, step)
  if not S.step_logging then return end
  if not segment.trace_header_printed then
    printf('[WOW SOUND] TRACE %02d %s START P=%s S=%s dispatch=%d', segment.id,
      segment.request.key, segment.request.primary_entry_hex or '----',
      segment.request.secondary_entry_hex or '----', segment.dispatch_period_ticks)
    print('[WOW SOUND]        STEP  FRAME   TIME     PRIMARY                     SECONDARY                   CHANGES')
    segment.trace_header_printed = true
  end
  local function side(s)
    return string.format('%-6s %4s W%02X M%d', s.phase, s.pointer and string.format('%04X', s.pointer) or '----', s.wait, s.modulators)
  end
  local changes = #step.changes > 0 and table.concat(step.changes, ',') or '-'
  printf('[WOW SOUND]        %04d  +%04d  %7.3f  P %-25s S %-25s %s', step.number,
    step.elapsed_frames, step.elapsed_seconds, side(step.primary), side(step.secondary), changes)
end

local function capture_sample(segment, force)
  if not segment then return end
  local now, frame, elapsed, elapsed_frames = relative_context(segment)
  local primary = capture_engine_snapshot(C.PRIMARY_ENGINE, C.PRIMARY_MODULATORS)
  local secondary = capture_engine_snapshot(C.SECONDARY_ENGINE, C.SECONDARY_MODULATORS)
  local signature = capture_signature(primary, secondary)
  if not force and signature == segment.last_sample_signature then return end

  if #segment.engine_samples >= C.CAPTURE_MAX_SAMPLES then
    segment.truncated = true
    segment.dropped_events.engine_samples = (segment.dropped_events.engine_samples or 0) + 1
    return
  end
  local previous_sample = segment.engine_samples[#segment.engine_samples]
  local changes = {}
  if previous_sample then
    append_all(changes, capture_changes(previous_sample.primary, primary, 'P'))
    append_all(changes, capture_changes(previous_sample.secondary, secondary, 'S'))
  end
  local sample = {
    number = #segment.engine_samples + 1,
    time_seconds = now, frame = frame,
    elapsed_seconds = elapsed, elapsed_frames = elapsed_frames,
    primary = primary, secondary = secondary, changes = changes,
  }
  segment.engine_samples[#segment.engine_samples + 1] = sample
  segment.last_sample_signature = signature

  if #segment.steps < C.CAPTURE_MAX_STEPS then
    local previous_step = segment.steps[#segment.steps]
    if previous_step then
      previous_step.duration_seconds = math.max(0, now - previous_step.time_seconds)
      previous_step.duration_frames = math.max(0, frame - previous_step.frame)
    end
    local step = {
      number = #segment.steps + 1,
      time_seconds = now, frame = frame,
      elapsed_seconds = elapsed, elapsed_frames = elapsed_frames,
      primary = primary, secondary = secondary, changes = copy_array(changes),
    }
    segment.steps[#segment.steps + 1] = step
    trace_compact_sample(segment, primary, secondary)
    trace_step(segment, step)
  else
    segment.truncated = true
    segment.dropped_events.steps = (segment.dropped_events.steps or 0) + 1
  end
end

local function capture_finish_active(reason, reason_code)
  local segment = S.capture.active
  if not segment then return end
  capture_sample(segment, false)
  local now, frame = machine_seconds(), frame_number()
  local last_step = segment.steps[#segment.steps]
  if last_step then
    last_step.duration_seconds = math.max(0, now - last_step.time_seconds)
    last_step.duration_frames = math.max(0, frame - last_step.frame)
  end
  segment.status = 'complete'
  segment.end_time_seconds = now
  segment.end_frame = frame
  segment.duration_seconds = math.max(0, now - segment.start_time_seconds)
  segment.duration_frames = math.max(0, frame - segment.start_frame)
  segment.stop_reason_code = reason_code
  segment.end_reason = reason or 'UNKNOWN'
  segment.last_sample_signature = nil
  S.capture.completed[#S.capture.completed + 1] = segment
  S.capture.active = nil
  S.capture.pending_stop = nil
  if S.step_logging then
    printf('[WOW SOUND] TRACE %02d %s END %s duration=%.3fs steps=%d bus=%d engine=%d',
      segment.id, segment.request.key, segment.end_reason, segment.duration_seconds,
      #segment.steps, #segment.raw_bus_events, #segment.engine_write_events)
  else
    trace_compact_end(segment)
  end
end

local function capture_open(index, begin_sequence)
  local entry = CATALOG[(index or 0) + 1]
  if not entry then return end
  if S.capture.active then
    if S.capture.pending_stop then
      local pending = S.capture.pending_stop
      capture_finish_active(pending.reason, pending.reason_code)
    else
      capture_finish_active('NEW PLAY', nil)
    end
  end
  local now, frame = machine_seconds(), frame_number()
  local id = S.capture.next_id
  S.capture.next_id = id + 1
  S.capture.active = {
    id = id, status = 'active', begin_sequence = begin_sequence,
    request = {
      catalog_index = index + 1,
      key = entry_key(entry),
      name = entry.name,
      priority = entry.priority,
      request_address = C.SOUND_REQUEST_1 + entry.group - 1,
      request_address_hex = hex4(C.SOUND_REQUEST_1 + entry.group - 1),
      request_mask = 1 << entry.bit,
      request_mask_hex = hex2(1 << entry.bit),
      primary_entry = entry.primary,
      primary_entry_hex = entry.primary and hex4(entry.primary) or nil,
      secondary_entry = entry.secondary,
      secondary_entry_hex = entry.secondary and hex4(entry.secondary) or nil,
    },
    dispatch_period_ticks = S.program:read_u8(C.STATE_DISPATCH_PERIOD),
    start_time_seconds = now, start_frame = frame,
    raw_bus_events = {}, engine_write_events = {}, engine_samples = {}, steps = {},
    stream_programs = nil, stream_decode_pending = true,
    retained_event_count = 0, truncated = false, dropped_events = {},
    trace_header_printed = false, last_sample_signature = nil,
    compact_trace_started = false, compact_trace_signature = nil,
  }
end

local function observe_play_begin_sequence(offset, data, mask)
  if not S.active then return end
  local sequence = (tonumber(data) or 0) & 0xFF
  if sequence == S.capture.last_begin_sequence then return end
  S.capture.last_begin_sequence = sequence
  capture_open(selected_index(), sequence)
end

local function observe_stop_sequence(offset, data, mask)
  if not S.active then return end
  local sequence = (tonumber(data) or 0) & 0xFF
  if sequence == S.capture.last_stop_sequence then return end
  S.capture.last_stop_sequence = sequence
  local reason_code = S.program:read_u8(C.STATE_STOP_REASON)
  S.capture.pending_stop = {
    sequence = sequence,
    reason_code = reason_code,
    reason = STOP_REASON[reason_code] or 'UNKNOWN',
    stop_index = S.program:read_u8(C.STATE_STOP_INDEX),
  }
end

local function io_write_target(raw_address)
  local raw = (tonumber(raw_address) or 0) & 0xFFFF
  local port = raw & 0xFF
  if port >= 0x10 and port <= 0x17 then return 'PRIMARY', port - 0x10, port, false end
  if port == 0x18 then return 'PRIMARY', (raw >> 8) & 0x07, port, true end
  if port >= 0x50 and port <= 0x57 then return 'SECONDARY', port - 0x50, port, false end
  if port == 0x58 then return 'SECONDARY', (raw >> 8) & 0x07, port, true end
  return nil
end

local function observe_astrocade_write(offset, data, mask)
  local segment = S.capture.active
  if not segment then return end
  local chip, register, port, block = io_write_target(offset)
  if not chip then return end
  local now, frame, elapsed, elapsed_frames = relative_context(segment)
  local event = {
    number = #segment.raw_bus_events + 1,
    time_seconds = now, frame = frame, elapsed_seconds = elapsed, elapsed_frames = elapsed_frames,
    pc = current_pc(), pc_hex = hex4(current_pc()),
    raw_address = (tonumber(offset) or 0) & 0xFFFF, raw_address_hex = hex4(offset),
    port = port, port_hex = hex2(port), chip = chip,
    register = register, register_name = REGISTER_NAMES[register + 1],
    data = (tonumber(data) or 0) & 0xFF, data_hex = hex2(data),
    block_transfer = block,
  }
  retain_event(segment, 'raw_bus_events', event, C.CAPTURE_MAX_BUS_EVENTS, 'raw_bus_events')
end

local function engine_address_info(address)
  local addr = (tonumber(address) or 0) & 0xFFFF
  local function within(mod_base, record_base, chip)
    if addr >= mod_base and addr < record_base then
      local relative = addr - mod_base
      return chip, 'MODULATOR', math.floor(relative / 7), 'MODULATOR_BYTE_' .. tostring(relative % 7)
    end
    if addr >= record_base and addr <= record_base + 17 then
      local relative = addr - record_base
      return chip, 'ENGINE_RECORD', nil, ENGINE_FIELDS[relative] or ('ENGINE_BYTE_' .. string.format('%02X', relative))
    end
  end
  local a,b,c,d = within(C.PRIMARY_MODULATORS, C.PRIMARY_ENGINE, 'PRIMARY')
  if a then return a,b,c,d end
  return within(C.SECONDARY_MODULATORS, C.SECONDARY_ENGINE, 'SECONDARY')
end

local function source_from_pc(pc)
  if pc >= 0x8316 and pc <= 0x846F then return 'STREAM' end
  if pc >= 0x8000 and pc <= 0x86FF then return 'SOUND_SERVICE' end
  return 'OTHER'
end

local function observe_engine_write(offset, data, mask)
  local segment = S.capture.active
  if not segment then return end
  local chip, area, slot, field = engine_address_info(offset)
  if not chip then return end
  local now, frame, elapsed, elapsed_frames = relative_context(segment)
  local pc = current_pc()
  local event = {
    number = #segment.engine_write_events + 1,
    time_seconds = now, frame = frame, elapsed_seconds = elapsed, elapsed_frames = elapsed_frames,
    pc = pc, pc_hex = hex4(pc), source = source_from_pc(pc),
    address = (tonumber(offset) or 0) & 0xFFFF, address_hex = hex4(offset),
    chip = chip, area = area, slot = slot, field = field,
    data = (tonumber(data) or 0) & 0xFF, data_hex = hex2(data),
    mask = (tonumber(mask) or 0xFF) & 0xFF,
  }
  retain_event(segment, 'engine_write_events', event, C.CAPTURE_MAX_ENGINE_WRITES, 'engine_write_events')
end

local function remove_capture_taps()
  for _, tap in pairs(S.taps) do
    if tap then pcall(function() tap:remove() end) end
  end
  S.taps = {}
  S.capture.available = false
end

local function install_capture_taps()
  remove_capture_taps()
  if not S.io_space or not S.program then
    S.capture.error = 'MAME address spaces unavailable'
    return false, S.capture.error
  end
  local ok, err = pcall(function()
    S.taps.io = S.io_space:install_write_tap(0, S.io_space.address_mask,
      'wow_lab_sound_astrocade_writes', observe_astrocade_write)
    S.taps.engine = S.program:install_write_tap(C.PRIMARY_MODULATORS, C.SECONDARY_ENGINE + 17,
      'wow_lab_sound_engine_writes', observe_engine_write)
    S.taps.play = S.program:install_write_tap(C.STATE_PLAY_BEGIN_SEQ, C.STATE_PLAY_BEGIN_SEQ,
      'wow_lab_sound_play_begin', observe_play_begin_sequence)
    S.taps.stop = S.program:install_write_tap(C.STATE_STOP_SEQ, C.STATE_STOP_SEQ,
      'wow_lab_sound_stop_sequence', observe_stop_sequence)
  end)
  if not ok then
    remove_capture_taps()
    S.capture.error = tostring(err)
    return false, S.capture.error
  end
  S.capture.available = true
  S.capture.error = nil
  return true
end

local function capture_frame()
  local segment = S.capture.active
  if not segment then return end
  if segment.stream_decode_pending then
    local entry = CATALOG[segment.request.catalog_index]
    segment.stream_programs = build_stream_programs(entry)
    segment.stream_decode_pending = false
  end
  capture_sample(segment, false)
  if S.capture.pending_stop then
    local pending = S.capture.pending_stop
    capture_finish_active(pending.reason, pending.reason_code)
  end
end

local function console_step_mode(mode)
  local enabled
  if mode == nil then enabled = not S.step_logging
  elseif type(mode) == 'boolean' then enabled = mode
  else
    local value = tostring(mode):lower()
    if value == 'on' or value == '1' or value == 'true' then enabled = true
    elseif value == 'off' or value == '0' or value == 'false' then enabled = false
    else print('[WOW SOUND] wssteps(): use on/off, true/false, or no argument'); return false end
  end
  S.step_logging = enabled
  printf('[WOW SOUND] detailed step logging %s', enabled and 'ON' or 'OFF')
  if S.capture.active then
    if enabled then
      S.capture.active.trace_header_printed = false
    else
      S.capture.active.compact_trace_signature = nil
      trace_compact_start(S.capture.active)
    end
  end
  return true
end

local function console_capture_status()
  printf('[WOW SOUND] capture available=%s completed=%d steps=%s',
    S.capture.available and 'YES' or 'NO', #S.capture.completed, S.step_logging and 'ON' or 'OFF')
  if not S.capture.available and S.capture.error then
    printf('[WOW SOUND] capture error: %s', S.capture.error)
  end
  local segment = S.capture.active
  if segment then
    printf('[WOW SOUND] active capture %02d %s %s bus=%d engine=%d samples=%d steps=%d%s',
      segment.id, segment.request.key, segment.request.name, #segment.raw_bus_events,
      #segment.engine_write_events, #segment.engine_samples, #segment.steps,
      segment.truncated and ' TRUNCATED' or '')
  else
    print('[WOW SOUND] active capture: NONE')
  end
end

local function console_capture_list()
  if #S.capture.completed == 0 and not S.capture.active then
    print('[WOW SOUND] no sound captures')
    return
  end
  for _, segment in ipairs(S.capture.completed) do
    printf('[WOW SOUND] CAP %02d %-4s %-24s %7.3fs %-13s steps=%d bus=%d engine=%d%s',
      segment.id, segment.request.key, segment.request.name, segment.duration_seconds or 0,
      segment.end_reason or 'UNKNOWN', #segment.steps, #segment.raw_bus_events,
      #segment.engine_write_events, segment.truncated and ' TRUNCATED' or '')
  end
  local segment = S.capture.active
  if segment then
    local elapsed = math.max(0, machine_seconds() - segment.start_time_seconds)
    printf('[WOW SOUND] CAP %02d %-4s %-24s %7.3fs ACTIVE        steps=%d bus=%d engine=%d%s',
      segment.id, segment.request.key, segment.request.name, elapsed, #segment.steps,
      #segment.raw_bus_events, #segment.engine_write_events, segment.truncated and ' TRUNCATED' or '')
  end
end

local function export_segment(segment, live)
  local now, frame = machine_seconds(), frame_number()
  local end_time = segment.end_time_seconds or (live and now or segment.start_time_seconds)
  local end_frame = segment.end_frame or (live and frame or segment.start_frame)
  return {
    id = segment.id, status = segment.status, begin_sequence = segment.begin_sequence,
    request = segment.request, dispatch_period_ticks = segment.dispatch_period_ticks,
    start_time_seconds = segment.start_time_seconds, start_frame = segment.start_frame,
    end_time_seconds = end_time, end_frame = end_frame,
    duration_seconds = segment.duration_seconds or math.max(0, end_time - segment.start_time_seconds),
    duration_frames = segment.duration_frames or math.max(0, end_frame - segment.start_frame),
    stop_reason_code = segment.stop_reason_code, end_reason = segment.end_reason,
    truncated = segment.truncated, dropped_events = copy_map(segment.dropped_events),
    counts = {
      raw_bus_events = #segment.raw_bus_events,
      engine_write_events = #segment.engine_write_events,
      engine_samples = #segment.engine_samples,
      steps = #segment.steps,
      retained_events = segment.retained_event_count,
    },
    stream_programs = segment.stream_programs,
    raw_bus_events = segment.raw_bus_events,
    engine_write_events = segment.engine_write_events,
    engine_samples = segment.engine_samples,
    steps = segment.steps,
  }
end

local function safe_emu_text(callback, fallback)
  local ok, value = pcall(callback)
  return ok and value ~= nil and tostring(value) or fallback
end

local function capture_document()
  local captures = {}
  for _, segment in ipairs(S.capture.completed) do captures[#captures + 1] = export_segment(segment, false) end
  if S.capture.active then captures[#captures + 1] = export_segment(S.capture.active, true) end
  local frame_period = screen_number('frame_period', nil)
  return {
    format = 'wow-sound-capture', format_version = 1,
    generated_utc = os.date('!%Y-%m-%dT%H:%M:%SZ'),
    producer = { name='Wizard of Wor Lab Sound Browser', version=M.VERSION, source_file='modules/sound_browser.lua' },
    machine = {
      rom_name = safe_emu_text(function() return emu.romname() end, 'wow'),
      game_name = safe_emu_text(function() return emu.gamename() end, 'Wizard of Wor'),
      astrocade_clock_hz = C.ASTROCADE_CLOCK_HZ,
      frame_period_seconds = frame_period,
      refresh_hz = frame_period and frame_period > 0 and (1 / frame_period) or nil,
    },
    register_model = { primary_ports='$10-$17', secondary_ports='$50-$57', order=REGISTER_NAMES },
    captures = captures,
  }
end

local function json_escape_string(value)
  local s = tostring(value)
  local out = {'"'}
  for i = 1, #s do
    local byte = s:byte(i)
    if byte == 0x22 then out[#out + 1] = '\\"'
    elseif byte == 0x5C then out[#out + 1] = '\\\\'
    elseif byte == 0x08 then out[#out + 1] = '\\b'
    elseif byte == 0x0C then out[#out + 1] = '\\f'
    elseif byte == 0x0A then out[#out + 1] = '\\n'
    elseif byte == 0x0D then out[#out + 1] = '\\r'
    elseif byte == 0x09 then out[#out + 1] = '\\t'
    elseif byte < 0x20 then out[#out + 1] = string.format('\\u%04X', byte)
    else out[#out + 1] = string.char(byte) end
  end
  out[#out + 1] = '"'
  return table.concat(out)
end

local JSON_ARRAY_FIELDS = {
  captures=true, order=true, raw_bus_events=true, engine_write_events=true, engine_samples=true,
  steps=true, changes=true, registers=true, register_hex=true, segments=true, commands=true, data=true,
}

local function json_table_kind(value, key_hint)
  local count, maximum = 0, 0
  for key in pairs(value) do
    if type(key) ~= 'number' or key < 1 or key % 1 ~= 0 then return 'object' end
    count = count + 1
    if key > maximum then maximum = key end
  end
  if count == 0 then return JSON_ARRAY_FIELDS[key_hint] and 'array' or 'object' end
  return maximum == count and 'array' or 'object'
end

local function json_encode_fallback(root)
  local active = {}
  local function encode(value, depth, key_hint)
    local kind = type(value)
    if value == nil then return 'null' end
    if kind == 'boolean' then return value and 'true' or 'false' end
    if kind == 'number' then
      if value ~= value or value == math.huge or value == -math.huge then return 'null' end
      return string.format('%.17g', value)
    end
    if kind == 'string' then return json_escape_string(value) end
    if kind ~= 'table' then
      error('unsupported JSON value type: ' .. kind, 0)
    end
    if active[value] then error('cyclic table in capture document', 0) end
    active[value] = true

    local indent = string.rep('  ', depth)
    local child_indent = string.rep('  ', depth + 1)
    local parts = {}
    if json_table_kind(value, key_hint) == 'array' then
      for i = 1, #value do parts[#parts + 1] = child_indent .. encode(value[i], depth + 1, nil) end
      active[value] = nil
      if #parts == 0 then return '[]' end
      return '[\n' .. table.concat(parts, ',\n') .. '\n' .. indent .. ']'
    end

    local keys = {}
    for key, item in pairs(value) do
      if item ~= nil then
        if type(key) ~= 'string' and type(key) ~= 'number' then
          error('unsupported JSON object key type: ' .. type(key), 0)
        end
        keys[#keys + 1] = key
      end
    end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, key in ipairs(keys) do
      parts[#parts + 1] = child_indent .. json_escape_string(key) .. ': ' .. encode(value[key], depth + 1, tostring(key))
    end
    active[value] = nil
    if #parts == 0 then return '{}' end
    return '{\n' .. table.concat(parts, ',\n') .. '\n' .. indent .. '}'
  end
  return encode(root, 0, nil)
end

local function encode_capture_json(document)
  local json_api = rawget(_G, 'json')
  if json_api and type(json_api.stringify) == 'function' then
    local ok, encoded = pcall(json_api.stringify, document, {indent=true})
    if ok and type(encoded) == 'string' then return encoded, 'MAME' end
  end
  return json_encode_fallback(document), 'Lua'
end

local function console_capture_save(path)
  local filename = path and tostring(path) or ''
  if filename == '' then filename = 'wow_sound_capture_' .. os.date('%Y%m%d-%H%M%S') .. '.json' end

  local ok, encoded, encoder = pcall(function()
    local body, source = encode_capture_json(capture_document())
    return body, source
  end)
  if not ok then
    printf('[WOW SOUND] wscapsave(): JSON encoding failed: %s', tostring(encoded))
    return false
  end

  local file, err = io.open(filename, 'w')
  if not file then printf('[WOW SOUND] wscapsave(): cannot open %s: %s', filename, tostring(err)); return false end
  local write_ok, write_err = file:write(encoded, '\n')
  file:close()
  if not write_ok then printf('[WOW SOUND] wscapsave(): cannot write %s: %s', filename, tostring(write_err)); return false end
  local count = #S.capture.completed + (S.capture.active and 1 or 0)
  printf('[WOW SOUND] saved %d capture(s) to %s (JSON encoder=%s)', count, filename, tostring(encoder))
  return true, filename
end

local function console_capture_clear()
  local count = #S.capture.completed
  S.capture.completed = {}
  printf('[WOW SOUND] cleared %d completed capture(s)%s', count,
    S.capture.active and '; active capture retained' or '')
  return true
end

local function observe_native_events()
  local play = S.program:read_u8(C.STATE_PLAY_SEQ)
  if play ~= S.last_play_seq then
    S.last_play_seq = play
    local active = active_index()
    local e = active and CATALOG[active + 1] or nil
    if e then
      print('')
      printf('[WOW SOUND] PLAY %s request=%s mask=%s pri=%d P%s S%s  %s',
        entry_key(e), hex4(C.SOUND_REQUEST_1 + e.group - 1), hex2(1 << e.bit), e.priority,
        e.primary and string.format('%04X', e.primary) or '----',
        e.secondary and string.format('%04X', e.secondary) or '----', e.name)
      trace_compact_start(S.capture.active)
    end
  end

  local stop = S.program:read_u8(C.STATE_STOP_SEQ)
  if stop ~= S.last_stop_seq then
    S.last_stop_seq = stop
    local index = S.program:read_u8(C.STATE_STOP_INDEX)
    local e = CATALOG[index + 1]
    local reason = STOP_REASON[S.program:read_u8(C.STATE_STOP_REASON)] or 'UNKNOWN'
    -- Compact mode reports lifecycle through TRACE ... END.  Detailed
    -- step mode retains the explicit STOP line as additional low-level context.
    if e and S.step_logging then
      printf('[WOW SOUND] STOP %s %s reason=%s', entry_key(e), e.name, reason)
    end
  end

  local mode = S.program:read_u8(C.STATE_MODE)
  local result = S.program:read_u8(C.STATE_BATCH_RESULT)
  if S.last_mode ~= 0 and mode == 0 and result == 1 and S.last_batch_result ~= 1 then
    printf('[WOW SOUND] PLAY ALL COMPLETE: %d sounds', S.program:read_u8(C.STATE_BATCH_COMPLETED))
  end
  S.last_mode = mode
  S.last_batch_result = result
end

local function mailbox(command, argument)
  if not S.active or not S.lab or S.lab.state ~= 'MODULE' then
    return false, 'sound module is not active'
  end
  if S.program:read_u8(C.STATE_MAILBOX_CMD) ~= 0 then
    return false, 'native mailbox is busy'
  end
  if argument ~= nil then S.program:write_u8(C.STATE_MAILBOX_ARG, argument & 0xFF) end
  S.program:write_u8(C.STATE_MAILBOX_CMD, command & 0xFF)
  return true
end

local function print_engine(label, base, modulators)
  local st = engine_state(base, modulators)
  local ptr = visible_pointer(st)
  printf('[WOW SOUND] %-9s %-6s ptr=%s pri=%d wait=%02X mods=%d',
    label, engine_phase(st), ptr and hex4(ptr) or '----', st.priority, st.wait, st.modulators)
end

local function console_state()
  print_engine('PRIMARY', C.PRIMARY_ENGINE, C.PRIMARY_MODULATORS)
  print_engine('SECONDARY', C.SECONDARY_ENGINE, C.SECONDARY_MODULATORS)
end

local function console_list()
  for i, e in ipairs(CATALOG) do
    printf('[WOW SOUND] %2d %-4s pri=%d P=%s S=%s  %s', i, entry_key(e), e.priority,
      e.primary and hex4(e.primary) or '----', e.secondary and hex4(e.secondary) or '----', e.name)
  end
end

local function console_info()
  local n = selected_index()
  local e = CATALOG[n + 1]
  if e then
    printf('[WOW SOUND] selected %d/%d %s request=%s mask=%s pri=%d P=%s S=%s  %s',
      n + 1, #CATALOG, entry_key(e), hex4(C.SOUND_REQUEST_1 + e.group - 1), hex2(1 << e.bit),
      e.priority, e.primary and hex4(e.primary) or '----', e.secondary and hex4(e.secondary) or '----', e.name)
  end
  printf('[WOW SOUND] active=%02X mode=%02X next=%d completed=%d playseq=%d stopseq=%d dispatch=%d/%d',
    S.program:read_u8(C.STATE_ACTIVE), S.program:read_u8(C.STATE_MODE),
    S.program:read_u8(C.STATE_BATCH_NEXT), S.program:read_u8(C.STATE_BATCH_COMPLETED),
    S.program:read_u8(C.STATE_PLAY_SEQ), S.program:read_u8(C.STATE_STOP_SEQ),
    S.program:read_u8(C.STATE_DISPATCH_COUNTDOWN), S.program:read_u8(C.STATE_DISPATCH_PERIOD))
  console_state()
  console_capture_status()
end

local function console_dispatch(mode)
  mode = tostring(mode or ''):lower()
  local period
  if mode == 'wow' or mode == '4' then period = C.DISPATCH_PERIOD_WOW
  elseif mode == 'fast' or mode == '1' then period = C.DISPATCH_PERIOD_FAST
  else
    printf('[WOW SOUND] wsdispatch(): use "wow" or "fast"')
    return false
  end
  S.program:write_u8(C.STATE_DISPATCH_PERIOD, period)
  S.program:write_u8(C.STATE_DISPATCH_COUNTDOWN, period)
  printf('[WOW SOUND] dispatch mode %s: every %d foreground tick(s)',
    period == C.DISPATCH_PERIOD_WOW and 'WOW' or 'FAST', period)
  return true
end

local function print_console_commands()
  print('[WOW SOUND] console commands:')
  print('[WOW SOUND]   wsplay(n|R#B#)  play request through native mailbox')
  print('[WOW SOUND]   wsstop()        stop/reset active sound')
  print('[WOW SOUND]   wsall()         toggle native Play All')
  print('[WOW SOUND]   wslist()        list 24-request catalog')
  print('[WOW SOUND]   wsinfo()        selected/native state')
  print('[WOW SOUND]   wsstate()       resident engine state')
  print('[WOW SOUND]   wsdispatch(m)   "wow" (4 ticks) or "fast" (1 tick)')
  print('[WOW SOUND]   wssteps([m])    toggle detailed step log; compact trace is used when OFF')
  print('[WOW SOUND]   wscapstatus()   capture counters and active segment')
  print('[WOW SOUND]   wscaplist()     list completed and active captures')
  print('[WOW SOUND]   wscapsave(p)    save versioned JSON; path is optional')
  print('[WOW SOUND]   wscapclear()    clear completed captures')
  print('[WOW SOUND]   wshelp()        show sound-module commands')
end

local function install_shortcut(name, handler)
  local previous = rawget(_G, name)
  S.shortcuts[name] = { handler=handler, previous=previous, restore=previous ~= nil }
  rawset(_G, name, handler)
end

local function install_console_shortcuts()
  install_shortcut('wsplay', function(arg)
    local i, e = find_entry(arg)
    if not e then print('[WOW SOUND] wsplay(): use 1..24 or R#B#'); return false end
    local ok, err = mailbox(1, i - 1)
    if not ok then printf('[WOW SOUND] wsplay(): %s', err) end
    return ok
  end)
  install_shortcut('wsstop', function()
    local ok, err = mailbox(2)
    if not ok then printf('[WOW SOUND] wsstop(): %s', err) end
    return ok
  end)
  install_shortcut('wsall', function()
    local ok, err = mailbox(3)
    if not ok then printf('[WOW SOUND] wsall(): %s', err) end
    return ok
  end)
  install_shortcut('wslist', console_list)
  install_shortcut('wsinfo', console_info)
  install_shortcut('wsstate', console_state)
  install_shortcut('wsdispatch', console_dispatch)
  install_shortcut('wssteps', console_step_mode)
  install_shortcut('wscapstatus', console_capture_status)
  install_shortcut('wscaplist', console_capture_list)
  install_shortcut('wscapsave', console_capture_save)
  install_shortcut('wscapclear', console_capture_clear)
  install_shortcut('wshelp', print_console_commands)
end

local function restore_console_shortcuts()
  for name, shortcut in pairs(S.shortcuts) do
    if rawget(_G, name) == shortcut.handler then
      rawset(_G, name, shortcut.restore and shortcut.previous or nil)
    end
  end
  S.shortcuts = {}
end

function M.start(lab)
  S.lab = lab
  S.machine = lab.machine or manager.machine
  S.cpu = lab.native.cpu or (S.machine and S.machine.devices and S.machine.devices[':maincpu'])
  S.program = lab.native.program
  S.io_space = S.cpu and S.cpu.spaces and S.cpu.spaces['io'] or nil
  S.screen = S.machine and S.machine.screens and (S.machine.screens[':screen'] or S.machine.screens[1]) or nil
  S.active = true
  S.window_first = 1
  S.step_logging = false
  S.capture = {
    available=false, error=nil, next_id=1, active=nil, pending_stop=nil, completed={},
    last_begin_sequence=0, last_stop_sequence=0,
  }

  local code, labels = build_controller()
  S.controller_labels = labels

  -- The module owns $D400 and above.  The permanent Lab kernel at $D3C0 and
  -- supervisor ABI at $D380 are deliberately untouched.
  lab.memory.write_bytes(S.program, C.NATIVE_CODE, code)
  lab.memory.write_bytes(S.program, C.REQUEST_TABLE, REQUEST_TABLE)
  lab.memory.fill(S.program, lab.memory.addr.VIDEO_START, lab.memory.addr.VISIBLE_VIDEO_END, 0)

  S.last_play_seq = 0
  S.last_stop_seq = 0
  S.last_mode = S.program:read_u8(C.STATE_MODE)
  S.last_batch_result = S.program:read_u8(C.STATE_BATCH_RESULT)
  local capture_ok, capture_err = install_capture_taps()
  install_console_shortcuts()

  printf('[WOW SOUND] SOUND BROWSER MODULE %s', M.VERSION)
  printf('[WOW SOUND] native controller %s-%s; state %s-$%04X; request table %s',
    hex4(C.NATIVE_CODE), hex4(C.NATIVE_CODE + #code - 1), hex4(C.STATE_BASE),
    C.STATE_PLAY_BEGIN_SEQ, hex4(C.REQUEST_TABLE))
  if capture_ok then
    print('[WOW SOUND] diagnostics: read-only engine/I/O capture enabled; detailed step console log OFF')
  else
    printf('[WOW SOUND] diagnostics unavailable: %s', tostring(capture_err))
  end
  print_console_commands()

  lab.native:handoff(C.NATIVE_CODE, C.STACK_TOP)
end

function M.update(lab)
  if not S.active then return end
  observe_native_events()
  capture_frame()
  service_ui()
end

function M.stop(lab)
  if not S.active then return end
  if S.capture.active then capture_finish_active('LAB RETURN', nil) end
  S.active = false
  remove_capture_taps()
  restore_console_shortcuts()
  S.io_space = nil
  S.screen = nil
  print('[WOW SOUND] return to Wizard of Wor Lab')
end

return M
