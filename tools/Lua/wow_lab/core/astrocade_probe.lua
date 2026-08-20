-- core/astrocade_probe.lua
-- Astrocade Lab boot/runtime I/O latch observer for MAME 0.289+.
--
-- This core is deliberately game-neutral.  It observes actual CPU I/O traffic
-- and remembers the last value written/read at Astrocade hardware ports.  It
-- never patches ROM, writes emulated hardware, or changes CPU execution.
--
-- Output ports on Astrocade hardware frequently have unrelated read-side
-- meanings, so an information screen cannot reconstruct video/audio latches by
-- simply issuing IN instructions later.  This probe records the real writes as
-- they occur, beginning before the game finishes booting.

local M = {}
M.VERSION = '1.2.0-20260820-0925'

local Probe = {}
Probe.__index = Probe

local function find_space(cpu, ...)
  if not cpu or not cpu.spaces then return nil end
  for i = 1, select('#', ...) do
    local name = select(i, ...)
    local ok, space = pcall(function() return cpu.spaces[name] end)
    if ok and space then return space end
  end
  return nil
end

local function find_cpu(machine)
  if not machine or not machine.devices then return nil end
  return machine.devices[':maincpu'] or machine.devices[':cpu']
end

local function remove_tap(tap)
  if not tap then return end
  pcall(function()
    if type(tap.remove) == 'function' then tap:remove() end
  end)
end

local function unsubscribe(subscription)
  if not subscription then return end
  pcall(function()
    if type(subscription.unsubscribe) == 'function' then subscription:unsubscribe() end
  end)
end

local function copy_entry(entry)
  if not entry then return nil end
  return {
    value = entry.value,
    count = entry.count,
    raw_address = entry.raw_address,
    sequence = entry.sequence,
    source_kind = entry.source_kind,
    source_port = entry.source_port,
  }
end

local function copy_port_table(source)
  local out = {}
  for port, entry in pairs(source or {}) do out[port] = copy_entry(entry) end
  return out
end

local function copy_snapshot(snapshot)
  if not snapshot then return nil end
  return {
    version = snapshot.version,
    active = snapshot.active,
    detail = snapshot.detail,
    sequence = snapshot.sequence,
    write_count = snapshot.write_count,
    read_count = snapshot.read_count,
    writes = copy_port_table(snapshot.writes),
    reads = copy_port_table(snapshot.reads),
    speech = copy_entry(snapshot.speech),
  }
end

local function write_port_is_interesting(port)
  if port >= 0x00 and port <= 0x19 then return true end -- video + primary sound + XPAND
  if port >= 0x50 and port <= 0x58 then return true end -- secondary sound
  if port == 0x5B then return true end                  -- protected/NVRAM write control
  if port >= 0x78 and port <= 0x7E then return true end -- Pattern Board
  return false
end

local function read_port_is_interesting(port)
  -- Video feedback aliases and the SC-01 address-bus strobe. Cabinet controls
  -- are intentionally not sampled by the global probe; modules read them natively.
  return port == 0x08 or port == 0x0C or port == 0x0E or port == 0x0F or port == 0x17
end

local function block_target_port(port, raw_address)
  -- Astrocade block ports use the upper Z80 I/O address bits as the register
  -- selector. MAME exposes that complete address to the tap. For Z80 OTIR/OUTI
  -- the observed high byte is the effective 0..7 selector, matching the
  -- hardware register number within the selected block.
  local selector = ((tonumber(raw_address) or 0) >> 8) & 0x07
  if port == 0x0B then return selector end          -- palette register $00-$07
  if port == 0x18 then return 0x10 + selector end   -- primary sound $10-$17
  if port == 0x58 then return 0x50 + selector end   -- secondary sound $50-$57
  return nil
end

local function store_entry(table_ref, port, raw_address, data, sequence, source_kind, source_port)
  local previous = table_ref[port]
  table_ref[port] = {
    value = (tonumber(data) or 0) & 0xFF,
    count = (previous and previous.count or 0) + 1,
    raw_address = raw_address,
    sequence = sequence,
    source_kind = source_kind or 'direct',
    source_port = source_port,
  }
end

function M.new(machine)
  local cpu = find_cpu(machine)
  local io = find_space(cpu, 'io', 'i/o')
  return setmetatable({
    machine = machine,
    cpu = cpu,
    io = io,
    active = false,
    detail = 'not started',
    sequence = 0,
    write_count = 0,
    read_count = 0,
    writes = {},
    reads = {},
    speech = nil,
    frozen_snapshots = {},
    write_observers = {},
    next_write_observer_id = 1,
    write_tap = nil,
    read_tap = nil,
    io_notifier = nil,
    stop_subscription = nil,
  }, Probe)
end

function Probe:_record(table_ref, raw_address, data, is_write, mask)
  raw_address = (tonumber(raw_address) or 0) & 0xFFFF
  local port = raw_address & 0xFF
  if is_write then
    if not write_port_is_interesting(port) then return end
    self.write_count = self.write_count + 1
  else
    if not read_port_is_interesting(port) then return end
    self.read_count = self.read_count + 1
  end

  self.sequence = self.sequence + 1
  store_entry(table_ref, port, raw_address, data, self.sequence, 'direct', nil)

  -- $0B/$18/$58 are block-transfer ports. Retain the bus write itself above,
  -- and also project it into the physical latch it actually updates. This is
  -- what makes palette and sound register images complete when a game uses
  -- OTIR/OUTI instead of individual OUT instructions.
  if is_write then
    local target = block_target_port(port, raw_address)
    if target ~= nil then
      store_entry(table_ref, target, raw_address, data, self.sequence, 'block', port)
    end
  end

  -- WoW/Gorf place the SC-01 command on the upper Z80 I/O address byte and
  -- perform IN (C) with C=$17.  Preserve the complete 16-bit port address so a
  -- hardware-information module can report that bus transaction without
  -- pretending it is an ordinary read-side register.
  if not is_write and port == 0x17 then
    local previous_speech = self.speech
    self.speech = {
      value = (raw_address >> 8) & 0xFF,
      count = (previous_speech and previous_speech.count or 0) + 1,
      raw_address = raw_address,
      sequence = self.sequence,
    }
  end

  -- A single MAME I/O tap is shared by Lab modules that need the raw write
  -- stream. This avoids overlapping full-I/O taps, which are unsafe in MAME
  -- 0.289 when modules install/remove their own observers at runtime.
  if is_write then
    for _, callback in pairs(self.write_observers) do
      pcall(callback, raw_address, data, mask)
    end
  end
