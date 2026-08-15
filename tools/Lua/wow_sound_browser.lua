-- wow_sound_browser.lua
-- Wizard of Wor native injected sound browser for MAME 0.289+
--
-- Lua validates the WoW ROM, injects the native controller and request table,
-- prepares the native menu, exposes console commands, and reports engine-state
-- transitions. The injected Z80 controller handles browser input, sound requests,
-- reset/dispatch, manual playback, and Play All through WoW's resident sound code.

local VERSION = "2.1.3-20260815-1349"
local BUILD_FILE = "wow_sound_browser.lua"

local C = {
  CPU_TAG = ":maincpu",

  SOUND_REQUEST_1 = 0xD240,
  SOUND_REQUEST_4 = 0xD243,
  SOUND_SERVICE_ENABLED = 0xD244,
  SPEECH_ACTIVE = 0xD245,
  QUEUE_WRITE = 0xD2D2,
  QUEUE_READ = 0xD2D4,

  PRIMARY_SOUND_ENGINE_RECORD = 0xD270,
  SECONDARY_SOUND_ENGINE_RECORD = 0xD2AC,

  SOUND_SERVICE_ENTRY = 0x8000,
  SOUND_REQUEST_DISPATCH_ENTRY = 0x8003,
  SOUND_RESET_ALL_ENTRY = 0x8006,
  SOUND_STREAM_OPCODE_TABLE = 0x8407,
  INVALID_STREAM_FALLBACK = 0x8740,

  PRINT_STRING = 0x03B3,
  PRINT_STRING_COLOR = 0x03B5,
  XPAND_BLUE = 0x04,
  XPAND_YELLOW = 0x08,
  XPAND_RED = 0x0C,

  NATIVE_CODE = 0xD400,
  NATIVE_CODE_END = 0xD6F6,

  STATE_SELECTION = 0xD700,
  STATE_ACTIVE = 0xD701,
  STATE_MODE = 0xD702,
  STATE_UI_DIRTY = 0xD709,
  STATE_UI_READY = 0xD70A,
  STATE_EXIT_REQUEST = 0xD70B,
  STATE_MAILBOX_CMD = 0xD70C,
  STATE_MAILBOX_ARG = 0xD70D,
  STATE_PLAY_SEQ = 0xD70E,
  STATE_STOP_SEQ = 0xD70F,
  STATE_STOP_REASON = 0xD710,
  STATE_STOP_INDEX = 0xD711,
  STATE_BATCH_RESULT = 0xD712,
  STATE_BATCH_NEXT = 0xD705,
  STATE_BATCH_COMPLETED = 0xD706,

  DRAW_CODE = 0xD740,
  DRAW_DATA = 0xD900,
  NATIVE_CATALOG = 0xDB00,
  CALL_STACK = 0xDFE0,

  TAKEOVER_DELAY_SEC = 2.0,
  UI_ROWS = 7,
}

local CATALOG = {
  { group=1, bit=0, priority=0, primary=0x89BE, secondary=0x89E5, name="GLOBAL EVENT 0" },
  { group=1, bit=1, priority=0, primary=0x89A0, secondary=0x89AF, name="GLOBAL EVENT 1" },
  { group=1, bit=2, priority=0, primary=0x8741, secondary=0x8772, name="GLOBAL EVENT 2" },
  { group=1, bit=3, priority=0, primary=0x8981, secondary=nil,    name="GLOBAL EVENT 3" },
  { group=1, bit=4, priority=0, primary=0x8A0C, secondary=0x8A27, name="GLOBAL EVENT 4" },
  { group=1, bit=5, priority=0, primary=0x8971, secondary=nil,    name="COIN UP" },
  { group=2, bit=0, priority=1, primary=nil,    secondary=0x8928, name="PLAYER DEATH" },
  { group=2, bit=1, priority=0, primary=nil,    secondary=0x887B, name="PLAYER FIRE" },
  { group=2, bit=2, priority=1, primary=nil,    secondary=0x87EA, name="UNRESOLVED EVENT" },
  { group=2, bit=3, priority=0, primary=nil,    secondary=0x883B, name="UNRESOLVED EVENT" },
  { group=2, bit=4, priority=0, primary=nil,    secondary=0x8825, name="ENEMY STATE EVENT" },
  { group=2, bit=6, priority=0, primary=nil,    secondary=0x8988, name="PLAYER STATUS EVENT" },
  { group=2, bit=7, priority=1, primary=0x8741, secondary=nil,    name="GLOBAL EVENT 2 PRIMARY" },
  { group=3, bit=0, priority=1, primary=0x8AA1, secondary=0x8ADD, name="SPECIAL ACTOR DEATH" },
  { group=3, bit=1, priority=0, primary=nil,    secondary=0x890E, name="MONSTER DEATH" },
  { group=3, bit=2, priority=0, primary=nil,    secondary=0x8851, name="MONSTER FIRE" },
  { group=3, bit=3, priority=0, primary=nil,    secondary=0x8851, name="MONSTER FIRE" },
  { group=3, bit=4, priority=0, primary=nil,    secondary=0x8A42, name="WORLUK PHASE EVENT" },
  { group=3, bit=5, priority=1, primary=0x8A81, secondary=0x8A6C, name="DUAL CHIP EVENT" },
  { group=3, bit=7, priority=1, primary=0x877B, secondary=nil,    name="WORLUK ENTRY" },
  { group=4, bit=0, priority=2, primary=0x88E2, secondary=0x8905, name="SPECIAL DEATH EVENT" },
  { group=4, bit=1, priority=1, primary=0x8AF6, secondary=0x8B1F, name="DUAL CHIP EVENT" },
  { group=4, bit=2, priority=1, primary=nil,    secondary=0x8AF3, name="SPECIAL MONSTER FIRE" },
  { group=4, bit=3, priority=1, primary=0x8B2E, secondary=0x8B5D, name="DUAL CHIP EVENT" },
}

