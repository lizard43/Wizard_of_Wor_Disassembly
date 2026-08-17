-- core/lab.lua
-- Resident Wizard of Wor Lab supervisor.

local Lab = {}
Lab.__index = Lab
Lab.VERSION = '1.0.8-20260816-1847'

function Lab.new(root, path_api, memory, Native, ModuleLoader)
  local machine = assert(manager and manager.machine, 'MAME running machine is unavailable')
  local native = Native.new(machine, memory)
  local modules_path = path_api.join(root, 'modules')

  return setmetatable({
    root = root,
    path = path_api,
    memory = memory,
    machine = machine,
    native = native,
    loader = ModuleLoader.new(modules_path, path_api),
    modules = {},
    active = nil,
    state = 'BOOT',
    boot_frames = 0,
    takeover_frames = 120,
    last_selected = -1,
    status = '',
    frame_subscription = nil,
    stop_subscription = nil,
  }, Lab)
end

function Lab:log(fmt, ...)
  print(string.format('[WOW LAB] ' .. fmt, ...))
end

function Lab:scan_modules()
  local ok, result = pcall(function() return self.loader:scan() end)
  if not ok then
    self.modules = {}
    self.status = 'MODULE SCAN ERROR'
    self:log('module scan failed: %s', tostring(result))
    return false
  end
  if #result > 255 then
    self:log('module directory contains %d entries; only the first 255 can be addressed by the native ABI', #result)
    while #result > 255 do table.remove(result) end
  end
  self.modules = result
  self:log('discovered %d module%s', #self.modules, #self.modules == 1 and '' or 's')
  return true
end

local function menu_window(selected, count, visible)
  if count <= visible then return 0 end
  local first = selected - math.floor(visible / 2)
  if first < 0 then first = 0 end
  if first > count - visible then first = count - visible end
  return first
end

function Lab:_menu_entries()
  local entries = {}
  for _, entry in ipairs(self.modules) do entries[#entries + 1] = entry.label end
  return entries
end

function Lab:_menu_row_line(entries, first, selected, index)
  local colors = self.native.colors
  local visible_row = index - first
  local label = entries[index + 1]
  if not label or visible_row < 0 or visible_row >= 8 then return nil end

  label = label:sub(1, 34)
  local is_selected = index == selected
  return {
    row = visible_row + 2,
    col = 2,
    text = (is_selected and '> ' or '  ') .. label,
    color = is_selected and colors.YELLOW or colors.RED,
  }
end

function Lab:draw_menu()
  local colors = self.native.colors
  local entries = self:_menu_entries()
  local selected = self.native:selected()
  local first = menu_window(selected, #entries, 8)
  local lines = {
    { row = 0, col = 4, text = 'WIZARD OF WOR LAB', color = colors.BLUE },
  }

  for index = first, math.min(first + 7, #entries - 1) do
    lines[#lines + 1] = self:_menu_row_line(entries, first, selected, index)
  end

  -- CHRTBL codes ']' and '^' are the resident up/down arrow glyphs.
  lines[#lines + 1] = { row = 11, col = 2, text = '] ^ - FIRE SELECT - 1P EXIT', color = colors.YELLOW }
  self.native:draw(lines, true)
  self.menu_first = first
end

function Lab:redraw_menu_selection(old_selected, new_selected)
  local entries = self:_menu_entries()
  local old_first = self.menu_first or menu_window(old_selected, #entries, 8)
  local new_first = menu_window(new_selected, #entries, 8)

  -- Crossing a scroll-window boundary changes more than two visible rows.
  if old_first ~= new_first then
    self:draw_menu()
    return
  end

  local lines = {}
  local old_line = self:_menu_row_line(entries, new_first, new_selected, old_selected)
  local new_line = self:_menu_row_line(entries, new_first, new_selected, new_selected)
  if old_line then lines[#lines + 1] = old_line end
  if new_line and new_selected ~= old_selected then lines[#lines + 1] = new_line end
  if #lines > 0 then self.native:draw(lines, false) end
  self.menu_first = new_first
end

function Lab:show_module_page(title, body)
  local colors = self.native.colors
  local lines = {
    { row = 0, col = 3, text = tostring(title or 'MODULE'), color = colors.BLUE },
  }
  for i, text in ipairs(body or {}) do
    if i > 8 then break end
    lines[#lines + 1] = { row = i + 2, col = 3, text = tostring(text), color = colors.RED }
  end
  lines[#lines + 1] = { row = 11, col = 3, text = '1P - RETURN TO LAB', color = colors.YELLOW }
  self.native:draw(lines)
end

function Lab:enter_menu(reason)
  if self.active then
    local module = self.active
    self.active = nil
    if module.stop then
      local ok, err = pcall(module.stop, self)
      if not ok then self:log('module stop error: %s', tostring(err)) end
    end
  end

  self:scan_modules()
  self.native:install(#self.modules)
  self.native:set_mode(0)
  self.state = 'MENU'
  self.last_selected = self.native:selected()
  self.status = reason or ''
  self:draw_menu()
end

function Lab:launch_selected()
  local selected = self.native:selected()
  if selected >= #self.modules then return end

  self.native:clear_request()
  local module, err = self.loader:load(selected + 1)
  if not module then
    self:log('module load failed: %s', tostring(err))
    self:show_module_page('MODULE LOAD ERROR', { self.modules[selected + 1].label, tostring(err):sub(1, 34) })
    self.native:set_mode(1)
    self.state = 'MODULE_ERROR'
    return
  end

  self.active = module
  self.state = 'MODULE'
  self.native:set_mode(1)
  self:log('launch %s', module.__entry.label)

  if module.start then
    local ok, start_err = pcall(module.start, self)
    if not ok then
      self:log('module start error: %s', tostring(start_err))
      self:show_module_page('MODULE START ERROR', { module.__entry.label, tostring(start_err):sub(1, 34) })
      self.state = 'MODULE_ERROR'
    end
  end
end

function Lab:return_to_menu(reason)
  self:enter_menu(reason or 'RETURN')
end

function Lab:exit_mame()
  self:log('exit requested')
  self.state = 'EXIT'
  self.machine:exit()
end

function Lab:update()
  if self.state == 'BOOT' then
    self.boot_frames = self.boot_frames + 1
    if self.boot_frames >= self.takeover_frames then self:enter_menu('READY') end
    return
  end

  if self.state == 'MENU' then
    local selected = self.native:selected()
    if selected ~= self.last_selected then
      local previous = self.last_selected
      self.last_selected = selected
      self:redraw_menu_selection(previous, selected)
    end

    local request = self.native:request()
    if request == 1 then
      self:launch_selected()
    elseif request == 3 then
      self.native:clear_request()
      self:exit_mame()
    elseif request ~= 0 then
      self.native:clear_request()
    end
    return
  end

  if self.state == 'MODULE' or self.state == 'MODULE_ERROR' then
    local request = self.native:request()
    if request == 2 then
      self.native:clear_request()
      self:return_to_menu('RETURN')
      return
    elseif request == 3 then
      self.native:clear_request()
      self:exit_mame()
      return
    end

    if self.state == 'MODULE' and self.active and self.active.update then
      local ok, err = pcall(self.active.update, self)
      if not ok then
        self:log('module update error: %s', tostring(err))
        self:show_module_page('MODULE RUNTIME ERROR', { self.active.__entry.label, tostring(err):sub(1, 34) })
        self.state = 'MODULE_ERROR'
      end
    end
  end
end


function Lab:print_status()
  local pc = self.native.cpu.state['PC'] and self.native.cpu.state['PC'].value or 0
  local sp = self.native.cpu.state['SP'] and self.native.cpu.state['SP'].value or 0
  self:log('state=%s frames=%d installed=%s active=%s',
    tostring(self.state), self.boot_frames, tostring(self.native.installed),
    self.active and self.active.__entry.label or 'NONE')
  self:log('PC=$%04X SP=$%04X selected=%d request=%d heartbeat=%d',
    pc & 0xFFFF, sp & 0xFFFF, self.native:selected(), self.native:request(),
    self.native.program:read_u8(self.memory.abi.HEARTBEAT))
end

function Lab:print_modules()
  self:log('%d module%s discovered', #self.modules, #self.modules == 1 and '' or 's')
  for i, entry in ipairs(self.modules) do
    print(string.format('[WOW LAB]   %2d  %-28s  %s', i, entry.label, entry.filename))
  end
end

function Lab:print_native()
  local p = self.native.program
  local A = self.memory.addr
  local B = self.memory.abi
  local sig = {}
  for i = 0, 3 do sig[#sig + 1] = string.char(p:read_u8(B.SIGNATURE + i)) end
  local vec_lo = p:read_u8(A.IM2_VECTOR)
  local vec_hi = p:read_u8(A.IM2_VECTOR + 1)
  local vector = vec_lo | (vec_hi << 8)
  local entry = self.native.labels.entry or 0
  local interrupt = self.native.labels.interrupt or 0
  self:log('signature=%q mode=%d selected=%d count=%d request=%d draw=%d heartbeat=%d',
    table.concat(sig), p:read_u8(B.MODE), p:read_u8(B.SELECTED),
    p:read_u8(B.ITEM_COUNT), p:read_u8(B.REQUEST), p:read_u8(B.DRAW_PENDING),
    p:read_u8(B.HEARTBEAT))
  self:log('entry=$%04X interrupt=$%04X vector=$%04X',
    entry & 0xFFFF, interrupt & 0xFFFF, vector & 0xFFFF)
end

function Lab:start()
  self:log('resident supervisor starting')
  self:log('module directory: %s', self.loader.path)
  self:scan_modules()

  self.frame_subscription = emu.add_machine_frame_notifier(function() self:update() end)
  self.stop_subscription = emu.add_machine_stop_notifier(function()
    self.state = 'STOPPED'
    self.active = nil
  end)
end

return Lab