end

function Probe:_install_taps()
  if not self.io then
    self.detail = 'CPU I/O address space unavailable'
    return false, self.detail
  end

  remove_tap(self.write_tap)
  remove_tap(self.read_tap)
  self.write_tap, self.read_tap = nil, nil

  local limit = tonumber(self.io.address_mask) or 0xFFFF
  local write_ok, write_result = pcall(function()
    return self.io:install_write_tap(0, limit, 'astrocade-lab-probe-write',
      function(offset, data, _mask)
        if not self.active then return end
        self:_record(self.writes, offset, data, true, _mask)
      end)
  end)
  if write_ok then self.write_tap = write_result end

  local read_ok, read_result = pcall(function()
    return self.io:install_read_tap(0, limit, 'astrocade-lab-probe-read',
      function(offset, data, _mask)
        if not self.active then return end
        self:_record(self.reads, offset, data, false, _mask)
      end)
  end)
  if read_ok then self.read_tap = read_result end

  if write_ok and read_ok then
    self.detail = 'read/write I/O taps active'
    return true, self.detail
  end

  self.detail = string.format('write %s; read %s',
    write_ok and 'active' or ('failed: ' .. tostring(write_result)),
    read_ok and 'active' or ('failed: ' .. tostring(read_result)))
  return write_ok or read_ok, self.detail
end

function Probe:start()
  if self.active then return true, self.detail end
  if not self.machine then
    self.detail = 'MAME running machine unavailable'
    return false, self.detail
  end
  if not self.cpu then
    self.detail = 'main CPU device unavailable'
    return false, self.detail
  end
  if not self.io then
    self.detail = 'CPU I/O address space unavailable'
    return false, self.detail
  end

  self.active = true
  local ok, detail = self:_install_taps()
  if not ok then self.active = false; return false, detail end

  if self.io.add_change_notifier then
    local notify_ok, subscription = pcall(function()
      return self.io:add_change_notifier(function(kind)
        if not self.active then return end
        if (kind == 'w' or kind == 'rw') and self.write_tap
            and type(self.write_tap.reinstall) == 'function' then
          pcall(function() self.write_tap:reinstall() end)
        end
        if (kind == 'r' or kind == 'rw') and self.read_tap
            and type(self.read_tap.reinstall) == 'function' then
          pcall(function() self.read_tap:reinstall() end)
        end
      end)
    end)
    if notify_ok then self.io_notifier = subscription end
  end

  if emu and emu.add_machine_stop_notifier then
    self.stop_subscription = emu.add_machine_stop_notifier(function() self:stop(true) end)
  end
  return true, self.detail
end


function Probe:add_write_observer(callback)
  assert(type(callback) == 'function', 'write observer must be a function')
  local id = self.next_write_observer_id
  self.next_write_observer_id = id + 1
  self.write_observers[id] = callback

  local owner = self
  local subscribed = true
  return {
    unsubscribe = function()
      if not subscribed then return end
      subscribed = false
      owner.write_observers[id] = nil
    end,
  }
end

function Probe:stop(machine_stopping)
  if not self.active and not self.write_tap and not self.read_tap then return end
  self.active = false
  self.write_observers = {}
  unsubscribe(self.io_notifier)
  self.io_notifier = nil
  remove_tap(self.write_tap)
  remove_tap(self.read_tap)
  self.write_tap, self.read_tap = nil, nil
  if not machine_stopping then unsubscribe(self.stop_subscription) end
  self.stop_subscription = nil
  self.detail = machine_stopping and 'machine stopped' or 'stopped'
end

function Probe:snapshot()
  return {
    version = M.VERSION,
    active = self.active,
    detail = self.detail,
    sequence = self.sequence,
    write_count = self.write_count,
    read_count = self.read_count,
    writes = copy_port_table(self.writes),
    reads = copy_port_table(self.reads),
    speech = copy_entry(self.speech),
  }
end

function Probe:freeze(name, replace)
  name = tostring(name or 'snapshot')
  if self.frozen_snapshots[name] and not replace then
    return copy_snapshot(self.frozen_snapshots[name])
  end
  local snapshot = self:snapshot()
  self.frozen_snapshots[name] = snapshot
  return copy_snapshot(snapshot)
end

function Probe:frozen(name)
  return copy_snapshot(self.frozen_snapshots[tostring(name or 'snapshot')])
end

function Probe:last_write(port, snapshot)
  port = (tonumber(port) or 0) & 0xFF
  local source = snapshot and snapshot.writes or self.writes
  return copy_entry(source and source[port])
end

function Probe:last_read(port, snapshot)
  port = (tonumber(port) or 0) & 0xFF
  local source = snapshot and snapshot.reads or self.reads
  return copy_entry(source and source[port])
end

M.Probe = Probe
return M