-- Native Z80 controller image installed at $D400-$D6F6.
-- wow_sound_browser.asm provides the labeled reference source for this image.
local NATIVE_CODE = {
  0xF3,0x31,0xE0,0xDF,0xCD,0x72,0xD4,0x3E,0x01,0x32,0x44,0xD2,0xCD,0x06,0x80,0xAF,
  0x32,0x00,0xD7,0x32,0x02,0xD7,0x32,0x03,0xD7,0x32,0x04,0xD7,0x32,0x05,0xD7,0x32,
  0x06,0xD7,0x32,0x07,0xD7,0x32,0x08,0xD7,0x32,0x0A,0xD7,0x32,0x0B,0xD7,0x32,0x0C,
  0xD7,0x32,0x0D,0xD7,0x32,0x0E,0xD7,0x32,0x0F,0xD7,0x32,0x10,0xD7,0x32,0x12,0xD7,
  0x3E,0xFF,0x32,0x01,0xD7,0x32,0x03,0xD7,0x3E,0x01,0x32,0x09,0xD7,0xC3,0x50,0xD4,
  0xFB,0x76,0xF3,0xCD,0x03,0x80,0xCD,0x7C,0xD5,0xCD,0x28,0xD5,0xCD,0xAE,0xD5,0xCD,
  0x4F,0xD6,0x3A,0x0A,0xD7,0xB7,0x28,0xE8,0xAF,0x32,0x0A,0xD7,0xCD,0x40,0xD7,0xC3,
  0x50,0xD4,0xAF,0x32,0x40,0xD2,0x32,0x41,0xD2,0x32,0x42,0xD2,0x32,0x43,0xD2,0xC9,
  0xCD,0x72,0xD4,0xCD,0x06,0x80,0xC9,0x3E,0x01,0x32,0x09,0xD7,0xC9,0xCD,0x80,0xD4,
  0x3A,0x00,0xD7,0x87,0x5F,0x16,0x00,0x21,0x00,0xDB,0x19,0x4E,0x23,0x46,0x21,0x40,
  0xD2,0x59,0x16,0x00,0x19,0x70,0xCD,0x03,0x80,0x3A,0x00,0xD7,0x32,0x01,0xD7,0xAF,
  0x32,0x07,0xD7,0x3A,0x0E,0xD7,0x3C,0x32,0x0E,0xD7,0xCD,0x87,0xD4,0xC9,0x32,0x10,
  0xD7,0x3A,0x0F,0xD7,0x3C,0x32,0x0F,0xD7,0xC9,0x3A,0x01,0xD7,0xFE,0xFF,0xC8,0x32,
  0x11,0xD7,0xCD,0x80,0xD4,0x3E,0x02,0xCD,0xBE,0xD4,0x3E,0xFF,0x32,0x01,0xD7,0xCD,
  0x87,0xD4,0xC9,0x3A,0x02,0xD7,0xB7,0xC2,0x25,0xD6,0x3A,0x01,0xD7,0x47,0x3A,0x00,
  0xD7,0xB8,0xCA,0xC9,0xD4,0x78,0xFE,0xFF,0x28,0x0B,0x32,0x11,0xD7,0xCD,0x80,0xD4,
  0x3E,0x03,0xCD,0xBE,0xD4,0xC3,0x8D,0xD4,0x3A,0x00,0xD7,0xB7,0x28,0x03,0x3D,0x18,
  0x02,0x3E,0x17,0x32,0x00,0xD7,0xC3,0x87,0xD4,0x3A,0x00,0xD7,0x3C,0xFE,0x18,0x38,
  0x01,0xAF,0x32,0x00,0xD7,0xC3,0x87,0xD4,0xDB,0x12,0x2F,0xE6,0x3F,0x47,0xDB,0x11,
  0x2F,0xE6,0x3F,0xB0,0x4F,0x3A,0x03,0xD7,0x2F,0xA1,0x47,0x79,0x32,0x03,0xD7,0x3A,
  0x02,0xD7,0xB7,0x20,0x12,0xCB,0x40,0xC4,0x08,0xD5,0xCB,0x48,0xC4,0x19,0xD5,0x78,
  0xE6,0x30,0xC4,0xE3,0xD4,0x18,0x06,0x78,0xE6,0x30,0xC4,0x25,0xD6,0xDB,0x10,0x2F,
  0xE6,0x60,0x4F,0x3A,0x04,0xD7,0x2F,0xA1,0x47,0x79,0x32,0x04,0xD7,0xCB,0x68,0x28,
  0x05,0x3E,0x01,0x32,0x0B,0xD7,0xCB,0x70,0xC4,0xCE,0xD5,0xC9,0x3A,0x0C,0xD7,0xB7,
  0xC8,0x47,0xAF,0x32,0x0C,0xD7,0x78,0xFE,0x01,0x20,0x0F,0x3A,0x0D,0xD7,0xFE,0x18,
  0xD0,0x32,0x00,0xD7,0xCD,0x87,0xD4,0xC3,0xE3,0xD4,0xFE,0x02,0x20,0x0A,0x3A,0x02,
  0xD7,0xB7,0xC2,0xFA,0xD5,0xC3,0xC9,0xD4,0xFE,0x03,0xC0,0xC3,0xCE,0xD5,0x3A,0x02,
  0xD7,0xB7,0xC0,0x3A,0x01,0xD7,0xFE,0xFF,0xC8,0x32,0x11,0xD7,0xCD,0xA9,0xD6,0xB7,
  0xC8,0x3E,0x01,0xCD,0xBE,0xD4,0x3E,0xFF,0x32,0x01,0xD7,0xC3,0x87,0xD4,0x3A,0x02,
  0xD7,0xB7,0xC2,0xFA,0xD5,0xCD,0x80,0xD4,0x3E,0x01,0x32,0x02,0xD7,0xAF,0x32,0x00,
  0xD7,0x32,0x05,0xD7,0x32,0x06,0xD7,0x32,0x07,0xD7,0x32,0x12,0xD7,0x3E,0x01,0x32,
  0x08,0xD7,0x3E,0xFF,0x32,0x01,0xD7,0xC3,0x87,0xD4,0x3A,0x01,0xD7,0xFE,0xFF,0x28,
  0x0D,0x32,0x11,0xD7,0xCD,0x80,0xD4,0x3E,0x05,0xCD,0xBE,0xD4,0x18,0x03,0xCD,0x80,
  0xD4,0xAF,0x32,0x02,0xD7,0x32,0x08,0xD7,0x3E,0x02,0x32,0x12,0xD7,0x3E,0xFF,0x32,
  0x01,0xD7,0xC3,0x87,0xD4,0x3A,0x01,0xD7,0xFE,0xFF,0xC8,0x32,0x11,0xD7,0xCD,0x80,
  0xD4,0x3E,0x02,0xCD,0xBE,0xD4,0x3E,0x02,0xC3,0x3B,0xD6,0x3E,0xFF,0x32,0x01,0xD7,
  0x3A,0x06,0xD7,0x3C,0x32,0x06,0xD7,0x3E,0x2D,0x32,0x08,0xD7,0xC3,0x87,0xD4,0x3A,
  0x02,0xD7,0xB7,0xC8,0x3A,0x01,0xD7,0xFE,0xFF,0x28,0x26,0x32,0x11,0xD7,0x3A,0x07,
  0xD7,0x3C,0x32,0x07,0xD7,0xFE,0xF0,0x30,0x0D,0xCD,0xA9,0xD6,0xB7,0xC8,0x3E,0x01,
  0xCD,0xBE,0xD4,0xC3,0x3B,0xD6,0xCD,0x80,0xD4,0x3E,0x04,0xCD,0xBE,0xD4,0xC3,0x3B,
  0xD6,0x3A,0x08,0xD7,0xB7,0x28,0x05,0x3D,0x32,0x08,0xD7,0xC9,0x3A,0x05,0xD7,0xFE,
  0x18,0x30,0x0A,0x32,0x00,0xD7,0x3C,0x32,0x05,0xD7,0xC3,0x8D,0xD4,0xAF,0x32,0x02,
  0xD7,0x3E,0x01,0x32,0x12,0xD7,0xC3,0x87,0xD4,0xDD,0x21,0x70,0xD2,0x21,0x46,0xD2,
  0xCD,0xBF,0xD6,0xB7,0xC8,0xDD,0x21,0xAC,0xD2,0x21,0x82,0xD2,0xC3,0xBF,0xD6,0xDD,
  0x7E,0x11,0xB7,0x20,0x30,0xDD,0x7E,0x0D,0xB7,0x20,0x2A,0x06,0x06,0x7E,0xB7,0x20,
  0x24,0x11,0x07,0x00,0x19,0x10,0xF6,0xDD,0x7E,0x05,0xB7,0x20,0x18,0xDD,0x7E,0x06,
  0xE6,0x0F,0x20,0x11,0xDD,0x7E,0x06,0xE6,0x20,0x28,0x07,0xDD,0x7E,0x04,0xE6,0xF0,
  0x20,0x03,0x3E,0x01,0xC9,0xAF,0xC9,
}

