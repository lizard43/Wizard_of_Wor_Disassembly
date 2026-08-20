-- wow_lab.lua
-- Wizard of Wor Lab command-line entry point for MAME 0.289+.
--
-- Run from any working directory:
--   mame wow -autoboot_script /path/to/wow_lab/wow_lab.lua
--
-- Lua remains resident as the lab supervisor.  Native Z80 code owns the menu,
-- cabinet input, WoW rendering calls, and ROM-service cadence after takeover.
-- Modules are discovered from the sibling modules directory.

local source = debug.getinfo(1, 'S').source
if source:sub(1, 1) == '@' then source = source:sub(2) end
source = source:gsub('\\', '/')
local root = source:match('^(.*)/[^/]*$') or '.'

local function load_core(name)
  local filename = string.format('%s/core/%s.lua', root, name)
  return assert(loadfile(filename))()
end

local Path = load_core('path')
local Memory = load_core('memory')
local Native = load_core('native')
local ModuleLoader = load_core('module_loader')
local VideoDebug = load_core('video_debug')
local LabFonts = load_core('lab_fonts')
local LabText = load_core('lab_text')
local AstrocadeProbe = load_core('astrocade_probe')
local Lab = load_core('lab')

-- Start hardware observation before the game's two-second Lab takeover point so
-- boot-time output latches are captured from the writes that actually program
-- them.  Failure is non-fatal: the information module will report it plainly.
local hardware_probe = AstrocadeProbe.new(assert(manager and manager.machine, 'MAME running machine is unavailable'))
local probe_ok, probe_detail = hardware_probe:start()

print('============================================================')
print(string.format('[WOW LAB] WIZARD OF WOR LAB %s', tostring(Lab.VERSION)))
print('[WOW LAB] entry module: wow_lab.lua')
print('[WOW LAB] native menu + resident Lua supervisor')
print('[WOW LAB] ROM patching: NONE')
print(string.format('[WOW LAB] core versions: lab=%s native=%s memory=%s loader=%s video=%s fonts=%s text=%s probe=%s path=%s',
  tostring(Lab.VERSION), tostring(Native.VERSION), tostring(Memory.VERSION),
  tostring(ModuleLoader.VERSION), tostring(VideoDebug.VERSION), tostring(LabFonts.VERSION),
  tostring(LabText.VERSION), tostring(AstrocadeProbe.VERSION), tostring(Path.VERSION)))
print(string.format('[WOW LAB] Astrocade I/O probe: %s%s',
  probe_ok and 'ACTIVE - ' or 'UNAVAILABLE - ', tostring(probe_detail)))
local tiny = LabText.metrics(LabFonts, 'tiny')
local compact = LabText.metrics(LabFonts, 'compact')
print(string.format('[WOW LAB] lab fonts: tiny=%dx%d/%dx%d cell (%dx%d); compact=%dx%d/%dx%d cell (%dx%d)',
  tiny.glyph_width, tiny.glyph_height, tiny.cell_width, tiny.cell_height, tiny.columns, tiny.rows,
  compact.glyph_width, compact.glyph_height, compact.cell_width, compact.cell_height, compact.columns, compact.rows))
print('============================================================')

local lab = Lab.new(root, Path, Memory, Native, ModuleLoader, VideoDebug, LabFonts, LabText, hardware_probe)
rawset(_G, 'WowLab', lab)
lab:start()

-- MAME executes -autoboot_script inside a sandbox environment.  Console
-- shortcuts must therefore be installed explicitly in the Lua state's real
-- global table, matching the established browser shortcut convention.
local shortcuts = {}

local function install_console_shortcut(name, handler)
  local previous = rawget(_G, name)
  shortcuts[name] = { handler = handler, previous = previous, restore = previous ~= nil }
  rawset(_G, name, handler)
end

local function restore_console_shortcuts()
  for name, shortcut in pairs(shortcuts) do
    if rawget(_G, name) == shortcut.handler then
      rawset(_G, name, shortcut.restore and shortcut.previous or nil)
    end
  end
  shortcuts = {}
end

install_console_shortcut('wlstatus', function() return lab:print_status() end)
install_console_shortcut('wlmodules', function() return lab:print_modules() end)
install_console_shortcut('wlnative', function() return lab:print_native() end)
install_console_shortcut('wlmenu', function() return lab:return_to_menu('CONSOLE') end)
install_console_shortcut('wlexit', function() return lab:exit_mame() end)
install_console_shortcut('wlhelp', function()
  print('[WOW LAB] console commands:')
  print('[WOW LAB]   wlstatus()   supervisor/CPU state')
  print('[WOW LAB]   wlmodules()  discovered module list')
  print('[WOW LAB]   wlnative()   ABI/vector/native state')
  print('[WOW LAB]   wlmenu()     reinstall and redraw lab menu')
  print('[WOW LAB]   wlexit()     exit MAME')
end)

-- Retain the notifier subscription for the life of the resident supervisor.
lab.console_stop_subscription = emu.add_machine_stop_notifier(function()
  restore_console_shortcuts()
  if rawget(_G, 'WowLab') == lab then rawset(_G, 'WowLab', nil) end
end)

print('[WOW LAB] console shortcuts installed globally: wlhelp()')
