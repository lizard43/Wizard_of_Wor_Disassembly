-- wow_sound_browser.lua
-- Wizard of Wor native ROM sound browser for MAME 0.289+
--
-- Wizard of Wor boots normally.  After startup speech and pending sound requests
-- become idle, the browser takes ownership of foreground execution while keeping
-- the original interrupt path active.  Sound playback uses WoW's own four-byte
-- request interface at $D240-$D243 and its resident ROM sound engine.
--
-- The browser does not replay Sound Studio JSON, synthesize audio in Lua, or
-- write Astrocade sound registers directly.  The JSON/library is documentation
-- and validation evidence only.  Runtime audio is produced by the loaded WoW ROM.
--
-- Controls:
--   UP / DOWN     move selection through all audible request events
--   FIRE          play selected sound; press again on the active sound to stop
--                 selecting another sound and pressing FIRE replaces the active one
--   2P START      play all 24 catalog sounds / stop play-all
--   1P START      exit MAME
--
-- LEFT / RIGHT are intentionally unused.  R1-R4 remain visible in each request
-- identifier because they are part of WoW's native $D240-$D243 request ABI.
--
-- Console:
--   wsplay(n)       play master catalog entry n (1..24)
--   wsplay("R2B1") play request by group/bit
--   wsall()         play all 24 catalog entries
--   wsstop()        stop current sound or active play-all run
--   wslist()        list all catalog entries
--   wsinfo()        show selected entry, request mapping, and engine state
--   wsstate()       show native engine state
--   wsdiag()        show fixed ROM/RAM anchors and request bytes
--   wsinput()       show raw/decoded WoW input ports
--   wsexit()        exit MAME
--   wshelp()        show commands

local VERSION = "1.5.1-20260815-1140"
local BUILD_FILE = "wow_sound_browser.lua"

local C = {
  CPU_TAG = ":maincpu",

  -- WoW input ports.  Reads share numbers with primary Astrocade sound writes.
  COINPORT = 0x10,
  P2PORT = 0x11,
  P1PORT = 0x12,

  -- Native WoW sound request interface.
  SOUND_REQUEST_1 = 0xD240,
  SOUND_REQUEST_2 = 0xD241,
  SOUND_REQUEST_3 = 0xD242,
  SOUND_REQUEST_4 = 0xD243,
  SOUND_SERVICE_ENABLED = 0xD244,

  -- Speech state used only to avoid taking over while startup speech is active.
  SPEECH_ACTIVE = 0xD245,
  QUEUE_WRITE = 0xD2D2,
  QUEUE_READ = 0xD2D4,

  -- Native WoW sound-engine records.
  PRIMARY_SOUND_ENGINE_RECORD = 0xD270,
  SECONDARY_SOUND_ENGINE_RECORD = 0xD2AC,

  -- High-ROM native service entry points.
  SOUND_SERVICE_ENTRY = 0x8000,          -- JP $84F2 Service_Sound_And_Speech
  SOUND_REQUEST_DISPATCH_ENTRY = 0x8003, -- JP $86C1 Dispatch_Sound_Requests
  SOUND_RESET_ALL_ENTRY = 0x8006,        -- JP $8316 Init_All_Sound_Engines

  -- Native sound-stream decoder anchors recovered in the sound RE pass.
  SOUND_STREAM_OPCODE_TABLE = 0x8407,
  SOUND_STREAM_DECODER = 0x8437,
  INSTALL_SOUND_STREAM = 0x851D,
  REQUEST_2_DECODER = 0x8538,
  REQUEST_3_DECODER = 0x8583,
  REQUEST_4_DECODER = 0x85E8,
  INVALID_STREAM_FALLBACK = 0x8740,

  -- Browser work RAM.  Keep the native UI/string/stack layout aligned with
  -- the proven WoW speech browser.
  IDLE_LOOP = 0xD400,
  UI_DRAW_PENDING = 0xD418,
  DRAW_CODE = 0xD420,
  DRAW_DATA = 0xD600,
  CALL_STACK = 0xDFE0,

  -- Native WoW text renderer.
  PRINT_STRING = 0x03B3,
  PRINT_STRING_COLOR = 0x03B5,
  XPAND_BLUE = 0x04,
  XPAND_YELLOW = 0x08,
  XPAND_RED = 0x0C,

  TAKEOVER_DELAY_SEC = 2.0,
  INPUT_INITIAL_REPEAT = 15,
  INPUT_REPEAT_RATE = 4,
  UI_ROWS = 7,

  -- Play-all auditions each request through the native WoW engine.  Naturally
  -- terminating sounds advance as soon as both engines return to IDLE.  A hard
  -- limit prevents sustained/looping requests from blocking the catalog run.
  PLAY_ALL_GAP_SEC = 0.75,
  PLAY_ALL_MAX_SOUND_SEC = 4.0,
}

-- Foreground browser loop:
--   EI
--   HALT
--   CALL $8003       ; consume requests and advance ready ROM streams
--   LD A,($D418)     ; native UI repaint pending?
--   OR A
--   JR Z,$D401
--   XOR A
--   LD ($D418),A
--   CALL $D420       ; generated native WoW text display list
--   JP $D401
--
-- WoW's interrupt path continues to call $8000/$84F2 and advances both native
-- sound-engine records.  UI repainting is scheduled inside this foreground loop
-- instead of depending on the MAME frame notifier observing the CPU at HALT.
local IDLE_LOOP_BYTES = {
  0xFB,                              -- $D400 EI
  0x76,                              -- $D401 HALT
  0xCD, 0x03, 0x80,                  -- $D402 CALL $8003
  0x3A, 0x18, 0xD4,                  -- $D405 LD A,($D418)
  0xB7,                              -- $D408 OR A
  0x28, 0xF6,                        -- $D409 JR Z,$D401
  0xAF,                              -- $D40B XOR A
  0x32, 0x18, 0xD4,                  -- $D40C LD ($D418),A
  0xCD, 0x20, 0xD4,                  -- $D40F CALL $D420
  0xC3, 0x01, 0xD4,                  -- $D412 JP $D401
}