-- Two bytes per catalog entry: request-bank offset from $D240, then bit mask.
local NATIVE_REQUEST_TABLE = {
  0x00,0x01,
  0x00,0x02,
  0x00,0x04,
  0x00,0x08,
  0x00,0x10,
  0x00,0x20,
  0x01,0x01,
  0x01,0x02,
  0x01,0x04,
  0x01,0x08,
  0x01,0x10,
  0x01,0x40,
  0x01,0x80,
  0x02,0x01,
  0x02,0x02,
  0x02,0x04,
  0x02,0x08,
  0x02,0x10,
  0x02,0x20,
  0x02,0x80,
  0x03,0x01,
  0x03,0x02,
  0x03,0x04,
  0x03,0x08,
}

local S = {
  enabled = true,
  takeover = false,
  frame_subscription = nil,
  stop_subscription = nil,
  shortcuts = {},
  window_first = 1,
  last_mode = nil,
  last_ui_signature = nil,
  last_play_seq = 0,
  last_stop_seq = 0,
  trace = nil,
}

local machine = manager.machine
local cpu = machine.devices[C.CPU_TAG]
if not cpu then error("[WOW SOUND] main CPU not found at " .. C.CPU_TAG) end
local program = cpu.spaces and cpu.spaces["program"] or nil
if not program then error("[WOW SOUND] main CPU program space is unavailable") end

