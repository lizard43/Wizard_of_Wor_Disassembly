-- core/memory.lua
-- Wizard of Wor Lab memory map and byte helpers.
--
-- The lab never modifies ROM.  Work RAM and video RAM are used only after
-- foreground takeover.  WoW's resident sound/speech work area remains intact
-- so ROM services can be called by lab modules.

local M = {}
M.VERSION = '1.0.8-20260816-1847'

M.addr = {
  UI_DATA_START      = 0xD050,
  UI_DATA_END        = 0xD23F,

  RESIDENT_START     = 0xD240,
  RESIDENT_END       = 0xD37F,

  ABI_START          = 0xD380,
  ABI_END            = 0xD3BF,
  IM2_VECTOR         = 0xD3CA,

  NATIVE_START       = 0xD400,
  NATIVE_END         = 0xD7FF,
  MENU_CODE_START    = 0xD400,
  MENU_CODE_END      = 0xD5FF,
  DRAW_CODE_START    = 0xD600,
  DRAW_CODE_END      = 0xD6FF,

  VIDEO_START        = 0x4000,
  VISIBLE_VIDEO_END  = 0x7FBF, -- visible bitmap ends below WoW's stack margin
  VIDEO_END          = 0x7FFF, -- physical video RAM end
  STACK_BOTTOM       = 0x7FC0, -- non-visible 64-byte stack margin
  STACK_TOP          = 0x8000,
}

M.abi = {
  SIGNATURE          = 0xD380, -- four bytes: "WLAB"
  MODE               = 0xD384, -- 0 menu, 1 module
  SELECTED           = 0xD385,
  ITEM_COUNT         = 0xD386, -- number of discovered menu modules
  REQUEST            = 0xD387, -- 0 none, 1 launch, 2 menu, 3 exit MAME
  DRAW_PENDING       = 0xD388,
  HEARTBEAT          = 0xD389,
  INPUT_CURRENT      = 0xD38A,
  INPUT_PRESSED      = 0xD38B,
  INPUT_LAST         = 0xD38C,
  START_LAST         = 0xD38D,
  HOLD_DIRECTION     = 0xD38E, -- 0 none, 1 up, 2 down
  HOLD_COUNTDOWN     = 0xD38F,
  MODULE_EVENT       = 0xD390, -- free byte for module/supervisor handoff
  MODULE_ARG0        = 0xD391,
  MODULE_ARG1        = 0xD392,
  MODULE_ARG2        = 0xD393,
  MODULE_ARG3        = 0xD394,
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