-- The 24 audible request selectors proven by WoW's native decoders at
-- $86C1/$8538/$8583/$85E8.  Generic names remain deliberately generic where
-- the exact gameplay event has not yet been established from a call site.
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

local REQUEST_ADDR = {
  [1] = C.SOUND_REQUEST_1,
  [2] = C.SOUND_REQUEST_2,
  [3] = C.SOUND_REQUEST_3,
  [4] = C.SOUND_REQUEST_4,
}

local S = {
  enabled = true,
  takeover = false,
  frame_subscription = nil,
  stop_subscription = nil,
  shortcuts = {},
  selection = 0,
  window_first = 1,
  pending = nil,
  stopping = false,
  status = "WAITING FOR WOW INITIALIZATION",
  last_controls = 0,
  last_2p_start = false,
  hold_dir = 0,
  hold_frames = 0,
  ui_dirty = true,
  draw_count = 0,
  last_engine_signature = nil,
  trace = nil,
  batch = nil,
}

local machine = manager.machine
local cpu = machine.devices[C.CPU_TAG]
if not cpu then error("[WOW SOUND] main CPU not found at " .. C.CPU_TAG) end
local program = cpu.spaces and cpu.spaces["program"] or nil
local io = cpu.spaces and cpu.spaces["io"] or nil
if not program then error("[WOW SOUND] main CPU program space is unavailable") end
if not io then error("[WOW SOUND] main CPU I/O space is unavailable") end

local function printf(fmt, ...)
  print(string.format(fmt, ...))
end

local function hex2(v) return string.format("$%02X", v & 0xFF) end
local function hex4(v) return string.format("$%04X", v & 0xFFFF) end

local function read16(addr)
  local lo = program:read_u8(addr)
  local hi = program:read_u8((addr + 1) & 0xFFFF)
  return lo | (hi << 8)
end

local function machine_seconds()
  local ok, value = pcall(function() return machine.time:as_double() end)
  if ok then return value end
  return 0
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
    0xC3,0xF2,0x84, -- JP $84F2 periodic sound/speech service
    0xC3,0xC1,0x86, -- JP $86C1 request dispatcher
    0xC3,0x16,0x83, -- JP $8316 reset both sound-engine records
  })
  if not ok then return false, why end

  -- $8407 is the 24-word sound-stream opcode dispatch table.  Check the first
  -- three little-endian handler pointers: $8397, $839A, $831F.
  ok, why = validate_bytes(C.SOUND_STREAM_OPCODE_TABLE, {
    0x97,0x83, 0x9A,0x83, 0x1F,0x83,
  })
  if not ok then return false, why end

  -- Invalid stream opcodes >= $18 are redirected to $8740, whose $03 command
  -- resets the current engine record.
  ok, why = validate_bytes(C.INVALID_STREAM_FALLBACK, { 0x03 })
  if not ok then return false, why end

  ok, why = validate_bytes(C.PRINT_STRING, { 0x3E,0x0C,0x0E,0xFF })
  if not ok then return false, why end

  return true, "WoW native sound-engine/text signatures match"
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

local function clear_requests()
  for addr = C.SOUND_REQUEST_1, C.SOUND_REQUEST_4 do
    program:write_u8(addr, 0)
  end
end

local function visible_catalog()
  -- The browser always presents the complete native request catalog.
  -- R1-R4 are ABI identifiers, not user-facing sound categories.
  return CATALOG
end

local function entry_key(entry)
  return string.format("R%dB%d", entry.group, entry.bit)
end

local function entry_mask(entry)
  return 1 << entry.bit
end

local function entry_request(entry)
  return REQUEST_ADDR[entry.group]
end

local function stream_text(addr, prefix)
  if not addr then return prefix .. "----" end
  return string.format("%s%04X", prefix, addr)
end