local function printf(fmt, ...)
  print(string.format(fmt, ...))
end

local function hex2(v) return string.format("$%02X", v & 0xFF) end
local function hex4(v) return string.format("$%04X", v & 0xFFFF) end

local function read16(addr)
  return program:read_u8(addr) | (program:read_u8(addr + 1) << 8)
end

local function machine_seconds()
  local ok, value = pcall(function() return machine.time:as_double() end)
  return ok and value or 0
end

local function validate_bytes(addr, expected)
  for i = 1, #expected do
    local actual = program:read_u8(addr + i - 1)
    if actual ~= expected[i] then
      return false, string.format("signature mismatch at %s: got %s expected %s",
        hex4(addr + i - 1), hex2(actual), hex2(expected[i]))
    end
  end
  return true
end

local function validate_program()
  local ok, why = validate_bytes(0x8000, {
    0xC3,0xF2,0x84,
    0xC3,0xC1,0x86,
    0xC3,0x16,0x83,
  })
  if not ok then return false, why end

  ok, why = validate_bytes(C.SOUND_STREAM_OPCODE_TABLE, {
    0x97,0x83,0x9A,0x83,0x1F,0x83,
  })
  if not ok then return false, why end

  ok, why = validate_bytes(C.INVALID_STREAM_FALLBACK, {0x03})
  if not ok then return false, why end

  ok, why = validate_bytes(C.PRINT_STRING, {0x3E,0x0C,0x0E,0xFF})
  if not ok then return false, why end

  return true
end

local function speech_idle()
  return program:read_u8(C.SPEECH_ACTIVE) == 0
     and read16(C.QUEUE_WRITE) == read16(C.QUEUE_READ)
end

local function sound_requests_idle()
  for addr = C.SOUND_REQUEST_1, C.SOUND_REQUEST_4 do
    if program:read_u8(addr) ~= 0 then return false end
  end
  return true
end

local function entry_key(entry)
  return string.format("R%dB%d", entry.group, entry.bit)
end

local function stream_text(addr, prefix)
  return addr and string.format("%s%04X", prefix, addr) or (prefix .. "----")
end

local function engine_state(base)
  local mod_active = 0
  for i = 0, 5 do
    local slot = base - 0x2A + i * 7
    if program:read_u8(slot) ~= 0 then mod_active = mod_active + 1 end
  end

  local voln = program:read_u8(base + 0x04)
  local volab = program:read_u8(base + 0x05)
  local volc = program:read_u8(base + 0x06)
  local audible = volab ~= 0
               or (volc & 0x0F) ~= 0
               or ((volc & 0x20) ~= 0 and (voln & 0xF0) ~= 0)

  return {
    pointer = read16(base + 0x01),
    priority = program:read_u8(base + 0x03),
    wait = program:read_u8(base + 0x0D),
    ready = program:read_u8(base + 0x11),
    modulators = mod_active,
    audible = audible,
  }
end

local function engine_phase(st)
  if st.ready ~= 0 then return "DECODE" end
  if st.wait ~= 0 then return "WAIT" end
  if st.modulators ~= 0 then return "MOD" .. tostring(st.modulators) end
  if st.audible then return "LATCH" end
  return "IDLE"
