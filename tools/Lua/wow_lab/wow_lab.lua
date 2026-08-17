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
local Lab = load_core('lab')

print('============================================================')
print('[WOW LAB] WIZARD OF WOR LAB 1.0.6-20260816-1830')
print('[WOW LAB] entry module: wow_lab.lua')
print('[WOW LAB] native menu + resident Lua supervisor')
print('[WOW LAB] ROM patching: NONE')
print(string.format('[WOW LAB] core versions: lab=%s native=%s memory=%s loader=%s path=%s',
  tostring(Lab.VERSION), tostring(Native.VERSION), tostring(Memory.VERSION),
  tostring(ModuleLoader.VERSION), tostring(Path.VERSION)))
print('============================================================')

local lab = Lab.new(root, Path, Memory, Native, ModuleLoader)
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
local function print_console_help()
  print('[WOW LAB] console commands:')
  print('[WOW LAB]   wlstatus()   supervisor/CPU state')
  print('[WOW LAB]   wlmodules()  discovered module list')
  print('[WOW LAB]   wlnative()   ABI/vector/native state')
  print('[WOW LAB]   wlmenu()     reinstall and redraw lab menu')
  print('[WOW LAB]   wlexit()     exit MAME')
end

install_console_shortcut('wlhelp', print_console_help)

-- Retain the notifier subscription for the life of the resident supervisor.
lab.console_stop_subscription = emu.add_machine_stop_notifier(function()
  restore_console_shortcuts()
  if rawget(_G, 'WowLab') == lab then rawset(_G, 'WowLab', nil) end
end)

print_console_help()