local function engine_state(base)
  local mod_active = 0
  for i = 0, 5 do
    local slot = base - 0x2A + (i * 7)
    if program:read_u8(slot) ~= 0 then mod_active = mod_active + 1 end
  end

  local voln = program:read_u8(base + 0x04)
  local volab = program:read_u8(base + 0x05)
  local volc = program:read_u8(base + 0x06)
  local audible = (volab ~= 0)
               or ((volc & 0x0F) ~= 0)
               or (((volc & 0x20) ~= 0) and ((voln & 0xF0) ~= 0))

  return {
    block_port = program:read_u8(base + 0x00),
    pointer = read16(base + 0x01),
    priority = program:read_u8(base + 0x03),
    voln = voln,
    volab = volab,
    volc = volc,
    vibra = program:read_u8(base + 0x07),
    tonec = program:read_u8(base + 0x08),
    toneb = program:read_u8(base + 0x09),
    tonea = program:read_u8(base + 0x0A),
    tonmo = program:read_u8(base + 0x0B),
    flag_0c = program:read_u8(base + 0x0C),
    wait = program:read_u8(base + 0x0D),
    service = program:read_u8(base + 0x10),
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

local function engine_visible_pointer(st)
  if engine_phase(st) == "IDLE" then return nil end
  return st.pointer
end

local function engine_signature()
  local p = engine_state(C.PRIMARY_SOUND_ENGINE_RECORD)
  local q = engine_state(C.SECONDARY_SOUND_ENGINE_RECORD)
  local pp = engine_visible_pointer(p) or 0
  local qp = engine_visible_pointer(q) or 0
  return string.format("%d:%s:%04X|%d:%s:%04X",
    p.priority, engine_phase(p), pp,
    q.priority, engine_phase(q), qp)
end

local function trace_end(reason)
  if not S.trace then return end
  printf("[WOW SOUND] TRACE %s END %s", entry_key(S.trace.entry), reason or "")
  S.trace = nil
  S.ui_dirty = true
end

local function trace_state_text(label, st)
  local phase = engine_phase(st)
  local ptr = engine_visible_pointer(st)
  if ptr then
    return string.format("%s %s %s", label, phase, hex4(ptr))
  end
  return string.format("%s %s ----", label, phase)
end

local function trace_tick()
  local tr = S.trace
  if not tr then return end

  -- trace_start() is called from the frame callback immediately after the
  -- request byte has been observed consumed.  The Z80 may still be finishing
  -- that dispatcher pass, so suppress the same-frame sample.  The next frame
  -- begins logging from the installed stream state rather than the preceding
  -- reset/fallback handoff.
  if tr.skip_ticks and tr.skip_ticks > 0 then
    tr.skip_ticks = tr.skip_ticks - 1
    return
  end

  local p = engine_state(C.PRIMARY_SOUND_ENGINE_RECORD)
  local q = engine_state(C.SECONDARY_SOUND_ENGINE_RECORD)
  local sig = string.format("%s:%04X|%s:%04X",
    engine_phase(p), engine_visible_pointer(p) or 0,
    engine_phase(q), engine_visible_pointer(q) or 0)

  if sig ~= tr.last_signature then
    tr.last_signature = sig
    printf("[WOW SOUND] TRACE %s %s  %s",
      entry_key(tr.entry), trace_state_text("P", p), trace_state_text("S", q))
  end

  if engine_phase(p) == "IDLE" and engine_phase(q) == "IDLE" then
    tr.idle_frames = tr.idle_frames + 1
    if tr.idle_frames >= 2 then trace_end("IDLE") end
  else
    tr.idle_frames = 0
  end
end

local function trace_start(entry)
  S.trace = { entry=entry, last_signature=nil, idle_frames=0, skip_ticks=1 }
  printf("[WOW SOUND] TRACE %s START entry=%s %s",
    entry_key(entry), stream_text(entry.primary,"P"), stream_text(entry.secondary,"S"))
end

local function engines_idle()
  local p = engine_state(C.PRIMARY_SOUND_ENGINE_RECORD)
  local q = engine_state(C.SECONDARY_SOUND_ENGINE_RECORD)
  return engine_phase(p) == "IDLE" and engine_phase(q) == "IDLE"
end

local function active_entry()
  if S.pending and S.pending.entry then return S.pending.entry end
  if S.trace and S.trace.entry then return S.trace.entry end
  return nil
end

local function native_ui_busy()
  if not S.takeover or not cpu.state["PC"] then return false end
  local pc = cpu.state["PC"].value & 0xFFFF
  return pc >= C.DRAW_CODE and pc < C.DRAW_DATA
end

local function install_idle_loop()
  for i = 1, #IDLE_LOOP_BYTES do
    program:write_u8(C.IDLE_LOOP + i - 1, IDLE_LOOP_BYTES[i])
  end
  program:write_u8(C.UI_DRAW_PENDING, 0)
  if cpu.state["HALT"] then cpu.state["HALT"].value = 0 end
  if cpu.state["IFF1"] then cpu.state["IFF1"].value = 1 end
  if cpu.state["IFF2"] then cpu.state["IFF2"].value = 1 end
  if cpu.state["SP"] then cpu.state["SP"].value = C.CALL_STACK end
  cpu.state["PC"].value = C.IDLE_LOOP
end

local function clear_video_ram()
  for addr = 0x4000, 0x7FFF do program:write_u8(addr, 0) end
end

local function request_native_reset(status)
  if S.trace then trace_end(status or "RESET") end
  clear_requests()
  -- R1 bit 6 calls $830E (secondary reset), bit 7 calls $8306 (primary reset).
  -- This is the game's own control path, not a direct sound-register reset.
  program:write_u8(C.SOUND_REQUEST_1, 0xC0)
  S.stopping = true
  S.status = status or "RESETTING BOTH SOUND ENGINES"
  S.ui_dirty = true
end

local function queue_play(entry, source)
  if not S.takeover then return false, "browser has not taken over" end
  if not entry then return false, "no catalog entry selected" end
  source = source or "manual"

  if S.batch and source ~= "batch" then
    return false, "play-all is running"
  end

  if S.trace then trace_end("NEW PLAY") end

  -- Every audition starts from the same native state.  This prevents a looping
  -- or higher-priority previous event from rejecting or masking the next one.
  clear_requests()
  program:write_u8(C.SOUND_REQUEST_1, 0xC0)
  S.pending = { entry=entry, phase="reset", source=source }
  S.stopping = false
  S.status = "RESET FOR " .. entry_key(entry) .. " " .. entry.name
  S.ui_dirty = true
  return true
end

local function service_pending()
  if not S.takeover then return end

  if S.stopping and program:read_u8(C.SOUND_REQUEST_1) == 0 then
    S.stopping = false
    S.status = "STOPPED"
    S.ui_dirty = true
  end

  local p = S.pending
  if not p then return end

  if p.phase == "reset" then
    if program:read_u8(C.SOUND_REQUEST_1) ~= 0 then return end
    clear_requests()
    local addr = entry_request(p.entry)
    local mask = entry_mask(p.entry)
    program:write_u8(addr, mask)
    p.phase = "posted"
    S.status = string.format("POST %s  %s=%s", entry_key(p.entry), hex4(addr), hex2(mask))
    S.ui_dirty = true
    return
  end

  if p.phase == "posted" then
    if program:read_u8(entry_request(p.entry)) ~= 0 then return end
    S.status = "PLAYING " .. entry_key(p.entry) .. " " .. p.entry.name
    print("")
    printf("[WOW SOUND] PLAY %s request=%s mask=%s pri=%d %s %s  %s",
      entry_key(p.entry), hex4(entry_request(p.entry)), hex2(entry_mask(p.entry)),
      p.entry.priority, stream_text(p.entry.primary,"P"),
      stream_text(p.entry.secondary,"S"), p.entry.name)
    trace_start(p.entry)
    if p.source == "batch" and S.batch and S.batch.current_index then
      S.batch.item_started_at = machine_seconds()
    end
    S.pending = nil
    S.ui_dirty = true
  end
end

local function keep_catalog_selection_visible(index)
  if not index or index < 1 then return end
  S.selection = index
  if index < S.window_first then
    S.window_first = index
  elseif index >= S.window_first + C.UI_ROWS then
    S.window_first = index - C.UI_ROWS + 1
  end
  local max_first = math.max(1, #CATALOG - C.UI_ROWS + 1)
  if S.window_first < 1 then S.window_first = 1 end
  if S.window_first > max_first then S.window_first = max_first end
  S.ui_dirty = true
end

local function batch_finish_current(reason)
  local b = S.batch
  if not b or not b.current_index then return end

  local index = b.current_index
  local entry = CATALOG[index]
  b.completed = b.completed + 1
  printf("[WOW SOUND] PLAY ALL %d/%d %s END %s",
    b.completed, b.total, entry and entry_key(entry) or "?", reason or "")

  b.current_index = nil
  b.item_started_at = nil
  b.waiting_reset = false
  b.reset_reason = nil

  if b.completed >= b.total then
    printf("[WOW SOUND] PLAY ALL COMPLETE: %d sounds", b.completed)
    S.batch = nil
    S.status = "READY"
  else
    b.gap_until = machine_seconds() + C.PLAY_ALL_GAP_SEC
  end
  S.ui_dirty = true
end

local function start_play_all()
  if not S.takeover then
    print("[WOW SOUND] wsall(): browser has not taken over yet")
    return false
  end
  if S.batch then
    print("[WOW SOUND] wsall(): play-all is already running")
    return false
  end

  -- Always begin from catalog entry 1 and from a clean native engine state.
  S.pending = nil
  local need_reset = S.trace ~= nil or S.stopping or not engines_idle()
  if need_reset then request_native_reset("PLAY ALL START") end

  S.batch = {
    next_index = 1,
    current_index = nil,
    completed = 0,
    total = #CATALOG,
    initial_reset = need_reset,
    waiting_reset = false,
    reset_reason = nil,
    item_started_at = nil,
    gap_until = nil,
  }
  keep_catalog_selection_visible(1)
  S.status = "PLAY ALL"
  S.ui_dirty = true
  print("")
  printf("[WOW SOUND] PLAY ALL START: %d sounds; gap %.2fs; sustained limit %.1fs",
    #CATALOG, C.PLAY_ALL_GAP_SEC, C.PLAY_ALL_MAX_SOUND_SEC)
  return true
end

local function stop_play_all()
  if not S.batch then return false end

  local b = S.batch
  printf("[WOW SOUND] PLAY ALL STOP: %d/%d completed", b.completed, b.total)
  S.batch = nil
  S.pending = nil
  request_native_reset("PLAY ALL STOP")
  S.status = "STOPPED"
  S.ui_dirty = true
  return true
end

local function stop_batch_sound()
  local b = S.batch
  if not b or not b.current_index or b.waiting_reset then return false end

  local entry = CATALOG[b.current_index]
  printf("[WOW SOUND] PLAY ALL %s FIRE STOP", entry and entry_key(entry) or "?")
  S.pending = nil
  b.waiting_reset = true
  b.reset_reason = "FIRE STOP"
  request_native_reset("PLAY ALL FIRE STOP")
  return true
end

local function service_batch()
  local b = S.batch
  if not b then return end
  local now = machine_seconds()

  if b.initial_reset then
    if S.stopping or S.pending or not engines_idle() then return end
    b.initial_reset = false
  end

  if b.waiting_reset then
    if S.stopping or S.pending or not engines_idle() then return end
    batch_finish_current(b.reset_reason or "RESET")
    return
  end

  if b.current_index then
    if b.item_started_at and S.trace
       and (now - b.item_started_at) >= C.PLAY_ALL_MAX_SOUND_SEC then
      local entry = CATALOG[b.current_index]
      printf("[WOW SOUND] PLAY ALL %s LIMIT %.1fs; RESET",
        entry and entry_key(entry) or "?", C.PLAY_ALL_MAX_SOUND_SEC)
      S.pending = nil
      b.waiting_reset = true
      b.reset_reason = "LIMIT"
      request_native_reset("PLAY ALL LIMIT")
      return
    end

    if b.item_started_at and not S.pending and not S.trace and not S.stopping and engines_idle() then
      batch_finish_current("IDLE")
    end
    return
  end

  if b.gap_until then
    if now < b.gap_until then return end
    b.gap_until = nil
  end

  if b.next_index > #CATALOG then
    printf("[WOW SOUND] PLAY ALL COMPLETE: %d sounds", b.completed)
    S.batch = nil
    S.status = "READY"
    S.ui_dirty = true
    return
  end

  local index = b.next_index
  local entry = CATALOG[index]
  b.next_index = index + 1
  b.current_index = index
  b.item_started_at = nil
  keep_catalog_selection_visible(index)

  local ok, err = queue_play(entry, "batch")
  if not ok then
    printf("[WOW SOUND] PLAY ALL ERROR at %s: %s", entry_key(entry), tostring(err))
    S.batch = nil
    S.status = "ERROR PLAY ALL"
    S.ui_dirty = true
  end
end

local read_2p_start

local function takeover(reason)
  if S.takeover then return true end

  local ok, why = validate_program()
  if not ok then
    S.status = "PROGRAM VALIDATION FAILED"
    printf("[WOW SOUND] takeover refused: %s", why)
    return false
  end

  clear_requests()
  -- Keep WoW's normal sound/speech service enabled for browser auditioning.
  -- Do not alter Game_Mode; the normal cabinet service-switch state already
  -- selects the ordinary $84F2 service path.
  program:write_u8(C.SOUND_SERVICE_ENABLED, 1)
  clear_video_ram()
  install_idle_loop()

  S.takeover = true
  S.selection = 0
  S.window_first = 1
  S.last_controls = 0
  S.last_2p_start = read_2p_start()
  S.hold_dir = 0
  S.hold_frames = 0
  S.status = "READY"
  S.last_engine_signature = nil
  S.ui_dirty = true

  -- Silence any attract-mode music through the same request/reset path used by
  -- the game.  The browser remains responsive while $8003 consumes this byte.
  request_native_reset("INITIAL SOUND RESET")

  printf("[WOW SOUND] browser takeover active (%s); native sound request interface enabled", reason or "auto")
  return true
end

local function read_controls()
  local p1 = io:read_u8(C.P1PORT)
  local p2 = io:read_u8(C.P2PORT)
  return ((~p1) | (~p2)) & 0x3F
end

local function read_1p_start()
  -- WoW port $10 bit 5: 1-player Start, active low.
  return ((~io:read_u8(C.COINPORT)) & 0x20) ~= 0
end

read_2p_start = function()
  -- WoW port $10 bit 6: 2-player Start, active low.
  return ((~io:read_u8(C.COINPORT)) & 0x40) ~= 0
end

local function normalize_selection()
  local list = visible_catalog()
  if #list == 0 then
    S.selection = 0
    S.window_first = 1
    return
  end

  -- Zero means deliberately unselected.  This matches the proven WoW speech
  -- browser and prevents takeover from immediately implying a playable row.
  if S.selection == 0 then
    S.window_first = 1
    return
  end

  if S.selection < 1 then S.selection = 1 end
  if S.selection > #list then S.selection = #list end
  local max_first = math.max(1, #list - C.UI_ROWS + 1)
  if S.selection < S.window_first then S.window_first = S.selection end
  if S.selection >= S.window_first + C.UI_ROWS then
    S.window_first = S.selection - C.UI_ROWS + 1
  end
  if S.window_first < 1 then S.window_first = 1 end
  if S.window_first > max_first then S.window_first = max_first end
end

local function move_selection(delta)
  local list = visible_catalog()
  if #list == 0 then return end

  if S.selection == 0 then
    S.selection = (delta < 0) and #list or 1
  else
    S.selection = S.selection + delta
    if S.selection < 1 then S.selection = #list end
    if S.selection > #list then S.selection = 1 end
  end

  normalize_selection()
  S.status = "READY"
  S.ui_dirty = true
end

local function process_inputs()
  if not S.takeover then return end

  local c = read_controls()
  local start2 = read_2p_start()
  local start2_pressed = start2 and not S.last_2p_start
  local pressed = c & (~S.last_controls) & 0x3F
  local fire_pressed = (pressed & 0x30) ~= 0

  -- Play-all follows the WoW speech-browser model: 2P toggles the batch run.
  -- FIRE stops the current sound and lets the batch continue after its gap.
  if S.batch then
    if fire_pressed then stop_batch_sound() end
    if start2_pressed then stop_play_all() end
    if read_1p_start() then machine:exit() end
    S.last_controls = c
    S.last_2p_start = start2
    return
  end

  if start2_pressed then start_play_all() end

  -- WoW joystick decode, identical to the proven speech browser:
  -- bits 0/1 vertical, bits 2/3 horizontal, bits 4/5 fire.
  -- Horizontal movement is intentionally unused by this browser.

  local dir = 0
  if (c & 0x01) ~= 0 and (c & 0x02) == 0 then dir = -1
  elseif (c & 0x02) ~= 0 and (c & 0x01) == 0 then dir = 1 end

  if dir ~= 0 then
    if dir ~= S.hold_dir then
      S.hold_dir = dir
      S.hold_frames = 0
      move_selection(dir)
    else
      S.hold_frames = S.hold_frames + 1
      if S.hold_frames >= C.INPUT_INITIAL_REPEAT
         and ((S.hold_frames - C.INPUT_INITIAL_REPEAT) % C.INPUT_REPEAT_RATE) == 0 then
        move_selection(dir)
      end
    end
  else
    S.hold_dir = 0
    S.hold_frames = 0
  end

  if fire_pressed then
    local list = visible_catalog()
    local entry = list[S.selection]
    if entry then
      local active = active_entry()
      if active == entry then
        S.pending = nil
        request_native_reset("FIRE STOP " .. entry_key(entry))
      else
        local ok, err = queue_play(entry, "manual")
        if not ok then S.status = "ERROR " .. tostring(err) end
      end
    end
  end

  if read_1p_start() then machine:exit() end

  S.last_controls = c
  S.last_2p_start = start2
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
  if #s > width then s = s:sub(1, width) end
  if #s < width then s = s .. string.rep("@", width - #s) end
  return s
end

local function native_center(text)
  local s = transliterate_for_wow(text)
  if #s > 40 then s = s:sub(1, 40) end
  local col = math.max(0, (40 - #s) // 2)
  return s, col
end

local function native_center_row(text)
  local s, col = native_center(text)
  local row = string.rep("@", col) .. s
  if #row < 40 then row = row .. string.rep("@", 40 - #row) end
  if #row > 40 then row = row:sub(1,40) end
  return row
end

-- Center text containing WoW-native special glyph codes.  Preserve the
-- CHRTBL arrow codes (']' = up, '^' = down), but translate ordinary
-- separators to the character codes expected by WoW's renderer.
local function native_center_encoded_row(text)
  local src = tostring(text or "")
  local out = {}
  for i = 1, #src do
    local ch = src:sub(i,i)
    if ch == " " then
      out[#out+1] = "@"      -- WoW blank glyph
    elseif ch == "-" then
      out[#out+1] = "_"      -- WoW hyphen glyph
    else
      out[#out+1] = ch        -- includes CHRTBL special glyph codes
    end
  end

  local s = table.concat(out)
  if #s > 40 then s = s:sub(1, 40) end
  local col = math.max(0, (40 - #s) // 2)
  local row = string.rep("@", col) .. s
  if #row < 40 then row = row .. string.rep("@", 40 - #row) end
  return row
end

local function screen_de(row, col)
  return (((row * 5) & 0xFF) << 8) | ((col * 2) & 0xFF)
end

local function native_menu_lines()
  normalize_selection()
  local list = visible_catalog()
  local lines = {}

  -- Keep the complete browser UI inside WoW native text rows 0-11.
  -- Row 0 is the compact column header; the version is anchored at far right.
  lines[#lines+1] = {
    row=0, col=1,
    -- WoW's native character table does not use ASCII $20 as a blank glyph.
    -- Translate spaces before handing this unpadded header to printstr.
    text=transliterate_for_wow("REQ  LVL PRI  SEC  EVENT"),
    color=C.XPAND_BLUE,
  }

  local vmaj, vmin, vpatch = VERSION:match("^(%d+)%.(%d+)%.(%d+)")
  local short_version = vmaj and ("V" .. vmaj .. vmin .. vpatch) or "VER"
  lines[#lines+1] = {
    row=0,
    col=math.max(0, 40 - #short_version),
    text=short_version,
    color=C.XPAND_BLUE,
  }

  for row = 0, C.UI_ROWS - 1 do
    local index = S.window_first + row
    local entry = list[index]
    if entry then
      local primary = entry.primary and string.format("%04X", entry.primary) or "----"
      local secondary = entry.secondary and string.format("%04X", entry.secondary) or "----"
      local text = string.format("%-4s %d   %4s %4s %s",
        entry_key(entry), entry.priority, primary, secondary, entry.name)
      text = fixed_native_text(text, 39)

      local screen_row = 1 + row
      lines[#lines+1] = { row=screen_row, col=1, text=text, color=C.XPAND_RED }
      lines[#lines+1] = {
        row=screen_row,
        col=0,
        text=(index == S.selection) and "a" or "@",
        color=C.XPAND_YELLOW,
      }
    end
  end

  local p = engine_state(C.PRIMARY_SOUND_ENGINE_RECORD)
  local q = engine_state(C.SECONDARY_SOUND_ENGINE_RECORD)
  local live
  if S.status:match("^ERROR") then
    live = S.status
  else
    local pp = engine_visible_pointer(p)
    local qp = engine_visible_pointer(q)
    live = string.format("LIVE P %-6s %s  S %-6s %s",
      engine_phase(p), pp and string.format("%04X",pp) or "----",
      engine_phase(q), qp and string.format("%04X",qp) or "----")
  end
  -- Keep a clear separator between the catalog and live engine state.
  lines[#lines+1] = { row=8, col=0, text=fixed_native_text("",40), color=C.XPAND_BLUE }
  lines[#lines+1] = { row=9, col=0, text=fixed_native_text(live,40), color=C.XPAND_BLUE }

  -- Leave one blank row before the single-line control legend.
  lines[#lines+1] = { row=10, col=0, text=fixed_native_text("",40), color=C.XPAND_BLUE }
  local footer
  if S.batch then
    footer = "FIRE STOP SOUND 1P EXIT 2P STOP ALL"
  else
    local selected = list[S.selection]
    local fire_word = (selected and active_entry() == selected) and "STOP" or "PLAY"
    footer = string.format("]^ SELECT FIRE %s 1P EXIT 2P PLAY ALL", fire_word)
  end
  lines[#lines+1] = {
    row=11, col=0,
    text=native_center_encoded_row(footer),
    color=C.XPAND_YELLOW,
  }

  return lines
end
local function write_native_draw_program(lines)
  local data = C.DRAW_DATA
  local code = {}
  local function emit(v) code[#code+1] = v & 0xFF end
  local function emit16(v) emit(v); emit(v >> 8) end

  for _, line in ipairs(lines) do
    local text = line.text
    local addr = data
    for i = 1, #text do
      program:write_u8(data, text:byte(i))
      data = data + 1
    end

    emit(0x21); emit16(addr)                         -- LD HL,string
    emit(0x11); emit16(screen_de(line.row,line.col)) -- LD DE,screen position
    emit(0x06); emit(#text)                          -- LD B,length
    emit(0x3E); emit(line.color or C.XPAND_RED)      -- LD A,expand color
    emit(0xCD); emit16(C.PRINT_STRING_COLOR)         -- CALL WoW printstr entry
  end

  -- WoW printstr leaves interrupts disabled.  The browser foreground loop CALLs
  -- this generated display list, so re-enable interrupts and return normally.
  emit(0xFB)
  emit(0xC9)

  if C.DRAW_CODE + #code >= C.DRAW_DATA then
    return false, "native UI display list exceeds reserved RAM"
  end
  -- Leave at least $40 bytes below the private WoW browser stack top.
  if data >= C.CALL_STACK - 0x40 then
    return false, "native UI strings exceed reserved RAM"
  end

  for i, b in ipairs(code) do program:write_u8(C.DRAW_CODE + i - 1, b) end
  return true
end

local function render_ui_native()
  if not S.takeover or not S.ui_dirty or native_ui_busy() then return end

  local ok, err = write_native_draw_program(native_menu_lines())
  if not ok then
    S.status = "ERROR " .. tostring(err)
    printf("[WOW SOUND] %s", tostring(err))
    S.ui_dirty = false
    return
  end

  -- The resident $D400 loop notices this flag after $8003 returns and CALLs
  -- the generated display list.  Lua never needs to redirect PC for repainting.
  program:write_u8(C.UI_DRAW_PENDING, 1)
  S.ui_dirty = false
  S.draw_count = S.draw_count + 1
end

local function find_entry(arg)
  if type(arg) == "number" then
    local n = math.floor(arg)
    return CATALOG[n], n
  end

  if type(arg) == "string" then
    local g,b = arg:upper():match("R(%d)%.?B(%d)")
    g,b = tonumber(g), tonumber(b)
    if g and b then
      for i,e in ipairs(CATALOG) do
        if e.group == g and e.bit == b then return e,i end
      end
    end
  end

  return nil
end

local function print_entry(i, e)
  printf("[WOW SOUND] %2d  %-4s req=%s mask=%s pri=%d  %-5s %-5s  %s",
    i, entry_key(e), hex4(entry_request(e)), hex2(entry_mask(e)), e.priority,
    stream_text(e.primary,"P"), stream_text(e.secondary,"S"), e.name)
end

local function console_list()
  for i,e in ipairs(CATALOG) do print_entry(i,e) end
end

local function print_engine_state(label, base, ports)
  local st = engine_state(base)
  printf("[WOW SOUND] %-9s record=%s ports=%s phase=%s ptr=%s pri=%d ready=%02X wait=%02X mods=%d",
    label, hex4(base), ports, engine_phase(st), hex4(st.pointer), st.priority, st.ready, st.wait, st.modulators)
  printf("[WOW SOUND] %-9s regs TONMO=%02X A=%02X B=%02X C=%02X VIB=%02X VOLC=%02X VOLAB=%02X VOLN=%02X flag0C=%02X service=%02X",
    label, st.tonmo, st.tonea, st.toneb, st.tonec, st.vibra, st.volc, st.volab, st.voln, st.flag_0c, st.service)
end

local function console_state()
  print_engine_state("PRIMARY", C.PRIMARY_SOUND_ENGINE_RECORD, "$10-$17")
  print_engine_state("SECONDARY", C.SECONDARY_SOUND_ENGINE_RECORD, "$50-$57")
end

local function console_info()
  local list = visible_catalog()
  local e = list[S.selection]
  if not e then
    print("[WOW SOUND] no selected entry")
    return
  end
  local master_index
  for i,c in ipairs(CATALOG) do if c == e then master_index = i break end end
  print_entry(master_index or 0,e)
  console_state()
end

local function console_diag()
  printf("[WOW SOUND] version %s", VERSION)
  printf("[WOW SOUND] service jump %s  dispatcher jump %s  reset jump %s",
    hex4(C.SOUND_SERVICE_ENTRY), hex4(C.SOUND_REQUEST_DISPATCH_ENTRY), hex4(C.SOUND_RESET_ALL_ENTRY))
  printf("[WOW SOUND] requests: %s=%02X %s=%02X %s=%02X %s=%02X service_gate=%02X",
    hex4(C.SOUND_REQUEST_1), program:read_u8(C.SOUND_REQUEST_1),
    hex4(C.SOUND_REQUEST_2), program:read_u8(C.SOUND_REQUEST_2),
    hex4(C.SOUND_REQUEST_3), program:read_u8(C.SOUND_REQUEST_3),
    hex4(C.SOUND_REQUEST_4), program:read_u8(C.SOUND_REQUEST_4),
    program:read_u8(C.SOUND_SERVICE_ENABLED))
  printf("[WOW SOUND] stream decoder=%s table=%s install=%s fallback=%s",
    hex4(C.SOUND_STREAM_DECODER), hex4(C.SOUND_STREAM_OPCODE_TABLE),
    hex4(C.INSTALL_SOUND_STREAM), hex4(C.INVALID_STREAM_FALLBACK))
  local pc = cpu.state["PC"] and (cpu.state["PC"].value & 0xFFFF) or 0
  printf("[WOW SOUND] browser PC=%s ui_pending=%02X draws=%d",
    hex4(pc), program:read_u8(C.UI_DRAW_PENDING), S.draw_count)
  console_state()
end

local function console_input()
  local coin = io:read_u8(C.COINPORT)
  local p2 = io:read_u8(C.P2PORT)
  local p1 = io:read_u8(C.P1PORT)
  local c = ((~p1) | (~p2)) & 0x3F
  printf("[WOW SOUND] INPUT raw $10=%02X $11=%02X $12=%02X decoded=%02X", coin, p2, p1, c)
  printf("[WOW SOUND] INPUT up=%d down=%d left=%d right=%d fire=%d 1P=%d 2P=%d",
    (c & 0x01) ~= 0 and 1 or 0,
    (c & 0x02) ~= 0 and 1 or 0,
    (c & 0x04) ~= 0 and 1 or 0,
    (c & 0x08) ~= 0 and 1 or 0,
    (c & 0x30) ~= 0 and 1 or 0,
    read_1p_start() and 1 or 0,
    read_2p_start() and 1 or 0)
end

local function print_console_commands()
  print("")
  print("[WOW SOUND] console commands:")
  print("[WOW SOUND]   wsplay(n) or wsplay(\"R2B1\")  play one request event")
  print("[WOW SOUND]   wsall()                        play all 24 request events")
  print("[WOW SOUND]   wsstop()                       stop sound / stop play-all")
  print("[WOW SOUND]   wslist()                       list 24 audible request events")
  print("[WOW SOUND]   wsinfo()                       selected event + engine state")
  print("[WOW SOUND]   wsstate()                      native sound-engine state")
  print("[WOW SOUND]   wsdiag()                       anchors/request bytes/state")
  print("[WOW SOUND]   wsinput()                      raw/decoded WoW input state")
  print("[WOW SOUND]   wsexit()                       exit MAME")
  print("[WOW SOUND]   wshelp()                       show this list")
  print("")
end

local function install_console_shortcut(name, handler)
  local previous = rawget(_G,name)
  S.shortcuts[name] = { handler=handler, previous=previous, restore=previous ~= nil }
  rawset(_G,name,handler)
end

local function install_console_shortcuts()
  install_console_shortcut("wsplay", function(arg)
    local e,i = find_entry(arg)
    if not e then
      print("[WOW SOUND] usage: wsplay(1..24) or wsplay(\"R2B1\")")
      return false
    end
    printf("[WOW SOUND] selected catalog entry %d %s", i, entry_key(e))
    return queue_play(e, "manual")
  end)
  install_console_shortcut("wsall", start_play_all)
  install_console_shortcut("wsstop", function()
    if not S.takeover then return false end
    if S.batch then return stop_play_all() end
    S.pending = nil
    request_native_reset("STOPPING")
    return true
  end)
  install_console_shortcut("wslist", console_list)
  install_console_shortcut("wsinfo", console_info)
  install_console_shortcut("wsstate", console_state)
  install_console_shortcut("wsdiag", console_diag)
  install_console_shortcut("wsinput", console_input)
  install_console_shortcut("wsexit", function() machine:exit() end)
  install_console_shortcut("wshelp", print_console_commands)
end

local function restore_console_shortcuts()
  for name, shortcut in pairs(S.shortcuts) do
    if rawget(_G,name) == shortcut.handler then
      if shortcut.restore then rawset(_G,name,shortcut.previous)
      else rawset(_G,name,nil) end
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

  -- Keep WoW's runtime sound-service gate enabled while foreground gameplay is frozen.
  if program:read_u8(C.SOUND_SERVICE_ENABLED) == 0 then
    program:write_u8(C.SOUND_SERVICE_ENABLED,1)
  end

  process_inputs()
  service_pending()
  trace_tick()
  service_batch()

  local sig = engine_signature()
  if sig ~= S.last_engine_signature then
    S.last_engine_signature = sig
    S.ui_dirty = true
  end

  render_ui_native()
end

print("============================================================")
printf("[WOW SOUND] WIZARD OF WOR SOUND BROWSER %s", VERSION)
print("[WOW SOUND] runtime audio: original WoW request dispatcher + ROM stream decoder + sound engine")
print("[WOW SOUND] direct Astrocade sound-register writes from Lua: NONE")
print("[WOW SOUND] WoW inputs: P1=$12 P2=$11 START=$10; up/down select; FIRE play/stop; 2P play-all/stop; left/right unused")
printf("[WOW SOUND] foreground loop: %s; dispatcher: %s; UI flag: %s; native UI: %s",
  hex4(C.IDLE_LOOP), hex4(C.SOUND_REQUEST_DISPATCH_ENTRY), hex4(C.UI_DRAW_PENDING), hex4(C.DRAW_CODE))
install_console_shortcuts()
print_console_commands()
print("============================================================")

if emu.add_machine_frame_notifier then
  S.frame_subscription = emu.add_machine_frame_notifier(on_frame)
else
  emu.register_frame_done(on_frame,"wow_sound_browser")
end

if emu.add_machine_stop_notifier then
  S.stop_subscription = emu.add_machine_stop_notifier(function()
    S.enabled = false
    restore_console_shortcuts()
  end)
end

printf("[WOW SOUND] %s loaded from %s; takeover begins after %.1fs when startup speech and sound requests are idle",
  VERSION, BUILD_FILE, C.TAKEOVER_DELAY_SEC)