end

local function visible_pointer(st)
  return engine_phase(st) == "IDLE" and nil or st.pointer
end

local function trace_state_text(label, st)
  local ptr = visible_pointer(st)
  if ptr then return string.format("%s %s %s", label, engine_phase(st), hex4(ptr)) end
  return string.format("%s %s ----", label, engine_phase(st))
end

local STOP_REASON = {
  [1] = "IDLE",
  [2] = "FIRE STOP",
  [3] = "NEW PLAY",
  [4] = "PLAY ALL LIMIT",
  [5] = "PLAY ALL STOP",
}

local function selected_index()
  return program:read_u8(C.STATE_SELECTION)
end

local function active_index()
  local n = program:read_u8(C.STATE_ACTIVE)
  return n < #CATALOG and n or nil
end

local function observe_native_events()
  local play_seq = program:read_u8(C.STATE_PLAY_SEQ)
  if play_seq ~= S.last_play_seq then
    S.last_play_seq = play_seq
    local index = active_index()
    local entry = index and CATALOG[index + 1] or nil
    if entry then
      print("")
      printf("[WOW SOUND] PLAY %s request=$D24%d mask=%s pri=%d %s %s  %s",
        entry_key(entry), entry.group - 1, hex2(1 << entry.bit), entry.priority,
        stream_text(entry.primary,"P"), stream_text(entry.secondary,"S"), entry.name)
      printf("[WOW SOUND] TRACE %s START entry=%s %s",
        entry_key(entry), stream_text(entry.primary,"P"), stream_text(entry.secondary,"S"))
      S.trace = { entry=entry, last_signature=nil }
    end
  end

  if S.trace then
    local p = engine_state(C.PRIMARY_SOUND_ENGINE_RECORD)
    local s = engine_state(C.SECONDARY_SOUND_ENGINE_RECORD)
    local sig = string.format("%s:%04X|%s:%04X",
      engine_phase(p), visible_pointer(p) or 0,
      engine_phase(s), visible_pointer(s) or 0)
    if sig ~= S.trace.last_signature then
      S.trace.last_signature = sig
      printf("[WOW SOUND] TRACE %s %s  %s",
        entry_key(S.trace.entry), trace_state_text("P",p), trace_state_text("S",s))
    end
  end

  local stop_seq = program:read_u8(C.STATE_STOP_SEQ)
  if stop_seq ~= S.last_stop_seq then
    S.last_stop_seq = stop_seq
    local reason = program:read_u8(C.STATE_STOP_REASON)
    local index = program:read_u8(C.STATE_STOP_INDEX)
    local entry = index < #CATALOG and CATALOG[index + 1] or nil
    if entry then
      printf("[WOW SOUND] TRACE %s END %s", entry_key(entry), STOP_REASON[reason] or ("REASON " .. tostring(reason)))
      if S.trace and S.trace.entry == entry then S.trace = nil end
    end
  end

  local mode = program:read_u8(C.STATE_MODE)
  if S.last_mode ~= nil and mode ~= S.last_mode then
    if mode ~= 0 then
      print("")
      printf("[WOW SOUND] PLAY ALL START: %d sounds; native gap 45 ticks; native limit 240 ticks", #CATALOG)
    else
      local result = program:read_u8(C.STATE_BATCH_RESULT)
      if result == 1 then
        printf("[WOW SOUND] PLAY ALL COMPLETE: %d sounds", program:read_u8(C.STATE_BATCH_COMPLETED))
      elseif result == 2 then
        printf("[WOW SOUND] PLAY ALL STOP: %d/%d completed", program:read_u8(C.STATE_BATCH_COMPLETED), #CATALOG)
      end
    end
  end
  S.last_mode = mode
end

local function transliterate_for_wow(text)
  local s = tostring(text or ""):upper()
  local out = {}
  for i = 1, #s do
    local ch = s:sub(i,i)
    local b = ch:byte()
    if (b >= 0x30 and b <= 0x39) or (b >= 0x41 and b <= 0x5A) then
      out[#out+1] = ch
    elseif ch == " " then
      out[#out+1] = "@"
    elseif ch == "-" then
      out[#out+1] = "_"
    elseif ch == "'" then
      out[#out+1] = "`"
    else
      out[#out+1] = "@"
    end
  end
  return table.concat(out)
end

local function fixed_native_text(text, width)
  local s = transliterate_for_wow(text)
  if #s > width then s = s:sub(1,width) end
  if #s < width then s = s .. string.rep("@", width - #s) end
  return s
end

local function native_center_encoded_row(text)
  local src = tostring(text or "")
  local out = {}
  for i = 1, #src do
    local ch = src:sub(i,i)
    if ch == " " then out[#out+1] = "@"
    elseif ch == "-" then out[#out+1] = "_"
    else out[#out+1] = ch end
  end
  local s = table.concat(out)
  if #s > 40 then s = s:sub(1,40) end
  local col = math.max(0, (40 - #s) // 2)
  return string.rep("@",col) .. s .. string.rep("@",40-col-#s)
end

local function screen_de(row, col)
  return (((row * 5) & 0xFF) << 8) | ((col * 2) & 0xFF)
end

local function update_window(selection)
  local index = selection + 1
  if index < S.window_first then
    S.window_first = index
  elseif index >= S.window_first + C.UI_ROWS then
    S.window_first = index - C.UI_ROWS + 1
  end
  local max_first = math.max(1, #CATALOG - C.UI_ROWS + 1)
  if S.window_first < 1 then S.window_first = 1 end
  if S.window_first > max_first then S.window_first = max_first end
end

local function native_status_line()
  local p = engine_state(C.PRIMARY_SOUND_ENGINE_RECORD)
  local s = engine_state(C.SECONDARY_SOUND_ENGINE_RECORD)
  local pphase = engine_phase(p)
  local sphase = engine_phase(s)
  local live = pphase ~= "IDLE" or sphase ~= "IDLE"
  local state = ""

  if not live then
    if program:read_u8(C.STATE_MODE) ~= 0 then
      state = "PAUSE"
    elseif program:read_u8(C.STATE_PLAY_SEQ) == 0 then
      state = "READY"
    else
      local reason = program:read_u8(C.STATE_STOP_REASON)
      state = (reason == 2 or reason == 5) and "STOPPED" or "READY"
    end
  end

  local pp = visible_pointer(p)
  local sp = visible_pointer(s)
  return string.format("%-7s P %-6s %4s  S %-6s %4s",
    state, pphase, pp and string.format("%04X",pp) or "----",
    sphase, sp and string.format("%04X",sp) or "----")
end

local function native_menu_lines()
  local selection = selected_index()
  if selection >= #CATALOG then selection = 0 end
  update_window(selection)

  local lines = {}
  local vmaj,vmin,vpatch = VERSION:match("^(%d+)%.(%d+)%.(%d+)")
  local ver = vmaj and ("V" .. vmaj .. vmin .. vpatch) or "VER"
  local header = fixed_native_text(" REQ   PSTR SSTR EVENT",40)
  header = header:sub(1,40-#ver) .. ver
  lines[#lines+1] = {row=0,col=0,text=header,color=C.XPAND_BLUE}

  for row = 0, C.UI_ROWS - 1 do
    local index = S.window_first + row
    local entry = CATALOG[index]
    local marker = ((index - 1) == selection) and "a" or "@"
    local primary = entry and entry.primary and string.format("%04X",entry.primary) or "----"
    local secondary = entry and entry.secondary and string.format("%04X",entry.secondary) or "----"
    local text = entry and string.format("%-4s  %4s %4s %s",
      entry_key(entry),primary,secondary,entry.name) or ""
    lines[#lines+1] = {row=1+row,col=1,text=fixed_native_text(text,39),color=C.XPAND_RED}
    lines[#lines+1] = {row=1+row,col=0,text=marker,color=C.XPAND_YELLOW}
  end

  -- Rows 8 and 10 provide spacing; row 9 reports the two engine states.
  lines[#lines+1] = {row=8,col=0,text=fixed_native_text("",40),color=C.XPAND_BLUE}
  lines[#lines+1] = {row=9,col=0,text=fixed_native_text(native_status_line(),40),color=C.XPAND_BLUE}
  lines[#lines+1] = {row=10,col=0,text=fixed_native_text("",40),color=C.XPAND_BLUE}

  local mode = program:read_u8(C.STATE_MODE)
  local active = active_index()
  local footer
  if mode ~= 0 then
    footer = "]^ SEL - FIRE STOP - 1P EXIT - 2P STOP"
  elseif active ~= nil and active == selection then
    footer = "]^ SELECT - FIRE STOP - 1P EXIT - 2P ALL"
  else
    footer = "]^ SELECT - FIRE PLAY - 1P EXIT - 2P ALL"
  end
  lines[#lines+1] = {row=11,col=0,text=native_center_encoded_row(footer),color=C.XPAND_YELLOW}
  return lines
end

local function write_native_draw_program(lines)
  local data = C.DRAW_DATA
  local code = {}
  local function emit(v) code[#code+1] = v & 0xFF end
  local function emit16(v) emit(v); emit(v >> 8) end

  for _,line in ipairs(lines) do
    local addr = data
    for i = 1, #line.text do
      program:write_u8(data, line.text:byte(i))
      data = data + 1
    end
    emit(0x21); emit16(addr)
    emit(0x11); emit16(screen_de(line.row,line.col))
    emit(0x06); emit(#line.text)
    emit(0x3E); emit(line.color)
    emit(0xCD); emit16(C.PRINT_STRING_COLOR)
  end
  emit(0xC9) -- return to the native controller

  if C.DRAW_CODE + #code >= C.DRAW_DATA then
    return false, "native UI display list exceeds reserved RAM"
  end
  if data >= C.NATIVE_CATALOG then
    return false, "native UI strings overlap native request catalog"
  end
  for i,b in ipairs(code) do program:write_u8(C.DRAW_CODE+i-1,b) end
  return true
end

local function request_ui_refresh()
  if program:read_u8(C.STATE_UI_DIRTY) == 0 then
    program:write_u8(C.STATE_UI_DIRTY,1)
  end
end

local function service_ui()
  if program:read_u8(C.STATE_UI_DIRTY) == 0 then return end
  if program:read_u8(C.STATE_UI_READY) ~= 0 then return end

  local ok,err = write_native_draw_program(native_menu_lines())
  if not ok then
    printf("[WOW SOUND] UI ERROR: %s", tostring(err))
    return
  end
  program:write_u8(C.STATE_UI_DIRTY,0)
  program:write_u8(C.STATE_UI_READY,1)
end

local function clear_video_ram()
  for addr = 0x4000,0x7FFF do program:write_u8(addr,0) end
end

local function inject_native_controller()
  for i,b in ipairs(NATIVE_CODE) do
    program:write_u8(C.NATIVE_CODE+i-1,b)
  end
  for i,b in ipairs(NATIVE_REQUEST_TABLE) do
    program:write_u8(C.NATIVE_CATALOG+i-1,b)
  end
end

local function verify_injection()
  for i,b in ipairs(NATIVE_CODE) do
    if program:read_u8(C.NATIVE_CODE+i-1) ~= b then
      return false,string.format("native code verify failed at %s",hex4(C.NATIVE_CODE+i-1))
    end
  end
  for i,b in ipairs(NATIVE_REQUEST_TABLE) do
    if program:read_u8(C.NATIVE_CATALOG+i-1) ~= b then
      return false,string.format("native catalog verify failed at %s",hex4(C.NATIVE_CATALOG+i-1))
    end
  end
  return true
end

local function takeover(reason)
  if S.takeover then return true end
  local ok,why = validate_program()
  if not ok then
    printf("[WOW SOUND] takeover refused: %s",why)
    return false
  end

  clear_video_ram()
  inject_native_controller()
  ok,why = verify_injection()
  if not ok then
    printf("[WOW SOUND] takeover refused: %s",why)
    return false
  end

  if cpu.state["HALT"] then cpu.state["HALT"].value = 0 end
  cpu.state["PC"].value = C.NATIVE_CODE
  S.takeover = true
  S.last_mode = nil
  S.last_ui_signature = nil
  S.last_play_seq = 0
  S.last_stop_seq = 0
  S.trace = nil
  printf("[WOW SOUND] native browser takeover active (%s); Z80 controller=%s-%s catalog=%s",
    reason or "auto",hex4(C.NATIVE_CODE),hex4(C.NATIVE_CODE_END),hex4(C.NATIVE_CATALOG))
  return true
end

local function ui_signature()
  if not S.takeover then return "" end
  local p = engine_state(C.PRIMARY_SOUND_ENGINE_RECORD)
  local s = engine_state(C.SECONDARY_SOUND_ENGINE_RECORD)
  return string.format("%02X:%02X:%02X:%02X:%s:%04X:%s:%04X",
    program:read_u8(C.STATE_SELECTION),
    program:read_u8(C.STATE_ACTIVE),
    program:read_u8(C.STATE_MODE),
    program:read_u8(C.STATE_PLAY_SEQ),
    engine_phase(p), visible_pointer(p) or 0,
    engine_phase(s), visible_pointer(s) or 0)
end

local function mailbox(cmd,arg)
  if not S.takeover then return false,"browser has not taken over" end
  if program:read_u8(C.STATE_MAILBOX_CMD) ~= 0 then return false,"native mailbox busy" end
  if arg ~= nil then program:write_u8(C.STATE_MAILBOX_ARG,arg & 0xFF) end
  program:write_u8(C.STATE_MAILBOX_CMD,cmd)
  return true
end

local function find_entry(arg)
  if type(arg) == "number" then
    local n = math.floor(arg)
    if n >= 1 and n <= #CATALOG then return n,CATALOG[n] end
  elseif type(arg) == "string" then
    local key = arg:upper()
    for i,e in ipairs(CATALOG) do if entry_key(e) == key then return i,e end end
  end
  return nil,nil
end

local function print_engine(label,base)
  local st = engine_state(base)
  printf("[WOW SOUND] %s %-6s ptr=%s pri=%d wait=%02X mods=%d",
    label,engine_phase(st),visible_pointer(st) and hex4(visible_pointer(st)) or "----",
    st.priority,st.wait,st.modulators)
end

local function console_state()
  print_engine("PRIMARY  ",C.PRIMARY_SOUND_ENGINE_RECORD)
  print_engine("SECONDARY",C.SECONDARY_SOUND_ENGINE_RECORD)
end

local function console_list()
  for i,e in ipairs(CATALOG) do
    printf("[WOW SOUND] %2d %-4s pri=%d %s %s  %s",i,entry_key(e),e.priority,
      stream_text(e.primary,"P"),stream_text(e.secondary,"S"),e.name)
  end
end

local function console_info()
  local n = selected_index()
  local e = n < #CATALOG and CATALOG[n+1] or nil
  if e then
    printf("[WOW SOUND] selected %d/%d %s request=%s mask=%s pri=%d %s %s  %s",
      n+1,#CATALOG,entry_key(e),hex4(C.SOUND_REQUEST_1+e.group-1),hex2(1<<e.bit),e.priority,
      stream_text(e.primary,"P"),stream_text(e.secondary,"S"),e.name)
  end
  printf("[WOW SOUND] native state active=%02X mode=%02X next=%d completed=%d playseq=%d stopseq=%d",
    program:read_u8(C.STATE_ACTIVE),program:read_u8(C.STATE_MODE),
    program:read_u8(C.STATE_BATCH_NEXT),program:read_u8(C.STATE_BATCH_COMPLETED),
    program:read_u8(C.STATE_PLAY_SEQ),program:read_u8(C.STATE_STOP_SEQ))
  console_state()
end

local function print_console_commands()
  print("")
  print("[WOW SOUND] console commands:")
  print("[WOW SOUND]   wsplay(n|R#B#)  request play through native Z80 mailbox")
  print("[WOW SOUND]   wsstop()        request native stop")
  print("[WOW SOUND]   wsall()         toggle native Play All")
  print("[WOW SOUND]   wslist()        list catalog")
  print("[WOW SOUND]   wsinfo()        selected/native state")
  print("[WOW SOUND]   wsstate()       native engine state")
  print("[WOW SOUND]   wsexit()        exit MAME")
  print("[WOW SOUND]   wshelp()        show commands")
end

local function install_shortcut(name,handler)
  local previous = rawget(_G,name)
  S.shortcuts[name] = {handler=handler,previous=previous,restore=previous~=nil}
  rawset(_G,name,handler)
end

local function install_console_shortcuts()
  install_shortcut("wsplay",function(arg)
    local i,e = find_entry(arg)
    if not e then print("[WOW SOUND] wsplay(): use 1..24 or R#B#"); return false end
    local ok,err = mailbox(1,i-1)
    if not ok then printf("[WOW SOUND] wsplay(): %s",err) end
    return ok
  end)
  install_shortcut("wsstop",function()
    local ok,err = mailbox(2)
    if not ok then printf("[WOW SOUND] wsstop(): %s",err) end
    return ok
  end)
  install_shortcut("wsall",function()
    local ok,err = mailbox(3)
    if not ok then printf("[WOW SOUND] wsall(): %s",err) end
    return ok
  end)
  install_shortcut("wslist",console_list)
  install_shortcut("wsinfo",console_info)
  install_shortcut("wsstate",console_state)
  install_shortcut("wsexit",function() machine:exit() end)
  install_shortcut("wshelp",print_console_commands)
end

local function restore_console_shortcuts()
  for name,shortcut in pairs(S.shortcuts) do
    if rawget(_G,name) == shortcut.handler then
      rawset(_G,name,shortcut.restore and shortcut.previous or nil)
    end
  end
  S.shortcuts = {}
end

local function on_frame()
  if not S.enabled then return end

  if not S.takeover then
    if machine_seconds() >= C.TAKEOVER_DELAY_SEC and speech_idle() and sound_requests_idle() then
      takeover("auto")
    end
    return
  end

  if program:read_u8(C.STATE_EXIT_REQUEST) ~= 0 then
    machine:exit()
    return
  end

  observe_native_events()

  local sig = ui_signature()
  if sig ~= S.last_ui_signature then
    S.last_ui_signature = sig
    request_ui_refresh()
  end
  service_ui()
end

print("============================================================")
printf("[WOW SOUND] WOW NATIVE SOUND BROWSER %s",VERSION)
printf("[WOW SOUND] native controller %s-%s; request table %s",
  hex4(C.NATIVE_CODE),hex4(C.NATIVE_CODE_END),hex4(C.NATIVE_CATALOG))
install_console_shortcuts()
print_console_commands()
print("============================================================")

if emu.add_machine_frame_notifier then
  S.frame_subscription = emu.add_machine_frame_notifier(on_frame)
else
  emu.register_frame_done(on_frame,"wow_sound_browser_native")
end

if emu.add_machine_stop_notifier then
  S.stop_subscription = emu.add_machine_stop_notifier(function()
    S.enabled = false
    restore_console_shortcuts()
  end)
end

printf("[WOW SOUND] %s loaded from %s; takeover begins after %.1fs when startup speech/requests are idle",
  VERSION,BUILD_FILE,C.TAKEOVER_DELAY_SEC)
