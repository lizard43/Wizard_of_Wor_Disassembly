-- core/memory.lua
-- Wizard of Wor Lab memory map and byte helpers.
--
-- The lab never modifies ROM.  The resident WoW sound/speech work area is
-- preserved so native lab applications can call the original ROM services.
-- The supervisor ABI and IM2 kernel live below the application workspace and
-- therefore remain available while an application owns $D400 and above.

local M = {}
M.VERSION = '1.1.0-20260816-1900'

M.addr = {
  -- Shared menu text buffer.  Applications may use their own buffers instead.
  UI_DATA_START       = 0xD050,
  UI_DATA_END         = 0xD23F,

  -- Resident WoW sound/speech state retained by the lab.
  RESIDENT_START      = 0xD240,
  RESIDENT_END        = 0xD37F,

  -- Permanent lab supervisor state.
  ABI_START           = 0xD380,
  ABI_END             = 0xD3BF,
  KERNEL_START        = 0xD3C0,
  KERNEL_END          = 0xD3FD,
  IM2_VECTOR          = 0xD3FE, -- two-byte IM2 vector; points into KERNEL_START

  -- Swappable native application workspace.  The menu and each real module
  -- may replace this region without touching the resident ABI/kernel.
  APPLICATION_START   = 0xD400,
  APPLICATION_END     = 0xDFFF,

  MENU_CODE_START     = 0xD400,
  MENU_CODE_END       = 0xD5FF,
  DRAW_CODE_START     = 0xD600,
  DRAW_CODE_END       = 0xD6FF,

  -- Compatibility aliases for code that describes the active native image.
  NATIVE_START        = 0xD400,
  NATIVE_END          = 0xDFFF,

  VIDEO_START         = 0x4000,
  VISIBLE_VIDEO_END   = 0x7FBF, -- visible bitmap ends below the menu stack margin
  VIDEO_END           = 0x7FFF,
  STACK_BOTTOM        = 0x7FC0, -- non-visible 64-byte menu stack margin
  STACK_TOP           = 0x8000,
}

M.abi = {
  SIGNATURE           = 0xD380, -- four bytes: "WLAB"
  MODE                = 0xD384, -- 0 menu, nonzero active module/application
  SELECTED            = 0xD385,
  ITEM_COUNT          = 0xD386, -- number of discovered menu modules
  REQUEST             = 0xD387, -- 0 none, 1 launch, 2 return to menu, 3 exit MAME
  DRAW_PENDING        = 0xD388,
  HEARTBEAT           = 0xD389,
  INPUT_CURRENT       = 0xD38A,
  INPUT_PRESSED       = 0xD38B,
  INPUT_LAST          = 0xD38C,
  START_LAST          = 0xD38D,
  HOLD_DIRECTION      = 0xD38E, -- 0 none, 1 up, 2 down
  HOLD_COUNTDOWN      = 0xD38F,
  MODULE_EVENT        = 0xD390, -- free byte for module/supervisor handoff
  MODULE_ARG0         = 0xD391,
  MODULE_ARG1         = 0xD392,
  MODULE_ARG2         = 0xD393,
  MODULE_ARG3         = 0xD394,
}

function M.write_bytes(space, address, bytes)
  for i, byte in ipairs(bytes) do
    space:write_u8(address + i - 1, byte & 0xFF)
  end
end

function M.read_bytes(space, address, length)
  local out = {}
  for i = 0, length - 1 do out[#out + 1] = space:read_u8(address + i) end
  return out
end

function M.fill(space, first, last, value)
  value = (value or 0) & 0xFF
  for address = first, last do space:write_u8(address, value) end
end

return M
