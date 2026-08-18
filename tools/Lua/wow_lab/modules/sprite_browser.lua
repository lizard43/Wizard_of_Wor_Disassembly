-- modules/sprite_browser.lua
-- Wizard of Wor Lab native sprite browser.
--
-- The module renders Wizard of Wor ROM sprites through the game's resident
-- fixed-size actor blitter at $0B92.  The one exception is 90-degree rotation:
-- Astrocade Magic requires the documented eight-write 4x4-tile protocol, which
-- native Z80 performs directly from the same ROM source.  Native Z80 owns the
-- complete visible interface and action records; Lua decodes diagnostics only.

local M = {}
M.VERSION = '1.3.4-20260817-1809'

local C = {
  -- Resident Wizard of Wor code and cabinet ports.
  PRINT_STRING_COLOR      = 0x03B5,
  DRAW_ACTOR_RECORD       = 0x0B92,
  COINPORT                = 0x10,
  P2PORT                  = 0x11,
  P1PORT                  = 0x12,

  -- Native application workspace.  $D380-$D3FF remains Lab-owned.
  NATIVE_CODE             = 0xD400,
  NATIVE_CODE_END         = 0xDCBF,

  CATALOG_TABLE           = 0xDCC0, -- 104 little-endian ROM addresses
  CELL_DEST_TABLE         = 0xDD90, -- 32 Magic-RAM destination offsets
  BORDER_DEST_TABLE       = 0xDDD0, -- 32 physical VRAM border addresses
  LABEL_DEST_TABLE        = 0xDE10, -- 32 Magic-RAM text destinations

  STATE_BASE              = 0xDE50,
  STATE_SELECTED          = 0xDE50,
  STATE_SELECTED_COL      = 0xDE51,
  STATE_SELECTED_ROW      = 0xDE52,
  STATE_FIRST_ROW         = 0xDE53,
  STATE_FIRST_INDEX       = 0xDE54,
  STATE_INPUT_CURRENT     = 0xDE55,
  STATE_FIRE_LAST         = 0xDE56,
  STATE_HOLD_DIRECTION    = 0xDE57,
  STATE_HOLD_COUNTDOWN    = 0xDE58,
  STATE_EVENT_SEQUENCE    = 0xDE59,
  STATE_EVENT_TYPE        = 0xDE5A, -- 1 selection, 2 Fire diagnostic, 3 menu
  STATE_REDRAW_SEQUENCE   = 0xDE5B,
  STATE_REDRAW_REQUEST    = 0xDE5C,
  STATE_OLD_SELECTED      = 0xDE5D,
  STATE_OLD_FIRST_ROW     = 0xDE5E,
  STATE_DRAW_INDEX        = 0xDE5F,
  STATE_DRAW_SLOT         = 0xDE60,
  STATE_BORDER_FILL       = 0xDE61,
  STATE_BORDER_LEFT       = 0xDE62,
  STATE_BORDER_RIGHT      = 0xDE63,
  STATE_DRAW_ROW          = 0xDE64,
  STATE_DRAW_COL          = 0xDE65,
  STATE_OLD_SELECTED_COL  = 0xDE66,
  STATE_START_LAST        = 0xDE67,
  STATE_MENU_ACTIVE       = 0xDE68,
  STATE_SELECTED_VIEW_ROW = 0xDE69,
  STATE_OLD_VIEW_ROW      = 0xDE6A,
  STATE_MENU_ITEM         = 0xDE6B,
  STATE_MAGIC_SHIFT       = 0xDE6C,
  STATE_MAGIC_ROTATE      = 0xDE6D,
  STATE_MAGIC_HFLIP       = 0xDE6E,
  STATE_MAGIC_VFLIP       = 0xDE6F,
  STATE_MAGIC_BLEND       = 0xDE70,
  STATE_MAGIC_MODE        = 0xDE71,
  STATE_LAST_ACTION       = 0xDE72,
  STATE_RENDER_ENTRY      = 0xDE73, -- actual final renderer, little-endian
  STATE_ROTATE_TILE_X     = 0xDE75,
  STATE_ROTATE_TILE_Y     = 0xDE76,
  STATE_ROTATE_ROWS       = 0xDE77,
  STATE_END               = 0xDE77,

  DRAW_RECORD             = 0xDE78, -- five-byte resident $0B92 descriptor
  ROTATE_SOURCE_ROW       = 0xDE7D, -- first source row of current 4-row band
  TEXT_BUFFER             = 0xDE80, -- four resident-font address glyphs
  STATE_ROTATE_WRITES     = 0xDE84, -- completed Magic writes; 200 expected
  STATE_LABEL_COLOR       = 0xDE85, -- XPAND color for address-label repaint
  BLANK_SPRITE            = 0xDE90, -- 90 zero bytes, drawn through $0B92

  -- Reserved for the animation/action phase.  Native Z80 will own these.
  SELECTION_BITMAP        = 0xDEF0, -- 104 bits = 13 bytes
  ANIMATION_LIST          = 0xDF00, -- ordered sprite indices
  ANIMATION_CAPACITY      = 32,
  ACTION_TRACE_BUFFER     = 0xDF30,
  ACTION_TRACE_END        = 0xDF8F,

  STACK_TOP               = 0xDFE0,

  VIDEO_START             = 0x4000,
  VISIBLE_VIDEO_END       = 0x7FBF,
  SCREEN_STRIDE_BYTES     = 80,

  SPRITE_WIDTH_BYTES      = 5,
  SPRITE_HEIGHT_ROWS      = 18,
  GRID_COLUMNS            = 8,
  CATALOG_ROWS            = 13,
  GRID_VISIBLE_ROWS       = 4,
  GRID_VISIBLE_CELLS      = 32,
  GRID_START_Y_ROWS       = 32,
  CELL_WIDTH_BYTES        = 10,
  CELL_HEIGHT_ROWS        = 34,
  SPRITE_X_INSET_BYTES    = 2,
  SPRITE_Y_INSET_ROWS     = 2,
  BORDER_X_INSET_BYTES    = 1,
  BORDER_Y_INSET_ROWS     = 0,
  LABEL_X_INSET_BYTES     = 1,
  LABEL_Y_INSET_ROWS      = 23,
  BORDER_WIDTH_BYTES      = 7,
  BORDER_INTERIOR_ROWS    = 20,
  -- The entire central header is a disposable transform workspace.  It is
  -- deliberately wider than the sprite so flop/rotate output and earlier
  -- transform footprints are erased without touching the version at x=72.
  PREVIEW_WORKSPACE_X     = 20,
  PREVIEW_WORKSPACE_Y     = 0,
  PREVIEW_WORKSPACE_VIDEO = 0x4000 + 20,
  PREVIEW_WORKSPACE_WIDTH = 40,
  PREVIEW_WORKSPACE_HEIGHT = 32,
  HEADER_SPRITE_DEST      = 5 * 80 + 37,
  HEADER_HFLIP_X_ADJUST   = 4,
  HEADER_VFLIP_Y_ADJUST   = 17,
  HEADER_VERSION_DEST     = 72,
  FOOTER_LINE1_DEST       = 11 * 16 * 80 + 2 * 2,
  FOOTER_LINE2_DEST       = 12 * 16 * 80,
  FOOTER_LINE1_WIDTH      = 36,
  FOOTER_LINE2_WIDTH      = 40,
  TEXT_BLUE               = 0x04,
  TEXT_YELLOW             = 0x08,
  TEXT_RED                = 0x0C,

  MAGIC_SHIFT_MASK        = 0x03,
  MAGIC_ROTATE_MASK       = 0x04,
  MAGIC_OR_MASK           = 0x10,
  MAGIC_XOR_MASK          = 0x20,
  MAGIC_HFLIP_MASK        = 0x40,
  MAGIC_VFLIP_MASK        = 0x80,
  MAGIC_ITEM_SHIFT        = 0,
  MAGIC_ITEM_ROTATE       = 1,
  MAGIC_ITEM_HFLIP        = 2,
  MAGIC_ITEM_VFLIP        = 3,
  MAGIC_ITEM_BLEND        = 4,
  MAGIC_ITEM_RESET        = 5,
  MAGIC_ITEM_COUNT        = 6,

  INPUT_DIRECTION_MASK    = 0x0F,
  INPUT_FIRE_MASK         = 0x30,
  INPUT_UP                = 0x01,
  INPUT_DOWN              = 0x02,
  INPUT_LEFT              = 0x04,
  INPUT_RIGHT             = 0x08,
  REPEAT_INITIAL          = 12,
  REPEAT_RATE             = 3,
}

local HEADER_SNAPSHOT_NAME = 'sprite.header'
local HEADER_CAPTURE_REGION = {
  base = C.VIDEO_START,
  stride_bytes = C.SCREEN_STRIDE_BYTES,
  x_byte = 0,
  y = 0,
  width_bytes = C.SCREEN_STRIDE_BYTES,
  height = C.PREVIEW_WORKSPACE_HEIGHT,
}
local HEADER_EXPECTED_WRITE = {
  x_byte = C.PREVIEW_WORKSPACE_X,
  y = C.PREVIEW_WORKSPACE_Y,
  width_bytes = C.PREVIEW_WORKSPACE_WIDTH,
  height = C.PREVIEW_WORKSPACE_HEIGHT,
}

-- The catalog is generated from the fixed 20x18, raw 2bpp Wizard of Wor
-- locations in 07-24-2026-3-astrocade_2bpp_sprite_library.json.  Names that
-- now have stronger labels in wow_disassembly.asm use those current labels.
-- Entries are grouped into animation families for later frame sequencing.
local CATALOG = {
  { name='BURWOR_1', address=0x9EAE },
  { name='BURWOR_2', address=0x9F08 },
  { name='BURWOR_3', address=0x9F62 },
  { name='BURWOR_1_UP', address=0x9DA0 },
  { name='BURWOR_2_UP', address=0x9DFA },
  { name='BURWOR_3_UP', address=0x9E54 },
  { name='BURWOR_FIRE_0', address=0xA124 },
  { name='BURWOR_FIRE_1', address=0xA17E },
  { name='BURWOR_FIRE_2', address=0xA1D8 },
  { name='BURWOR_FIRE_3', address=0xA232 },
  { name='BURWOR_FIRE_0_UP', address=0x9FBC },
  { name='BURWOR_FIRE_1_UP', address=0xA016 },
  { name='BURWOR_FIRE_2_UP', address=0xA070 },
  { name='BURWOR_FIRE_3_UP', address=0xA0CA },

  { name='GARWOR_1', address=0x9600 },
  { name='GARWOR_2', address=0x965A },
  { name='GARWOR_3', address=0x96B4 },
  { name='GARWOR_1_UP', address=0x970E },
  { name='GARWOR_2_UP', address=0x9768 },
  { name='GARWOR_3_UP', address=0x3CD5 },
  { name='GARWOR_FIRE_0', address=0xAAFC },
  { name='GARWOR_FIRE_1', address=0xAB56 },
  { name='GARWOR_FIRE_2', address=0xABB0 },
  { name='GARWOR_FIRE_3', address=0xAC0A },
  { name='GARWOR_FIRE_0_UP', address=0xA994 },
  { name='GARWOR_FIRE_1_UP', address=0xA9EE },
  { name='GARWOR_FIRE_2_UP', address=0xAA48 },
  { name='GARWOR_FIRE_3_UP', address=0xAAA2 },

  { name='THORWOR_1', address=0x3D2F },
  { name='THORWOR_2', address=0x3D89 },
  { name='THORWOR_3', address=0x3DE3 },
  { name='THORWOR_1_UP', address=0x3E3D },
  { name='THORWOR_2_UP', address=0x3E97 },
  { name='THORWOR_3_UP', address=0x3EF1 },
  { name='THORWOR_FIRE_0', address=0xADCC },
  { name='THORWOR_FIRE_1', address=0xAE26 },
  { name='THORWOR_FIRE_2', address=0xAE80 },
  { name='THORWOR_FIRE_3', address=0xAEDA },
  { name='THORWOR_FIRE_0_UP', address=0xAC64 },
  { name='THORWOR_FIRE_1_UP', address=0xACBE },
  { name='THORWOR_FIRE_2_UP', address=0xAD18 },
  { name='THORWOR_FIRE_3_UP', address=0xAD72 },

  { name='WORLUK_1', address=0xA39A },
  { name='WORLUK_2', address=0xA3F4 },
  { name='WORLUK_3', address=0xA44E },
  { name='WORLUK_1_UP', address=0xA28C },
  { name='WORLUK_2_UP', address=0xA2E6 },
  { name='WORLUK_3_UP', address=0xA340 },

  { name='WIZARD_1', address=0xA610 },
  { name='WIZARD_2', address=0xA66A },
  { name='WIZARD_3', address=0xA6C4 },
  { name='WIZARD_4', address=0xA71E },
  { name='WIZARD_1_UP', address=0xA4A8 },
  { name='WIZARD_2_UP', address=0xA502 },
  { name='WIZARD_3_UP', address=0xA55C },
  { name='WIZARD_4_UP', address=0xA5B6 },
  { name='WIZARD_1_FIRE', address=0xA886 },
  { name='WIZARD_2_FIRE', address=0xA8E0 },
  { name='WIZARD_3_FIRE', address=0xA93A },
  { name='WIZARD_1_FIRE_UP', address=0xA778 },
  { name='WIZARD_2_FIRE_UP', address=0xA7D2 },
  { name='WIZARD_3_FIRE_UP', address=0xA82C },

  { name='WORRIOR_BLUE_1', address=0x389C },
  { name='WORRIOR_BLUE_2', address=0x3950 },
  { name='WORRIOR_BLUE_3', address=0x3A04 },
  { name='WORRIOR_BLUE_1_UP', address=0x3B12 },
  { name='WORRIOR_BLUE_2_UP', address=0x3BC6 },
  { name='WORRIOR_BLUE_3_UP', address=0x3C7A },
  { name='WORRIOR_YELLOW_1', address=0x38F6 },
  { name='WORRIOR_YELLOW_2', address=0x39AA },
  { name='WORRIOR_YELLOW_3', address=0x3A5E },
  { name='WORRIOR_YELLOW_1_UP', address=0x3AB8 },
  { name='WORRIOR_YELLOW_2_UP', address=0x3B6C },
  { name='WORRIOR_YELLOW_3_UP', address=0x3C20 },
  { name='WORRIOR_BLUE_FIRE_1', address=0x9968 },
  { name='WORRIOR_BLUE_FIRE_2', address=0x99C2 },
  { name='WORRIOR_BLUE_FIRE_3', address=0x9A1C },
  { name='WORRIOR_BLUE_FIRE_4', address=0x9A76 },
  { name='WORRIOR_BLUE_FIRE_1_UP', address=0x9800 },
  { name='WORRIOR_BLUE_FIRE_2_UP', address=0x985A },
  { name='WORRIOR_BLUE_FIRE_3_UP', address=0x98B4 },
  { name='WORRIOR_BLUE_FIRE_4_UP', address=0x990E },
  { name='WORRIOR_YELLOW_FIRE_1', address=0x9C38 },
  { name='WORRIOR_YELLOW_FIRE_2', address=0x9C92 },
  { name='WORRIOR_YELLOW_FIRE_3', address=0x9CEC },
  { name='WORRIOR_YELLOW_FIRE_4', address=0x9D46 },
  { name='WORRIOR_YELLOW_FIRE_1_UP', address=0x9AD0 },
  { name='WORRIOR_YELLOW_FIRE_2_UP', address=0x9B2A },
  { name='WORRIOR_YELLOW_FIRE_3_UP', address=0x9B84 },
  { name='WORRIOR_YELLOW_FIRE_4_UP', address=0x9BDE },
  { name='WORRIOR_BLOW_1', address=0x3590 },
  { name='WORRIOR_BLOW_2', address=0x3644 },
  { name='WORRIOR_BLOW_3', address=0x36F8 },
  { name='WORRIOR_BLOW_4', address=0x37AC },
  { name='WORRIOR_BLOW_1_UP', address=0x35EA },
  { name='WORRIOR_BLOW_2_UP', address=0x369E },
  { name='WORRIOR_BLOW_3_UP', address=0x3752 },
  { name='WORRIOR_BLOW_4_UP', address=0x3806 },

  { name='SPLOT', address=0x3536 },
  { name='SPLOT_2', address=0x34DC },
  { name='SPLOT_3', address=0x3482 },
  { name='SPLOT_4', address=0x3428 },
  { name='SPLOT_5', address=0x33CE },
  { name='SPLOT_6', address=0x3374 },
}

assert(#CATALOG == 104, 'sprite catalog must contain 104 fixed-size ROM entries')

local MAGIC_ITEM_NAMES = {
  'SHIFT', 'ROTATE', 'H-FLIP', 'V-FLIP', 'BLEND', 'RESET',
}

local MAGIC_BLEND_NAMES = { 'PLOP', 'OR', 'XOR' }

local S = {
  active = false,
  lab = nil,
  program = nil,
  video_debug = nil,
  shortcuts = {},
  controller_labels = {},
  last_event_sequence = 0,
  last_redraw_sequence = 0,
}

local function printf(fmt, ...)
  print(string.format(fmt, ...))
end

local function hex2(value)
  return string.format('$%02X', (tonumber(value) or 0) & 0xFF)
end

local function hex4(value)
  return string.format('$%04X', (tonumber(value) or 0) & 0xFFFF)
end

-- Small label-aware Z80 emitter.  The module keeps its native source symbolic
-- while still producing the application image at runtime without an assembler.
local function assembler(origin)
  local a = { origin=origin, bytes={}, labels={}, fixups={} }

  function a:pc() return self.origin + #self.bytes end
  function a:b(value) self.bytes[#self.bytes + 1] = value & 0xFF end
  function a:w(value) self:b(value); self:b(value >> 8) end
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
  function a:abs(opcode, target)
    self:b(opcode)
    self:word(target)
  end
  function a:jr(opcode, target)
    self:b(opcode)
    local pos = #self.bytes + 1
    self:b(0)
    self.fixups[#self.fixups + 1] = { kind='rel', pos=pos, target=target }
  end
  function a:finish()
    for _, fixup in ipairs(self.fixups) do
      local target = assert(self.labels[fixup.target], 'undefined native label: ' .. fixup.target)
      if fixup.kind == 'abs' then
        self.bytes[fixup.pos] = target & 0xFF
        self.bytes[fixup.pos + 1] = (target >> 8) & 0xFF
      else
        local operand_address = self.origin + fixup.pos - 1
        local displacement = target - (operand_address + 1)
        assert(displacement >= -128 and displacement <= 127,
          'JR target out of range: ' .. fixup.target)
        self.bytes[fixup.pos] = displacement & 0xFF
      end
    end
    return self.bytes, self.labels
  end

  return a
end

local function emit_ld_mem_a(a, address) a:b(0x32); a:w(address) end
local function emit_ld_a_mem(a, address) a:b(0x3A); a:w(address) end
local function emit_call(a, target) a:abs(0xCD, target) end
local function emit_jp(a, target) a:abs(0xC3, target) end

local function build_controller()
  local a = assembler(C.NATIVE_CODE)

  a:label('entry')
  a:b(0xF3)                                      -- DI
  a:b(0x31); a:w(C.STACK_TOP)                    -- LD SP,$DFE0
  a:b(0xAF)                                      -- XOR A
  for address = C.STATE_BASE, C.STATE_END do emit_ld_mem_a(a, address) end
  a:b(0xDB); a:b(C.COINPORT); a:b(0x2F); a:b(0xE6); a:b(0x40)
  emit_ld_mem_a(a, C.STATE_START_LAST)            -- prime active-high 2P state
  emit_call(a, 'draw_gallery')

  a:label('main')
  a:b(0xFB); a:b(0x76)                           -- EI / HALT
  emit_ld_a_mem(a, C.STATE_REDRAW_REQUEST)
  a:b(0xB7)                                      -- OR A
  a:jr(0x28, 'main_no_redraw')                   -- JR Z
  emit_call(a, 'draw_gallery')
  a:label('main_no_redraw')
  emit_call(a, 'read_controls')
  emit_jp(a, 'main')

  -- Read both player control ports.  Directions and Fire remain entirely
  -- native; 1P Start is handled by the permanent Lab kernel below $D400.
  a:label('read_controls')
  a:b(0xDB); a:b(C.P1PORT); a:b(0x2F); a:b(0xE6); a:b(0x3F); a:b(0x47)
  a:b(0xDB); a:b(C.P2PORT); a:b(0x2F); a:b(0xE6); a:b(0x3F); a:b(0xB0)
  a:b(0x47)                                      -- LD B,A
  emit_ld_mem_a(a, C.STATE_INPUT_CURRENT)

  -- Fire reports the current sprite during browsing.  In the Magic menu it
  -- resets every transform through the same native action/trace path.
  a:b(0xE6); a:b(C.INPUT_FIRE_MASK); a:b(0x4F)  -- AND $30 / LD C,A
  emit_ld_a_mem(a, C.STATE_FIRE_LAST)
  a:b(0x2F); a:b(0xA1); a:b(0x57)                -- CPL / AND C / LD D,A
  a:b(0x79); emit_ld_mem_a(a, C.STATE_FIRE_LAST) -- remember current Fire
  a:b(0x7A); a:b(0xB7); a:jr(0x28, 'fire_done')
  emit_ld_a_mem(a, C.STATE_MENU_ACTIVE); a:b(0xB7)
  a:jr(0x28, 'fire_browse')
  emit_call(a, 'reset_magic')
  a:b(0xC9)
  a:label('fire_browse')
  a:b(0x3E); a:b(0x02); emit_ld_mem_a(a, C.STATE_EVENT_TYPE)
  a:b(0x21); a:w(C.STATE_EVENT_SEQUENCE); a:b(0x34)
  a:label('fire_done')

  -- Edge-detect 2P Start (COINPORT bit 6) independently of the permanent
  -- Lab kernel, which continues to own 1P Start and return-to-menu behavior.
  a:b(0xDB); a:b(C.COINPORT); a:b(0x2F); a:b(0xE6); a:b(0x40); a:b(0x4F)
  emit_ld_a_mem(a, C.STATE_START_LAST); a:b(0x2F); a:b(0xA1); a:b(0x47)
  a:b(0x79); emit_ld_mem_a(a, C.STATE_START_LAST)
  a:b(0x78); a:b(0xB7); a:jr(0x28, 'start_done')
  emit_call(a, 'toggle_menu')
  a:b(0xC9)
  a:label('start_done')

  -- Only cardinal one-bit direction states move the selection.  Diagonals and
  -- opposing directions release repeat state instead of choosing arbitrarily.
  emit_ld_a_mem(a, C.STATE_INPUT_CURRENT)
  a:b(0xE6); a:b(C.INPUT_DIRECTION_MASK); a:b(0x47)
  for _, direction in ipairs({C.INPUT_UP, C.INPUT_DOWN, C.INPUT_LEFT, C.INPUT_RIGHT}) do
    a:b(0xFE); a:b(direction); a:jr(0x28, 'direction_valid')
  end
  emit_jp(a, 'direction_release')

  a:label('direction_valid')
  emit_ld_a_mem(a, C.STATE_HOLD_DIRECTION); a:b(0xB8)
  a:jr(0x20, 'direction_new')
  -- Browsing retains held-direction repeat.  Magic-menu fields are deliberate
  -- one-press operations: a held direction cannot cycle a boolean or race
  -- through several values before the physical joystick returns to center.
  emit_ld_a_mem(a, C.STATE_MENU_ACTIVE); a:b(0xB7); a:b(0xC0) -- RET NZ
  a:b(0x21); a:w(C.STATE_HOLD_COUNTDOWN); a:b(0x35) -- DEC (HL)
  a:b(0xC0)                                      -- RET NZ
  a:b(0x36); a:b(C.REPEAT_RATE)
  a:b(0x78); emit_jp(a, 'move_direction')

  a:label('direction_new')
  a:b(0x78); emit_ld_mem_a(a, C.STATE_HOLD_DIRECTION)
  a:b(0x3E); a:b(C.REPEAT_INITIAL); emit_ld_mem_a(a, C.STATE_HOLD_COUNTDOWN)
  a:b(0x78); emit_jp(a, 'move_direction')

  a:label('direction_release')
  a:b(0xAF)
  emit_ld_mem_a(a, C.STATE_HOLD_DIRECTION)
  emit_ld_mem_a(a, C.STATE_HOLD_COUNTDOWN)
  a:b(0xC9)

  a:label('move_direction')
  a:b(0x47)                                      -- LD B,A
  emit_ld_a_mem(a, C.STATE_SELECTED); emit_ld_mem_a(a, C.STATE_OLD_SELECTED)
  emit_ld_a_mem(a, C.STATE_FIRST_ROW); emit_ld_mem_a(a, C.STATE_OLD_FIRST_ROW)
  emit_ld_a_mem(a, C.STATE_SELECTED_COL); emit_ld_mem_a(a, C.STATE_OLD_SELECTED_COL)
  emit_ld_a_mem(a, C.STATE_SELECTED_VIEW_ROW); emit_ld_mem_a(a, C.STATE_OLD_VIEW_ROW)
  emit_ld_a_mem(a, C.STATE_MENU_ACTIVE); a:b(0xB7)
  a:b(0x78)
  a:abs(0xC2, 'menu_direction')                  -- JP NZ
  a:b(0xFE); a:b(C.INPUT_LEFT);  a:abs(0xCA, 'move_left')
  a:b(0xFE); a:b(C.INPUT_RIGHT); a:abs(0xCA, 'move_right')
  a:b(0xFE); a:b(C.INPUT_UP);    a:abs(0xCA, 'move_up')
  emit_jp(a, 'move_down')

  a:label('move_left')
  emit_ld_a_mem(a, C.STATE_SELECTED_COL); a:b(0xB7); a:b(0xC8) -- RET Z
  a:b(0x3D); emit_ld_mem_a(a, C.STATE_SELECTED_COL)
  emit_ld_a_mem(a, C.STATE_SELECTED); a:b(0x3D); emit_ld_mem_a(a, C.STATE_SELECTED)
  emit_jp(a, 'commit_cell_move')

  a:label('move_right')
  emit_ld_a_mem(a, C.STATE_SELECTED_COL); a:b(0xFE); a:b(C.GRID_COLUMNS - 1); a:b(0xD0)
  emit_ld_a_mem(a, C.STATE_SELECTED); a:b(0x3C); a:b(0xFE); a:b(#CATALOG); a:b(0xD0)
  emit_ld_mem_a(a, C.STATE_SELECTED)
  emit_ld_a_mem(a, C.STATE_SELECTED_COL); a:b(0x3C); emit_ld_mem_a(a, C.STATE_SELECTED_COL)
  emit_jp(a, 'commit_cell_move')

  -- Vertical input moves the box through the four visible rows.  Crossing a
  -- display edge scrolls one circular catalog row while the box stays at that
  -- edge.  Selected absolute row and visible row are independent state.
  a:label('move_up')
  emit_ld_a_mem(a, C.STATE_SELECTED_VIEW_ROW); a:b(0xB7)
  a:jr(0x28, 'move_up_scroll')
  a:b(0x3D); emit_ld_mem_a(a, C.STATE_SELECTED_VIEW_ROW)
  emit_call(a, 'selected_row_up')
  emit_jp(a, 'commit_cell_move')

  a:label('move_up_scroll')
  emit_ld_a_mem(a, C.STATE_FIRST_ROW); a:b(0xB7)
  a:jr(0x20, 'move_up_first_decrement')
  a:b(0x3E); a:b(C.CATALOG_ROWS)
  a:label('move_up_first_decrement')
  a:b(0x3D); emit_ld_mem_a(a, C.STATE_FIRST_ROW)
  emit_call(a, 'selected_row_up')
  emit_jp(a, 'commit_row_scroll')

  a:label('move_down')
  emit_ld_a_mem(a, C.STATE_SELECTED_VIEW_ROW)
  a:b(0xFE); a:b(C.GRID_VISIBLE_ROWS - 1); a:jr(0x28, 'move_down_scroll')
  a:b(0x3C); emit_ld_mem_a(a, C.STATE_SELECTED_VIEW_ROW)
  emit_call(a, 'selected_row_down')
  emit_jp(a, 'commit_cell_move')

  a:label('move_down_scroll')
  emit_ld_a_mem(a, C.STATE_FIRST_ROW); a:b(0x3C)
  a:b(0xFE); a:b(C.CATALOG_ROWS); a:jr(0x38, 'move_down_first_store')
  a:b(0xAF)
  a:label('move_down_first_store')
  emit_ld_mem_a(a, C.STATE_FIRST_ROW)
  emit_call(a, 'selected_row_down')

  a:label('commit_row_scroll')
  emit_call(a, 'draw_gallery')
  emit_jp(a, 'commit_event')

  a:label('commit_cell_move')
  emit_call(a, 'old_visible_slot')
  emit_call(a, 'border_off')
  emit_call(a, 'draw_header')
  emit_call(a, 'current_visible_slot')
  emit_call(a, 'border_on')

  a:label('commit_event')
  a:b(0x3E); a:b(0x01); emit_ld_mem_a(a, C.STATE_EVENT_TYPE)
  a:b(0x21); a:w(C.STATE_EVENT_SEQUENCE); a:b(0x34)
  a:b(0xC9)

  a:label('selected_row_up')
  emit_ld_a_mem(a, C.STATE_SELECTED_ROW); a:b(0xB7)
  a:jr(0x20, 'selected_row_up_decrement')
  a:b(0x3E); a:b(C.CATALOG_ROWS)
  a:label('selected_row_up_decrement')
  a:b(0x3D); emit_ld_mem_a(a, C.STATE_SELECTED_ROW)
  emit_jp(a, 'select_selected_row')

  a:label('selected_row_down')
  emit_ld_a_mem(a, C.STATE_SELECTED_ROW); a:b(0x3C)
  a:b(0xFE); a:b(C.CATALOG_ROWS); a:jr(0x38, 'selected_row_down_store')
  a:b(0xAF)
  a:label('selected_row_down_store')
  emit_ld_mem_a(a, C.STATE_SELECTED_ROW)

  -- SELECTED = SELECTED_ROW * 8 + SELECTED_COL.
  a:label('select_selected_row')
  emit_ld_a_mem(a, C.STATE_SELECTED_ROW)
  a:b(0x87); a:b(0x87); a:b(0x87)               -- row * 8
  a:b(0x47)
  emit_ld_a_mem(a, C.STATE_SELECTED_COL); a:b(0x80)
  emit_ld_mem_a(a, C.STATE_SELECTED)
  a:b(0xC9)

  a:label('old_visible_slot')
  emit_ld_a_mem(a, C.STATE_OLD_VIEW_ROW)
  a:b(0x87); a:b(0x87); a:b(0x87); a:b(0x47)
  emit_ld_a_mem(a, C.STATE_OLD_SELECTED_COL); a:b(0x80); a:b(0xC9)

  a:label('current_visible_slot')
  emit_ld_a_mem(a, C.STATE_SELECTED_VIEW_ROW)
  a:b(0x87); a:b(0x87); a:b(0x87); a:b(0x47)
  emit_ld_a_mem(a, C.STATE_SELECTED_COL); a:b(0x80); a:b(0xC9)

  -- Magic menu: Up/Down selects a register field; Left/Right changes it.
  -- Every change rebuilds the five-byte WoW actor record, redraws through the
  -- resident $0B92 entry, and writes a compact native trace record.
  a:label('menu_direction')
  a:b(0x4F)                                      -- C=direction
  a:b(0xFE); a:b(C.INPUT_UP); a:abs(0xCA, 'menu_item_up')
  a:b(0xFE); a:b(C.INPUT_DOWN); a:abs(0xCA, 'menu_item_down')
  emit_ld_a_mem(a, C.STATE_MENU_ITEM)
  a:b(0xFE); a:b(C.MAGIC_ITEM_SHIFT);  a:abs(0xCA, 'menu_change_shift')
  a:b(0xFE); a:b(C.MAGIC_ITEM_ROTATE); a:abs(0xCA, 'menu_toggle_rotate')
  a:b(0xFE); a:b(C.MAGIC_ITEM_HFLIP);  a:abs(0xCA, 'menu_toggle_hflip')
  a:b(0xFE); a:b(C.MAGIC_ITEM_VFLIP);  a:abs(0xCA, 'menu_toggle_vflip')
  a:b(0xFE); a:b(C.MAGIC_ITEM_BLEND);  a:abs(0xCA, 'menu_change_blend')
  emit_jp(a, 'reset_magic')

  a:label('menu_item_up')
  emit_ld_a_mem(a, C.STATE_MENU_ITEM); a:b(0xB7)
  a:jr(0x20, 'menu_item_up_decrement')
  a:b(0x3E); a:b(C.MAGIC_ITEM_COUNT)
  a:label('menu_item_up_decrement')
  a:b(0x3D); emit_ld_mem_a(a, C.STATE_MENU_ITEM)
  emit_jp(a, 'commit_menu_item')

  a:label('menu_item_down')
  emit_ld_a_mem(a, C.STATE_MENU_ITEM); a:b(0x3C)
  a:b(0xFE); a:b(C.MAGIC_ITEM_COUNT); a:jr(0x38, 'menu_item_down_store')
  a:b(0xAF)
  a:label('menu_item_down_store')
  emit_ld_mem_a(a, C.STATE_MENU_ITEM)

  a:label('commit_menu_item')
  emit_call(a, 'draw_footer')
  a:b(0x3E); a:b(0x03); emit_ld_mem_a(a, C.STATE_EVENT_TYPE)
  a:b(0x21); a:w(C.STATE_EVENT_SEQUENCE); a:b(0x34)
  a:b(0xC9)

  a:label('menu_change_shift')
  a:b(0x79); a:b(0xFE); a:b(C.INPUT_LEFT)
  a:jr(0x20, 'menu_shift_right')
  emit_ld_a_mem(a, C.STATE_MAGIC_SHIFT); a:b(0xB7)
  a:jr(0x20, 'menu_shift_left_decrement')
  a:b(0x3E); a:b(0x04)
  a:label('menu_shift_left_decrement')
  a:b(0x3D); emit_ld_mem_a(a, C.STATE_MAGIC_SHIFT)
  emit_jp(a, 'commit_magic')
  a:label('menu_shift_right')
  emit_ld_a_mem(a, C.STATE_MAGIC_SHIFT); a:b(0x3C); a:b(0xE6); a:b(0x03)
  emit_ld_mem_a(a, C.STATE_MAGIC_SHIFT)
  emit_jp(a, 'commit_magic')

  a:label('menu_toggle_rotate')
  emit_ld_a_mem(a, C.STATE_MAGIC_ROTATE); a:b(0xEE); a:b(0x01)
  emit_ld_mem_a(a, C.STATE_MAGIC_ROTATE); emit_jp(a, 'commit_magic')

  a:label('menu_toggle_hflip')
  emit_ld_a_mem(a, C.STATE_MAGIC_HFLIP); a:b(0xEE); a:b(0x01)
  emit_ld_mem_a(a, C.STATE_MAGIC_HFLIP); emit_jp(a, 'commit_magic')

  a:label('menu_toggle_vflip')
  emit_ld_a_mem(a, C.STATE_MAGIC_VFLIP); a:b(0xEE); a:b(0x01)
  emit_ld_mem_a(a, C.STATE_MAGIC_VFLIP); emit_jp(a, 'commit_magic')

  a:label('menu_change_blend')
  a:b(0x79); a:b(0xFE); a:b(C.INPUT_LEFT)
  a:jr(0x20, 'menu_blend_right')
  emit_ld_a_mem(a, C.STATE_MAGIC_BLEND); a:b(0xB7)
  a:jr(0x20, 'menu_blend_left_decrement')
  a:b(0x3E); a:b(0x03)
  a:label('menu_blend_left_decrement')
  a:b(0x3D); emit_ld_mem_a(a, C.STATE_MAGIC_BLEND)
  emit_jp(a, 'commit_magic')
  a:label('menu_blend_right')
  emit_ld_a_mem(a, C.STATE_MAGIC_BLEND); a:b(0x3C)
  a:b(0xFE); a:b(0x03); a:jr(0x38, 'menu_blend_store')
  a:b(0xAF)
  a:label('menu_blend_store')
  emit_ld_mem_a(a, C.STATE_MAGIC_BLEND)
  emit_jp(a, 'commit_magic')

  a:label('reset_magic')
  a:b(0xAF)
  for _, address in ipairs({
    C.STATE_MAGIC_SHIFT, C.STATE_MAGIC_ROTATE, C.STATE_MAGIC_HFLIP,
    C.STATE_MAGIC_VFLIP, C.STATE_MAGIC_BLEND, C.STATE_MAGIC_MODE,
  }) do emit_ld_mem_a(a, address) end
  a:b(0x3E); a:b(C.MAGIC_ITEM_RESET); emit_ld_mem_a(a, C.STATE_LAST_ACTION)
  emit_jp(a, 'commit_magic_apply')

  a:label('commit_magic')
  emit_ld_a_mem(a, C.STATE_MENU_ITEM); emit_ld_mem_a(a, C.STATE_LAST_ACTION)
  a:label('commit_magic_apply')
  emit_call(a, 'build_magic_mode')
  emit_call(a, 'draw_header')
  emit_call(a, 'draw_footer')
  emit_call(a, 'record_magic_action')
  a:b(0x3E); a:b(0x04); emit_ld_mem_a(a, C.STATE_EVENT_TYPE)
  a:b(0x21); a:w(C.STATE_EVENT_SEQUENCE); a:b(0x34)
  a:b(0xC9)

  a:label('build_magic_mode')
  emit_ld_a_mem(a, C.STATE_MAGIC_SHIFT); a:b(0xE6); a:b(C.MAGIC_SHIFT_MASK)
  a:b(0x47)                                      -- B=mode
  emit_ld_a_mem(a, C.STATE_MAGIC_ROTATE); a:b(0xB7)
  a:jr(0x28, 'magic_no_rotate')
  a:b(0x78); a:b(0xF6); a:b(C.MAGIC_ROTATE_MASK); a:b(0x47)
  a:label('magic_no_rotate')
  emit_ld_a_mem(a, C.STATE_MAGIC_HFLIP); a:b(0xB7)
  a:jr(0x28, 'magic_no_hflip')
  a:b(0x78); a:b(0xF6); a:b(C.MAGIC_HFLIP_MASK); a:b(0x47)
  a:label('magic_no_hflip')
  emit_ld_a_mem(a, C.STATE_MAGIC_VFLIP); a:b(0xB7)
  a:jr(0x28, 'magic_no_vflip')
  a:b(0x78); a:b(0xF6); a:b(C.MAGIC_VFLIP_MASK); a:b(0x47)
  a:label('magic_no_vflip')
  emit_ld_a_mem(a, C.STATE_MAGIC_BLEND)
  a:b(0xFE); a:b(0x01); a:jr(0x20, 'magic_test_xor')
  a:b(0x78); a:b(0xF6); a:b(C.MAGIC_OR_MASK); a:b(0x47)
  a:jr(0x18, 'magic_store_mode')
  a:label('magic_test_xor')
  a:b(0xFE); a:b(0x02); a:jr(0x20, 'magic_store_mode')
  a:b(0x78); a:b(0xF6); a:b(C.MAGIC_XOR_MASK); a:b(0x47)
  a:label('magic_store_mode')
  a:b(0x78); emit_ld_mem_a(a, C.STATE_MAGIC_MODE); a:b(0xC9)

  -- Ten-byte native action record: sequence, selection, Magic mode, menu item,
  -- source, destination, and the renderer that performed the final operation.
  -- Normal operations record WoW $0B92; rotate records rotate_sprite_90.
  a:label('record_magic_action')
  a:b(0x21); a:w(C.ACTION_TRACE_BUFFER); a:b(0x34); a:b(0x23)
  emit_ld_a_mem(a, C.STATE_SELECTED); a:b(0x77); a:b(0x23)
  emit_ld_a_mem(a, C.STATE_MAGIC_MODE); a:b(0x77); a:b(0x23)
  emit_ld_a_mem(a, C.STATE_LAST_ACTION); a:b(0x77); a:b(0x23)
  emit_ld_a_mem(a, C.DRAW_RECORD + 1); a:b(0x77); a:b(0x23)
  emit_ld_a_mem(a, C.DRAW_RECORD + 2); a:b(0x77); a:b(0x23)
  emit_ld_a_mem(a, C.DRAW_RECORD + 3); a:b(0x77); a:b(0x23)
  emit_ld_a_mem(a, C.DRAW_RECORD + 4); a:b(0x77); a:b(0x23)
  emit_ld_a_mem(a, C.STATE_RENDER_ENTRY); a:b(0x77); a:b(0x23)
  emit_ld_a_mem(a, C.STATE_RENDER_ENTRY + 1); a:b(0x77); a:b(0xC9)

  -- In-place gallery replacement.  There is deliberately no screen clear:
  -- every destination receives the sprite from the adjacent catalog row using
  -- WoW's PLOP actor path, and its four-character label is overwritten by the
  -- resident Pattern Board font path.  This prevents the page-blank flash.
  a:label('draw_gallery')
  a:b(0xF3)                                      -- DI
  emit_ld_a_mem(a, C.STATE_FIRST_ROW)
  a:b(0x87); a:b(0x87); a:b(0x87)
  emit_ld_mem_a(a, C.STATE_FIRST_INDEX)
  emit_call(a, 'old_visible_slot')
  emit_call(a, 'border_off')

  emit_ld_a_mem(a, C.STATE_FIRST_ROW); emit_ld_mem_a(a, C.STATE_DRAW_ROW)
  a:b(0xAF); emit_ld_mem_a(a, C.STATE_DRAW_SLOT)
  emit_ld_mem_a(a, C.STATE_DRAW_COL)

  a:label('draw_gallery_loop')
  emit_ld_a_mem(a, C.STATE_DRAW_ROW)
  a:b(0x87); a:b(0x87); a:b(0x87)               -- row * 8
  a:b(0x47)
  emit_ld_a_mem(a, C.STATE_DRAW_COL); a:b(0x80)
  emit_ld_mem_a(a, C.STATE_DRAW_INDEX)
  a:b(0xFE); a:b(#CATALOG); a:abs(0xD2, 'draw_blank_cell') -- JP NC

  a:b(0x87); a:b(0x5F); a:b(0x16); a:b(0x00)    -- *2 / E=A / LD D,0
  a:b(0x21); a:w(C.CATALOG_TABLE); a:b(0x19)     -- LD HL,table / ADD HL,DE
  a:b(0x7E); emit_ld_mem_a(a, C.DRAW_RECORD + 1)
  a:b(0x23); a:b(0x7E); emit_ld_mem_a(a, C.DRAW_RECORD + 2)
  emit_call(a, 'draw_cell_sprite')
  emit_call(a, 'draw_address_label')
  emit_jp(a, 'advance_gallery_cell')

  a:label('draw_blank_cell')
  a:b(0x21); a:w(C.BLANK_SPRITE)
  a:b(0x7D); emit_ld_mem_a(a, C.DRAW_RECORD + 1)
  a:b(0x7C); emit_ld_mem_a(a, C.DRAW_RECORD + 2)
  emit_call(a, 'draw_cell_sprite')
  emit_call(a, 'draw_blank_label')

  a:label('advance_gallery_cell')
  a:b(0x21); a:w(C.STATE_DRAW_INDEX); a:b(0x34)
  a:b(0x21); a:w(C.STATE_DRAW_SLOT); a:b(0x34)
  emit_ld_a_mem(a, C.STATE_DRAW_SLOT); a:b(0xFE); a:b(C.GRID_VISIBLE_CELLS)
  a:abs(0xD2, 'draw_gallery_done')               -- JP NC

  a:b(0x21); a:w(C.STATE_DRAW_COL); a:b(0x34)
  emit_ld_a_mem(a, C.STATE_DRAW_COL); a:b(0xFE); a:b(C.GRID_COLUMNS)
  a:abs(0xDA, 'draw_gallery_loop')                -- JP C
  a:b(0xAF); emit_ld_mem_a(a, C.STATE_DRAW_COL)
  a:b(0x21); a:w(C.STATE_DRAW_ROW); a:b(0x34)
  emit_ld_a_mem(a, C.STATE_DRAW_ROW); a:b(0xFE); a:b(C.CATALOG_ROWS)
  a:abs(0xDA, 'draw_gallery_loop')                -- JP C
  a:b(0xAF); emit_ld_mem_a(a, C.STATE_DRAW_ROW)
  emit_jp(a, 'draw_gallery_loop')

  a:label('draw_gallery_done')
  emit_call(a, 'draw_header')
  emit_call(a, 'current_visible_slot')
  emit_call(a, 'border_on')
  emit_call(a, 'draw_footer')
  emit_ld_a_mem(a, C.STATE_SELECTED); emit_ld_mem_a(a, C.STATE_OLD_SELECTED)
  emit_ld_a_mem(a, C.STATE_FIRST_ROW); emit_ld_mem_a(a, C.STATE_OLD_FIRST_ROW)
  emit_ld_a_mem(a, C.STATE_SELECTED_COL); emit_ld_mem_a(a, C.STATE_OLD_SELECTED_COL)
  emit_ld_a_mem(a, C.STATE_SELECTED_VIEW_ROW); emit_ld_mem_a(a, C.STATE_OLD_VIEW_ROW)
  a:b(0x21); a:w(C.STATE_REDRAW_SEQUENCE); a:b(0x34)
  a:b(0xAF); emit_ld_mem_a(a, C.STATE_REDRAW_REQUEST)
  a:b(0xFB); a:b(0xC9)                           -- EI / RET

  -- Copy the current DRAW_RECORD source into the destination for DRAW_SLOT.
  -- Mode zero is a full PLOP replace: zero pixels erase the previous sprite.
  a:label('draw_cell_sprite')
  emit_ld_a_mem(a, C.STATE_DRAW_SLOT)
  a:b(0x87); a:b(0x5F); a:b(0x16); a:b(0x00)
  a:b(0x21); a:w(C.CELL_DEST_TABLE); a:b(0x19)
  a:b(0x7E); emit_ld_mem_a(a, C.DRAW_RECORD + 3)
  a:b(0x23); a:b(0x7E); emit_ld_mem_a(a, C.DRAW_RECORD + 4)
  a:b(0xAF); emit_ld_mem_a(a, C.DRAW_RECORD)
  a:b(0x21); a:w(C.DRAW_RECORD)
  emit_call(a, C.DRAW_ACTOR_RECORD)
  a:b(0xC9)

  -- Convert the current 16-bit ROM source address to four ASCII hex digits,
  -- then fall through to WoW's resident Pattern Board string printer.
  a:label('draw_address_label')
  emit_ld_a_mem(a, C.DRAW_RECORD + 2)
  a:b(0x0F); a:b(0x0F); a:b(0x0F); a:b(0x0F)
  emit_call(a, 'nibble_to_ascii'); emit_ld_mem_a(a, C.TEXT_BUFFER)
  emit_ld_a_mem(a, C.DRAW_RECORD + 2)
  emit_call(a, 'nibble_to_ascii'); emit_ld_mem_a(a, C.TEXT_BUFFER + 1)
  emit_ld_a_mem(a, C.DRAW_RECORD + 1)
  a:b(0x0F); a:b(0x0F); a:b(0x0F); a:b(0x0F)
  emit_call(a, 'nibble_to_ascii'); emit_ld_mem_a(a, C.TEXT_BUFFER + 2)
  emit_ld_a_mem(a, C.DRAW_RECORD + 1)
  emit_call(a, 'nibble_to_ascii'); emit_ld_mem_a(a, C.TEXT_BUFFER + 3)
  a:b(0x21); a:w(C.TEXT_BUFFER)
  emit_jp(a, 'print_cell_label')

  a:label('draw_blank_label')
  a:b(0x21); a:word('blank_text')

  -- HL = four native character codes.  Destination comes from DRAW_SLOT.
  a:label('print_cell_label')
  a:b(0xE5)                                      -- PUSH HL
  emit_ld_a_mem(a, C.STATE_DRAW_SLOT)
  a:b(0x87); a:b(0x5F); a:b(0x16); a:b(0x00)
  a:b(0x21); a:w(C.LABEL_DEST_TABLE); a:b(0x19)
  a:b(0x5E); a:b(0x23); a:b(0x56)                -- LD E,(HL)/INC/LD D,(HL)
  a:b(0xE1)                                      -- POP HL
  a:b(0x06); a:b(0x04)
  emit_ld_a_mem(a, C.STATE_LABEL_COLOR)
  emit_call(a, C.PRINT_STRING_COLOR)
  a:b(0xC9)

  -- Two resident-font footer rows provide browse controls or Magic menu help.
  -- Every line has a fixed width so switching modes erases all prior glyphs.
  a:label('draw_footer')
  emit_call(a, 'update_footer_values')
  emit_ld_a_mem(a, C.STATE_MENU_ACTIVE); a:b(0xB7)
  a:abs(0xCA, 'draw_footer_main')                 -- JP Z
  emit_ld_a_mem(a, C.STATE_MENU_ITEM)
  a:b(0xFE); a:b(C.MAGIC_ITEM_SHIFT);  a:jr(0x28, 'footer_use_shift')
  a:b(0xFE); a:b(C.MAGIC_ITEM_ROTATE); a:jr(0x28, 'footer_use_rotate')
  a:b(0xFE); a:b(C.MAGIC_ITEM_HFLIP);  a:jr(0x28, 'footer_use_hflip')
  a:b(0xFE); a:b(C.MAGIC_ITEM_VFLIP);  a:jr(0x28, 'footer_use_vflip')
  a:b(0xFE); a:b(C.MAGIC_ITEM_BLEND);  a:jr(0x28, 'footer_use_blend')
  a:b(0x21); a:word('footer_magic_reset'); a:jr(0x18, 'draw_footer_magic')
  a:label('footer_use_shift')
  a:b(0x21); a:word('footer_magic_shift'); a:jr(0x18, 'draw_footer_magic')
  a:label('footer_use_rotate')
  a:b(0x21); a:word('footer_magic_rotate'); a:jr(0x18, 'draw_footer_magic')
  a:label('footer_use_hflip')
  a:b(0x21); a:word('footer_magic_hflip'); a:jr(0x18, 'draw_footer_magic')
  a:label('footer_use_vflip')
  a:b(0x21); a:word('footer_magic_vflip'); a:jr(0x18, 'draw_footer_magic')
  a:label('footer_use_blend')
  a:b(0x21); a:word('footer_magic_blend')
  a:label('draw_footer_magic')
  emit_call(a, 'print_footer_line1')
  a:b(0x21); a:word('footer_magic_line2')
  emit_jp(a, 'print_footer_line2')

  a:label('draw_footer_main')
  a:b(0x21); a:word('footer_main_line1')
  emit_call(a, 'print_footer_line1')
  a:b(0x21); a:word('footer_main_line2')
  emit_jp(a, 'print_footer_line2')

  a:label('print_footer_line1')
  a:b(0x11); a:w(C.FOOTER_LINE1_DEST)
  a:b(0x06); a:b(C.FOOTER_LINE1_WIDTH)
  a:b(0x3E); a:b(C.TEXT_YELLOW)
  emit_call(a, C.PRINT_STRING_COLOR)
  a:b(0xC9)

  a:label('print_footer_line2')
  a:b(0x11); a:w(C.FOOTER_LINE2_DEST)
  a:b(0x06); a:b(C.FOOTER_LINE2_WIDTH)
  a:b(0x3E); a:b(C.TEXT_YELLOW)
  emit_call(a, C.PRINT_STRING_COLOR)
  a:b(0xC9)

  a:label('update_footer_values')
  emit_ld_a_mem(a, C.STATE_MAGIC_SHIFT); a:b(0xC6); a:b(0x30)
  a:abs(0x32, 'footer_shift_value')
  emit_ld_a_mem(a, C.STATE_MAGIC_ROTATE); a:b(0xC6); a:b(0x30)
  a:abs(0x32, 'footer_rotate_value')
  emit_ld_a_mem(a, C.STATE_MAGIC_HFLIP); a:b(0xC6); a:b(0x30)
  a:abs(0x32, 'footer_hflip_value')
  emit_ld_a_mem(a, C.STATE_MAGIC_VFLIP); a:b(0xC6); a:b(0x30)
  a:abs(0x32, 'footer_vflip_value')
  emit_ld_a_mem(a, C.STATE_MAGIC_BLEND); a:b(0xC6); a:b(0x30)
  a:abs(0x32, 'footer_blend_value')
  a:b(0xC9)

  a:label('toggle_menu')
  emit_ld_a_mem(a, C.STATE_MENU_ACTIVE); a:b(0xEE); a:b(0x01)
  emit_ld_mem_a(a, C.STATE_MENU_ACTIVE)
  a:b(0xAF)
  emit_ld_mem_a(a, C.STATE_HOLD_DIRECTION)
  emit_ld_mem_a(a, C.STATE_HOLD_COUNTDOWN)
  emit_call(a, 'draw_footer')
  a:b(0x3E); a:b(0x03); emit_ld_mem_a(a, C.STATE_EVENT_TYPE)
  a:b(0x21); a:w(C.STATE_EVENT_SEQUENCE); a:b(0x34)
  a:b(0xC9)

  a:label('nibble_to_ascii')
  a:b(0xE6); a:b(0x0F); a:b(0xC6); a:b(0x30)
  a:b(0xFE); a:b(0x3A); a:b(0xD8)                -- RET C for 0-9
  a:b(0xC6); a:b(0x07); a:b(0xC9)                -- A-F

  -- Selected sprite preview.  Normal, shift, flop, flip, OR and XOR continue
  -- through resident WoW $0B92.  Rotate uses the final iWizard/Nutter 4x4-tile
  -- protocol: four source-row writes at 0/80/160/240 are repeated so writes
  -- five through eight emit the clockwise-rotated tile.
  a:label('draw_header')
  emit_call(a, 'clear_preview_workspace')
  emit_ld_a_mem(a, C.STATE_SELECTED)
  a:b(0x87); a:b(0x5F); a:b(0x16); a:b(0x00)
  a:b(0x21); a:w(C.CATALOG_TABLE); a:b(0x19)
  a:b(0x7E); emit_ld_mem_a(a, C.DRAW_RECORD + 1)
  a:b(0x23); a:b(0x7E); emit_ld_mem_a(a, C.DRAW_RECORD + 2)
  emit_ld_a_mem(a, C.STATE_MAGIC_BLEND); a:b(0xB7)
  a:jr(0x28, 'draw_header_prepare_transformed')
  a:b(0x21); a:w(C.HEADER_SPRITE_DEST)
  a:b(0x7D); emit_ld_mem_a(a, C.DRAW_RECORD + 3)
  a:b(0x7C); emit_ld_mem_a(a, C.DRAW_RECORD + 4)
  a:b(0xAF); emit_ld_mem_a(a, C.DRAW_RECORD)     -- base PLOP for OR/XOR demo
  a:b(0x21); a:w(C.DRAW_RECORD)
  emit_call(a, C.DRAW_ACTOR_RECORD)
  a:label('draw_header_prepare_transformed')
  emit_ld_a_mem(a, C.STATE_MAGIC_ROTATE); a:b(0xB7)
  a:jr(0x28, 'draw_header_nonrotate')
  a:b(0x21); a:w(C.HEADER_SPRITE_DEST)
  a:b(0x7D); emit_ld_mem_a(a, C.DRAW_RECORD + 3)
  a:b(0x7C); emit_ld_mem_a(a, C.DRAW_RECORD + 4)
  emit_ld_a_mem(a, C.STATE_MAGIC_MODE); emit_ld_mem_a(a, C.DRAW_RECORD)
  emit_call(a, 'rotate_sprite_90')
  a:b(0x21); a:word('rotate_sprite_90')
  a:b(0x22); a:w(C.STATE_RENDER_ENTRY)           -- LD (render_entry),HL
  a:jr(0x18, 'draw_header_version')

  a:label('draw_header_nonrotate')
  a:b(0xAF); emit_ld_mem_a(a, C.STATE_ROTATE_WRITES)
  emit_call(a, 'set_header_destination')
  emit_ld_a_mem(a, C.STATE_MAGIC_MODE); emit_ld_mem_a(a, C.DRAW_RECORD)
  a:b(0x21); a:w(C.DRAW_RECORD)
  emit_call(a, C.DRAW_ACTOR_RECORD)
  a:b(0x21); a:w(C.DRAW_ACTOR_RECORD)
  a:b(0x22); a:w(C.STATE_RENDER_ENTRY)           -- LD (render_entry),HL

  a:label('draw_header_version')
  a:b(0x21); a:word('version_text')
  a:b(0x11); a:w(C.HEADER_VERSION_DEST)
  a:b(0x06); a:b(0x04)
  a:b(0x3E); a:b(C.TEXT_YELLOW)
  emit_call(a, C.PRINT_STRING_COLOR)
  a:b(0xC9)

  a:label('set_header_destination')
  a:b(0x21); a:w(C.HEADER_SPRITE_DEST)
  emit_ld_a_mem(a, C.STATE_MAGIC_HFLIP); a:b(0xB7)
  a:jr(0x28, 'header_destination_no_hflip')
  a:b(0x11); a:w(C.HEADER_HFLIP_X_ADJUST); a:b(0x19) -- ADD HL,DE
  a:label('header_destination_no_hflip')
  emit_ld_a_mem(a, C.STATE_MAGIC_VFLIP); a:b(0xB7)
  a:jr(0x28, 'header_destination_store')
  a:b(0x11); a:w(C.HEADER_VFLIP_Y_ADJUST * C.SCREEN_STRIDE_BYTES)
  a:b(0x19)                                      -- ADD HL,DE
  a:label('header_destination_store')
  a:b(0x7D); emit_ld_mem_a(a, C.DRAW_RECORD + 3)
  a:b(0x7C); emit_ld_mem_a(a, C.DRAW_RECORD + 4)
  a:b(0xC9)

  -- Fixed 20x18 raw-ROM rotation.  Output is 20x20: five source byte-columns
  -- by five four-row bands.  The last source band contains two real rows and
  -- two zero pads.  H-FLIP and V-FLIP mirror the completed rotated axes using
  -- the same Magic flop bit and reverse-row policy as the generic iWizard API.
  a:label('rotate_sprite_90')
  a:b(0xF3)                                      -- DI: eight writes are atomic
  a:b(0xAF); emit_ld_mem_a(a, C.STATE_ROTATE_WRITES)
  a:b(0x2A); a:w(C.DRAW_RECORD + 1)               -- LD HL,(source)
  a:b(0x22); a:w(C.ROTATE_SOURCE_ROW)
  a:b(0xAF); emit_ld_mem_a(a, C.STATE_ROTATE_TILE_Y)

  a:label('rotate_tile_row')
  emit_ld_a_mem(a, C.STATE_ROTATE_TILE_Y)
  a:b(0xFE); a:b(0x04); a:jr(0x38, 'rotate_four_real_rows') -- JR C
  a:b(0x3E); a:b(0x02); a:jr(0x18, 'rotate_rows_ready')
  a:label('rotate_four_real_rows')
  a:b(0x3E); a:b(0x04)
  a:label('rotate_rows_ready')
  emit_ld_mem_a(a, C.STATE_ROTATE_ROWS)
  a:b(0xAF); emit_ld_mem_a(a, C.STATE_ROTATE_TILE_X)

  a:label('rotate_tile_column')
  -- Re-arm the four-write accumulator for every individual 4x4 tile.
  emit_ld_a_mem(a, C.STATE_MAGIC_MODE); a:b(0xE6); a:b(0x7F)
  a:b(0xD3); a:b(0x0C)                           -- OUT (MAGIC),A

  -- HL = first source byte for this tile in the current four-row band.
  a:b(0x2A); a:w(C.ROTATE_SOURCE_ROW)
  emit_ld_a_mem(a, C.STATE_ROTATE_TILE_X)
  a:b(0x4F); a:b(0x06); a:b(0x00); a:b(0x09)    -- C=A / B=0 / ADD HL,BC
  a:b(0xE5)                                      -- PUSH HL source

  -- Clockwise tile mapping: (source X,Y) -> (4-Y,X).  H-FLIP mirrors the
  -- completed destination X axis and therefore uses Y directly.
  a:b(0x21); a:w(C.HEADER_SPRITE_DEST)
  emit_ld_a_mem(a, C.STATE_MAGIC_HFLIP); a:b(0xB7)
  emit_ld_a_mem(a, C.STATE_ROTATE_TILE_Y)
  a:jr(0x20, 'rotate_dest_x_ready')               -- H-FLIP: X=tileY
  a:b(0x4F); a:b(0x3E); a:b(0x04); a:b(0x91)    -- C=A / A=4 / SUB C
  a:label('rotate_dest_x_ready')
  a:b(0x4F); a:b(0x06); a:b(0x00); a:b(0x09)    -- ADD X byte

  -- Source tile X selects a four-scanline output band.  V-FLIP anchors at
  -- output row 19 and moves upward four rows for each source tile column.
  emit_ld_a_mem(a, C.STATE_MAGIC_VFLIP); a:b(0xB7)
  emit_ld_a_mem(a, C.STATE_ROTATE_TILE_X)
  a:jr(0x20, 'rotate_dest_vflip')
  a:b(0xB7); a:jr(0x28, 'rotate_destination_ready')
  a:b(0x11); a:w(4 * C.SCREEN_STRIDE_BYTES)
  a:label('rotate_add_y_band')
  a:b(0x19); a:b(0x3D); a:jr(0x20, 'rotate_add_y_band')
  a:jr(0x18, 'rotate_destination_ready')

  a:label('rotate_dest_vflip')
  a:b(0xF5)                                      -- PUSH AF tileX
  a:b(0x3E); a:b(19)
  a:b(0x11); a:w(C.SCREEN_STRIDE_BYTES)
  a:label('rotate_add_last_row')
  a:b(0x19); a:b(0x3D); a:jr(0x20, 'rotate_add_last_row')
  a:b(0xF1); a:b(0xB7)                           -- POP AF / OR A
  a:jr(0x28, 'rotate_destination_ready')
  a:b(0x11); a:w((-4 * C.SCREEN_STRIDE_BYTES) & 0xFFFF)
  a:label('rotate_subtract_y_band')
  a:b(0x19); a:b(0x3D); a:jr(0x20, 'rotate_subtract_y_band')

  a:label('rotate_destination_ready')
  a:b(0xEB); a:b(0xE1)                           -- EX DE,HL / POP HL source
  a:b(0xE5); a:b(0xD5)                           -- save identical pass two
  emit_call(a, 'rotate_four_writes')
  a:b(0xD1); a:b(0xE1)
  emit_call(a, 'rotate_four_writes')

  a:b(0x21); a:w(C.STATE_ROTATE_TILE_X); a:b(0x34)
  emit_ld_a_mem(a, C.STATE_ROTATE_TILE_X); a:b(0xFE); a:b(0x05)
  a:abs(0xC2, 'rotate_tile_column')              -- JP NZ

  -- Advance source-row base by four packed rows: 4 * 5 = 20 bytes.
  a:b(0x2A); a:w(C.ROTATE_SOURCE_ROW)
  a:b(0x11); a:w(4 * C.SPRITE_WIDTH_BYTES); a:b(0x19)
  a:b(0x22); a:w(C.ROTATE_SOURCE_ROW)
  a:b(0x21); a:w(C.STATE_ROTATE_TILE_Y); a:b(0x34)
  emit_ld_a_mem(a, C.STATE_ROTATE_TILE_Y); a:b(0xFE); a:b(0x05)
  a:abs(0xC2, 'rotate_tile_row')                 -- JP NZ
  a:b(0xAF); a:b(0xD3); a:b(0x0C); a:b(0xC9)   -- Magic off / RET

  -- One half of the Nutter eight-write protocol.  Input HL is the first source
  -- row and DE is the first destination row; partial rows are zero-padded.
  a:label('rotate_four_writes')
  emit_ld_a_mem(a, C.STATE_ROTATE_ROWS); a:b(0x4F)
  a:b(0x06); a:b(0x04)
  a:label('rotate_four_write_loop')
  a:b(0x79); a:b(0xB7); a:jr(0x28, 'rotate_four_write_padding')
  a:b(0x0D); a:b(0x7E); a:b(0xF5); a:b(0xC5)
  a:b(0x01); a:w(C.SPRITE_WIDTH_BYTES); a:b(0x09)
  a:b(0xC1); a:b(0xF1); a:jr(0x18, 'rotate_four_write_store')
  a:label('rotate_four_write_padding')
  a:b(0xAF)
  a:label('rotate_four_write_store')
  a:b(0x12)                                      -- LD (DE),A
  emit_ld_a_mem(a, C.STATE_ROTATE_WRITES); a:b(0x3C)
  emit_ld_mem_a(a, C.STATE_ROTATE_WRITES)
  a:jr(0x10, 'rotate_four_write_advance')        -- DJNZ
  a:b(0xC9)
  a:label('rotate_four_write_advance')
  -- Preserve BC: B is the four-write loop counter and C is the remaining
  -- real-row count.  The address calculation temporarily needs BC for +/-80.
  a:b(0xE5); a:b(0xC5); a:b(0xEB)               -- PUSH HL / PUSH BC / EX DE,HL
  emit_ld_a_mem(a, C.STATE_MAGIC_VFLIP); a:b(0xB7)
  a:b(0x01); a:w(C.SCREEN_STRIDE_BYTES)
  a:jr(0x28, 'rotate_four_step_ready')
  a:b(0x01); a:w((-C.SCREEN_STRIDE_BYTES) & 0xFFFF)
  a:label('rotate_four_step_ready')
  a:b(0x09); a:b(0xEB); a:b(0xC1); a:b(0xE1)   -- ADD / EX / POP BC / POP HL
  a:jr(0x18, 'rotate_four_write_loop')

  a:label('clear_preview_workspace')
  a:b(0x21); a:w(C.PREVIEW_WORKSPACE_VIDEO)
  a:b(0x06); a:b(C.PREVIEW_WORKSPACE_HEIGHT)
  a:b(0xAF)
  a:label('clear_preview_row')
  a:b(0xC5)                                      -- PUSH BC
  a:b(0x0E); a:b(C.PREVIEW_WORKSPACE_WIDTH)
  a:label('clear_preview_byte')
  a:b(0x77); a:b(0x23); a:b(0x0D)
  a:jr(0x20, 'clear_preview_byte')
  a:b(0x11); a:w(C.SCREEN_STRIDE_BYTES - C.PREVIEW_WORKSPACE_WIDTH)
  a:b(0x19); a:b(0xC1)                           -- ADD HL,DE / POP BC
  a:jr(0x10, 'clear_preview_row')
  a:b(0xC9)

  -- A = visible cell index.  A color-3, one-pixel border surrounds the padded
  -- 20x18 sprite.  Border changes also repaint that cell's address: selected
  -- red, unselected blue.  Clearing touches padding bytes, never sprite data.
  a:label('border_on')
  emit_ld_mem_a(a, C.STATE_DRAW_SLOT)
  a:b(0xF5)
  a:b(0x3E); a:b(0xFF); emit_ld_mem_a(a, C.STATE_BORDER_FILL)
  a:b(0x3E); a:b(0xC0); emit_ld_mem_a(a, C.STATE_BORDER_LEFT)
  a:b(0x3E); a:b(0x03); emit_ld_mem_a(a, C.STATE_BORDER_RIGHT)
  a:b(0xF1); emit_call(a, 'draw_border')
  a:b(0x3E); a:b(C.TEXT_RED); emit_ld_mem_a(a, C.STATE_LABEL_COLOR)
  emit_jp(a, 'draw_address_label')

  a:label('border_off')
  emit_ld_mem_a(a, C.STATE_DRAW_SLOT)
  a:b(0xF5); a:b(0xAF)
  emit_ld_mem_a(a, C.STATE_BORDER_FILL)
  emit_ld_mem_a(a, C.STATE_BORDER_LEFT)
  emit_ld_mem_a(a, C.STATE_BORDER_RIGHT)
  a:b(0xF1); emit_call(a, 'draw_border')
  a:b(0x3E); a:b(C.TEXT_BLUE); emit_ld_mem_a(a, C.STATE_LABEL_COLOR)
  emit_jp(a, 'draw_address_label')

  a:label('draw_border')
  a:b(0x87); a:b(0x5F); a:b(0x16); a:b(0x00)
  a:b(0x21); a:w(C.BORDER_DEST_TABLE); a:b(0x19)
  a:b(0x5E); a:b(0x23); a:b(0x56); a:b(0xEB)    -- DE=(HL), EX DE,HL
  a:b(0xE5)                                      -- PUSH HL
  emit_ld_a_mem(a, C.STATE_BORDER_FILL)
  a:b(0x06); a:b(C.BORDER_WIDTH_BYTES)
  a:label('border_top_loop')
  a:b(0x77); a:b(0x23); a:jr(0x10, 'border_top_loop')
  a:b(0xE1)                                      -- POP HL
  a:b(0x11); a:w(C.SCREEN_STRIDE_BYTES); a:b(0x19)
  a:b(0x06); a:b(C.BORDER_INTERIOR_ROWS)
  a:label('border_side_loop')
  emit_ld_a_mem(a, C.STATE_BORDER_LEFT); a:b(0x77)
  a:b(0x11); a:w(C.BORDER_WIDTH_BYTES - 1); a:b(0x19)
  emit_ld_a_mem(a, C.STATE_BORDER_RIGHT); a:b(0x77)
  a:b(0x11); a:w(C.SCREEN_STRIDE_BYTES - (C.BORDER_WIDTH_BYTES - 1)); a:b(0x19)
  a:jr(0x10, 'border_side_loop')
  emit_ld_a_mem(a, C.STATE_BORDER_FILL)
  a:b(0x06); a:b(C.BORDER_WIDTH_BYTES)
  a:label('border_bottom_loop')
  a:b(0x77); a:b(0x23); a:jr(0x10, 'border_bottom_loop')
  a:b(0xC9)

  local function emit_native_text(text)
    text = text:gsub(' ', '@'):gsub('%-', '_')
    for index = 1, #text do a:b(text:byte(index)) end
  end

  local function emit_fixed_line(text, width)
    assert(#text <= width, 'native footer line exceeds fixed width')
    local left = math.floor((width - #text) / 2)
    emit_native_text(string.rep(' ', left) .. text
      .. string.rep(' ', width - left - #text))
  end

  local function emit_dynamic_line(before, value_label, after, width)
    local content_width = #before + 1 + #after
    assert(content_width <= width, 'native dynamic footer line exceeds fixed width')
    local left = math.floor((width - content_width) / 2)
    emit_native_text(string.rep(' ', left) .. before)
    a:label(value_label); a:b(string.byte('0'))
    emit_native_text(after .. string.rep(' ', width - left - content_width))
  end

  a:label('version_text'); emit_native_text('V134')
  a:label('blank_text'); emit_native_text('@@@@')
  a:label('footer_main_line1')
  emit_fixed_line('', C.FOOTER_LINE1_WIDTH)
  a:label('footer_main_line2')
  emit_fixed_line('JOY BROWSE-FIRE INFO-1P EXIT-2P MAGIC', C.FOOTER_LINE2_WIDTH)
  a:label('footer_magic_shift')
  emit_dynamic_line('MAGIC SHIFT ', 'footer_shift_value', '  LR 0 TO 3', C.FOOTER_LINE1_WIDTH)
  a:label('footer_magic_rotate')
  emit_dynamic_line('MAGIC ROTATE ', 'footer_rotate_value', '  0 OFF 1 ON', C.FOOTER_LINE1_WIDTH)
  a:label('footer_magic_hflip')
  emit_dynamic_line('MAGIC H FLIP ', 'footer_hflip_value', '  0 OFF 1 ON', C.FOOTER_LINE1_WIDTH)
  a:label('footer_magic_vflip')
  emit_dynamic_line('MAGIC V FLIP ', 'footer_vflip_value', '  0 OFF 1 ON', C.FOOTER_LINE1_WIDTH)
  a:label('footer_magic_blend')
  emit_dynamic_line('MAGIC BLEND ', 'footer_blend_value', '  0 PLOP 1 OR 2 XOR', C.FOOTER_LINE1_WIDTH)
  a:label('footer_magic_reset')
  emit_fixed_line('MAGIC RESET  LR OR FIRE', C.FOOTER_LINE1_WIDTH)
  a:label('footer_magic_line2')
  emit_fixed_line('UD ITEM LR CHANGE FIRE RESET 2P CLOSE', C.FOOTER_LINE2_WIDTH)

  local bytes, labels = a:finish()
  assert(C.NATIVE_CODE + #bytes - 1 <= C.NATIVE_CODE_END,
    string.format('sprite native controller exceeds reserved range: %d bytes', #bytes))
  return bytes, labels
end

local function little_endian_words(values)
  local bytes = {}
  for _, value in ipairs(values) do
    bytes[#bytes + 1] = value & 0xFF
    bytes[#bytes + 1] = (value >> 8) & 0xFF
  end
  return bytes
end

local function catalog_bytes()
  local values = {}
  for _, entry in ipairs(CATALOG) do values[#values + 1] = entry.address end
  return little_endian_words(values)
end

local function cell_destination_bytes()
  local values = {}
  for slot = 0, C.GRID_VISIBLE_CELLS - 1 do
    local row = math.floor(slot / C.GRID_COLUMNS)
    local col = slot % C.GRID_COLUMNS
    local y = C.GRID_START_Y_ROWS + row * C.CELL_HEIGHT_ROWS
        + C.SPRITE_Y_INSET_ROWS
    local x_byte = col * C.CELL_WIDTH_BYTES + C.SPRITE_X_INSET_BYTES
    values[#values + 1] = y * C.SCREEN_STRIDE_BYTES + x_byte
  end
  return little_endian_words(values)
end

local function border_destination_bytes()
  local values = {}
  for slot = 0, C.GRID_VISIBLE_CELLS - 1 do
    local row = math.floor(slot / C.GRID_COLUMNS)
    local col = slot % C.GRID_COLUMNS
    local y = C.GRID_START_Y_ROWS + row * C.CELL_HEIGHT_ROWS
        + C.BORDER_Y_INSET_ROWS
    local x_byte = col * C.CELL_WIDTH_BYTES + C.BORDER_X_INSET_BYTES
    values[#values + 1] = C.VIDEO_START + y * C.SCREEN_STRIDE_BYTES + x_byte
  end
  return little_endian_words(values)
end

local function label_destination_bytes()
  local values = {}
  for slot = 0, C.GRID_VISIBLE_CELLS - 1 do
    local row = math.floor(slot / C.GRID_COLUMNS)
    local col = slot % C.GRID_COLUMNS
    local y = C.GRID_START_Y_ROWS + row * C.CELL_HEIGHT_ROWS
        + C.LABEL_Y_INSET_ROWS
    local x_byte = col * C.CELL_WIDTH_BYTES + C.LABEL_X_INSET_BYTES
    values[#values + 1] = y * C.SCREEN_STRIDE_BYTES + x_byte
  end
  return little_endian_words(values)
end

local function fnv1a_sprite(program, address)
  local hash = 0x811C9DC5
  local nonzero = 0
  for offset = 0, C.SPRITE_WIDTH_BYTES * C.SPRITE_HEIGHT_ROWS - 1 do
    local byte = program:read_u8(address + offset)
    if byte ~= 0 then nonzero = nonzero + 1 end
    hash = ((hash ~ byte) * 0x01000193) & 0xFFFFFFFF
  end
  return hash, nonzero
end

local function audit_catalog(verbose)
  local seen = {}
  local errors = 0
  local blank = 0
  for index, entry in ipairs(CATALOG) do
    local valid_range = (entry.address >= 0x0000 and entry.address + 89 <= 0x3FFF)
        or (entry.address >= 0x8000 and entry.address + 89 <= 0xBFFF)
    if not valid_range then
      errors = errors + 1
      printf('[WOW SPRITE] AUDIT ERROR %03d %s crosses mapped ROM: %s',
        index, entry.name, hex4(entry.address))
    end
    if seen[entry.address] then
      errors = errors + 1
      printf('[WOW SPRITE] AUDIT ERROR duplicate %s: %s and %s',
        hex4(entry.address), seen[entry.address], entry.name)
    end
    seen[entry.address] = entry.name
    local hash, nonzero = fnv1a_sprite(S.program, entry.address)
    if nonzero == 0 then blank = blank + 1 end
    if verbose then
      printf('[WOW SPRITE] %03d %s %-28s FNV1A=$%08X NONZERO=%d/90',
        index, hex4(entry.address), entry.name, hash, nonzero)
    end
  end
  printf('[WOW SPRITE] catalog audit: %d entries; %d address error%s; %d blank ROM image%s',
    #CATALOG, errors, errors == 1 and '' or 's', blank, blank == 1 and '' or 's')
  return errors == 0 and blank == 0
end

local function selected_index()
  if not S.program then return 1 end
  local value = S.program:read_u8(C.STATE_SELECTED) + 1
  if value < 1 then value = 1 end
  if value > #CATALOG then value = #CATALOG end
  return value
end

local function print_selected(prefix)
  if not S.program then return nil end
  local index = selected_index()
  local entry = CATALOG[index]
  local hash, nonzero = fnv1a_sprite(S.program, entry.address)
  local first_row = S.program:read_u8(C.STATE_FIRST_ROW)
  local row = S.program:read_u8(C.STATE_SELECTED_ROW)
  local view_row = S.program:read_u8(C.STATE_SELECTED_VIEW_ROW)
  local col = S.program:read_u8(C.STATE_SELECTED_COL)
  local visible = {}
  for offset = 0, C.GRID_VISIBLE_ROWS - 1 do
    visible[#visible + 1] = tostring((first_row + offset) % C.CATALOG_ROWS)
  end
  printf('[WOW SPRITE] %s %03d/%03d ROW=%d VIEW=%d COL=%d WINDOW=%s ROM=%s FNV1A=$%08X NZ=%d %s',
    prefix or 'SELECT', index, #CATALOG, row, view_row, col,
    table.concat(visible, ','), hex4(entry.address), hash, nonzero, entry.name)
  return entry
end

local function print_status()
  if not S.active or not S.program then
    print('[WOW SPRITE] module is not active')
    return false
  end
  local pc = S.lab.native.cpu.state['PC'] and S.lab.native.cpu.state['PC'].value or 0
  local sp = S.lab.native.cpu.state['SP'] and S.lab.native.cpu.state['SP'].value or 0
  printf('[WOW SPRITE] version=%s PC=%s SP=%s input=%s hold=%s/%d menu=%d item=%d magic=%s event=%d/%d redraw=%d',
    M.VERSION, hex4(pc), hex4(sp), hex2(S.program:read_u8(C.STATE_INPUT_CURRENT)),
    hex2(S.program:read_u8(C.STATE_HOLD_DIRECTION)),
    S.program:read_u8(C.STATE_HOLD_COUNTDOWN),
    S.program:read_u8(C.STATE_MENU_ACTIVE),
    S.program:read_u8(C.STATE_MENU_ITEM), hex2(S.program:read_u8(C.STATE_MAGIC_MODE)),
    S.program:read_u8(C.STATE_EVENT_TYPE), S.program:read_u8(C.STATE_EVENT_SEQUENCE),
    S.program:read_u8(C.STATE_REDRAW_SEQUENCE))
  print_selected('CURRENT')
  return true
end

local function print_magic_trace()
  if not S.program then return false end
  local base = C.ACTION_TRACE_BUFFER
  local sequence = S.program:read_u8(base)
  local selected = S.program:read_u8(base + 1)
  local mode = S.program:read_u8(base + 2)
  local action = S.program:read_u8(base + 3)
  local source = S.program:read_u8(base + 4) | (S.program:read_u8(base + 5) << 8)
  local destination = S.program:read_u8(base + 6) | (S.program:read_u8(base + 7) << 8)
  local entry = S.program:read_u8(base + 8) | (S.program:read_u8(base + 9) << 8)
  local catalog_entry = CATALOG[selected + 1]
  local rotate_entry = S.controller_labels and S.controller_labels.rotate_sprite_90 or -1
  local expected_entry = (mode & C.MAGIC_ROTATE_MASK) ~= 0
    and rotate_entry or C.DRAW_ACTOR_RECORD
  local renderer = entry == rotate_entry and 'INJECTED-IWIZARD-4X4' or 'WOW-ROM-$0B92'
  printf('[WOW SPRITE] MAGIC TRACE %03d ACTION=%s SELECT=%03d ROM=%s MODE=%s DEST=%s CALL=%s RENDER=%s',
    sequence, MAGIC_ITEM_NAMES[action + 1] or ('ITEM-' .. tostring(action)),
    selected + 1, hex4(source), hex2(mode), hex4(destination), hex4(entry), renderer)
  local rotate_writes = S.program:read_u8(C.STATE_ROTATE_WRITES)
  printf('[WOW SPRITE] MAGIC STATE shift=%d rotate=%d hflip=%d vflip=%d blend=%s writes=%d sprite=%s',
    S.program:read_u8(C.STATE_MAGIC_SHIFT),
    S.program:read_u8(C.STATE_MAGIC_ROTATE),
    S.program:read_u8(C.STATE_MAGIC_HFLIP),
    S.program:read_u8(C.STATE_MAGIC_VFLIP),
    MAGIC_BLEND_NAMES[S.program:read_u8(C.STATE_MAGIC_BLEND) + 1] or 'UNKNOWN',
    rotate_writes,
    catalog_entry and catalog_entry.name or 'OUT-OF-RANGE')
  local write_count_ok = (mode & C.MAGIC_ROTATE_MASK) == 0 or rotate_writes == 200
  return entry == expected_entry
    and source == (catalog_entry and catalog_entry.address or -1)
    and write_count_ok
end

local function print_list(first, count)
  first = math.max(1, math.floor(tonumber(first) or 1))
  count = math.max(1, math.floor(tonumber(count) or #CATALOG))
  local last = math.min(#CATALOG, first + count - 1)
  for index = first, last do
    local entry = CATALOG[index]
    printf('[WOW SPRITE] %03d  %s  %s', index, hex4(entry.address), entry.name)
  end
  printf('[WOW SPRITE] listed %d-%d of %d', first, last, #CATALOG)
  return last >= first
end

local function request_redraw()
  if not S.active or not S.program then
    print('[WOW SPRITE] wgredraw(): module is not active')
    return false
  end
  S.program:write_u8(C.STATE_REDRAW_REQUEST, 1)
  print('[WOW SPRITE] native in-place gallery refresh requested')
  return true
end

local function header_metadata()
  local index = selected_index()
  local entry = CATALOG[index]
  return {
    selected = index,
    sprite = entry and entry.name or 'OUT-OF-RANGE',
    rom = entry and entry.address or 0,
    magic_mode = S.program:read_u8(C.STATE_MAGIC_MODE),
    magic_action_sequence = S.program:read_u8(C.ACTION_TRACE_BUFFER),
    event_sequence = S.program:read_u8(C.STATE_EVENT_SEQUENCE),
  }
end

local function require_header_debug(command)
  if not S.active or not S.program or not S.video_debug then
    printf('[WOW SPRITE] %s(): module/video diagnostic core is not active', command)
    return false
  end
  return true
end

local function header_snapshot()
  if not require_header_debug('wgheadsnap') then return nil end
  local snapshot = S.video_debug:capture(
    HEADER_SNAPSHOT_NAME, HEADER_CAPTURE_REGION, header_metadata())
  local meta = snapshot.metadata
  printf('[WOW SPRITE] HEADER SNAP bytes=%d hash=$%08X SELECT=%03d ROM=%s MODE=%s ACTION=%03d %s',
    snapshot.byte_count, snapshot.hash, meta.selected, hex4(meta.rom),
    hex2(meta.magic_mode), meta.magic_action_sequence, meta.sprite)
  printf('[WOW SPRITE] HEADER SNAP region xbyte=%d..%d pixels=%d..%d y=%d..%d',
    snapshot.region.x_byte,
    snapshot.region.x_byte + snapshot.region.width_bytes - 1,
    snapshot.region.x_byte * 4,
    (snapshot.region.x_byte + snapshot.region.width_bytes) * 4 - 1,
    snapshot.region.y, snapshot.region.y + snapshot.region.height - 1)
  return snapshot
end

local function print_changed_bounds(prefix, bounds)
  printf('[WOW SPRITE] %s address=%s..%s xbyte=%d..%d pixels=%d..%d y=%d..%d',
    prefix, hex4(bounds.min_address), hex4(bounds.max_address),
    bounds.min_x_byte, bounds.max_x_byte,
    bounds.min_x_byte * 4, bounds.max_x_byte * 4 + 3,
    bounds.min_y, bounds.max_y)
end

local function header_difference()
  if not require_header_debug('wgheaddiff') then return nil end
  local result, err = S.video_debug:compare(HEADER_SNAPSHOT_NAME, HEADER_EXPECTED_WRITE)
  if not result then
    print('[WOW SPRITE] wgheaddiff(): no header snapshot; run wgheadsnap() first')
    return nil, err
  end

  local before = result.metadata
  local now = header_metadata()
  printf('[WOW SPRITE] HEADER DIFF changed=%d snapshot=$%08X current=$%08X',
    result.changed_count, result.snapshot_hash, result.current_hash)
  printf('[WOW SPRITE] HEADER DIFF baseline SELECT=%03d ROM=%s MODE=%s ACTION=%03d; now SELECT=%03d ROM=%s MODE=%s ACTION=%03d',
    before.selected, hex4(before.rom), hex2(before.magic_mode),
    before.magic_action_sequence, now.selected, hex4(now.rom),
    hex2(now.magic_mode), now.magic_action_sequence)

  if result.changed_count == 0 then
    print('[WOW SPRITE] HEADER DIFF video memory is unchanged')
  else
    print_changed_bounds('HEADER CHANGED', result.bounds)
  end

  local expected = result.expected_write
  printf('[WOW SPRITE] HEADER EXPECTED xbyte=%d..%d pixels=%d..%d y=%d..%d',
    expected.x_byte, expected.x_byte + expected.width_bytes - 1,
    expected.x_byte * 4, (expected.x_byte + expected.width_bytes) * 4 - 1,
    expected.y, expected.y + expected.height - 1)
  if result.outside_count == 0 then
    print('[WOW SPRITE] HEADER OUTSIDE=0 all changed bytes are inside the preview workspace')
  else
    printf('[WOW SPRITE] HEADER OUTSIDE=%d WARNING transformed draw escaped preview workspace',
      result.outside_count)
    print_changed_bounds('HEADER OUTSIDE BOUNDS', result.outside_bounds)
  end
  return result
end

local function header_snapshot_status()
  if not require_header_debug('wgheadstatus') then return nil end
  local status = S.video_debug:status(HEADER_SNAPSHOT_NAME)
  if not status then
    print('[WOW SPRITE] HEADER SNAPSHOT NONE; run wgheadsnap() before an operation')
    return nil
  end
  local meta = status.metadata
  printf('[WOW SPRITE] HEADER SNAPSHOT READY bytes=%d hash=$%08X SELECT=%03d ROM=%s MODE=%s ACTION=%03d %s',
    status.byte_count, status.hash, meta.selected, hex4(meta.rom),
    hex2(meta.magic_mode), meta.magic_action_sequence, meta.sprite)
  return status
end

local function header_snapshot_clear()
  if not require_header_debug('wgheadclear') then return false end
  local existed = S.video_debug:clear(HEADER_SNAPSHOT_NAME)
  print(existed and '[WOW SPRITE] header diagnostic snapshot cleared'
    or '[WOW SPRITE] header diagnostic snapshot was already empty')
  return existed
end

local function install_shortcut(name, handler)
  local previous = rawget(_G, name)
  S.shortcuts[name] = { handler=handler, previous=previous, restore=previous ~= nil }
  rawset(_G, name, handler)
end

local function restore_shortcuts()
  for name, shortcut in pairs(S.shortcuts) do
    if rawget(_G, name) == shortcut.handler then
      rawset(_G, name, shortcut.restore and shortcut.previous or nil)
    end
  end
  S.shortcuts = {}
end

local function print_help()
  print('[WOW SPRITE] console commands:')
  print('[WOW SPRITE]   wginfo()          selected sprite, ROM address, hash and grid state')
  print('[WOW SPRITE]   wgstatus()        native controller/input state')
  print('[WOW SPRITE]   wglist([n],[c])   list catalog from 1-based n for c entries')
  print('[WOW SPRITE]   wgaudit([detail]) audit catalog; true prints every ROM hash')
  print('[WOW SPRITE]   wgmagic()         last native Magic action record')
  print('[WOW SPRITE]   wgheadsnap()      capture header VRAM plus sprite/Magic state')
  print('[WOW SPRITE]   wgheaddiff()      compare header and flag out-of-workspace writes')
  print('[WOW SPRITE]   wgheadstatus()    show the saved header snapshot context')
  print('[WOW SPRITE]   wgheadclear()     discard the saved header snapshot')
  print('[WOW SPRITE]   wgredraw()        request a native in-place gallery refresh')
  print('[WOW SPRITE]   wghelp()          show these commands')
end

local function install_shortcuts()
  install_shortcut('wginfo', function() return print_selected('CURRENT') end)
  install_shortcut('wgstatus', print_status)
  install_shortcut('wglist', print_list)
  install_shortcut('wgaudit', function(detail) return audit_catalog(detail == true) end)
  install_shortcut('wgmagic', print_magic_trace)
  install_shortcut('wgheadsnap', header_snapshot)
  install_shortcut('wgheaddiff', header_difference)
  install_shortcut('wgheadstatus', header_snapshot_status)
  install_shortcut('wgheadclear', header_snapshot_clear)
  install_shortcut('wgredraw', request_redraw)
  install_shortcut('wghelp', print_help)
end

function M.start(lab)
  S.lab = lab
  S.program = lab.native.program
  S.video_debug = assert(lab.video_debug, 'WoW Lab video diagnostic core is required')
  S.video_debug:clear(HEADER_SNAPSHOT_NAME)
  S.active = true

  local code, labels = build_controller()
  S.controller_labels = labels

  -- The application image is disposable.  Preserve the Lab ABI/kernel below
  -- $D400, replace this module's complete workspace, and leave palette ports
  -- untouched so the initialized in-game palette remains authoritative.
  lab.memory.fill(S.program, lab.memory.addr.APPLICATION_START,
    lab.memory.addr.APPLICATION_END, 0)
  lab.memory.write_bytes(S.program, C.NATIVE_CODE, code)
  lab.memory.write_bytes(S.program, C.CATALOG_TABLE, catalog_bytes())
  lab.memory.write_bytes(S.program, C.CELL_DEST_TABLE, cell_destination_bytes())
  lab.memory.write_bytes(S.program, C.BORDER_DEST_TABLE, border_destination_bytes())
  lab.memory.write_bytes(S.program, C.LABEL_DEST_TABLE, label_destination_bytes())
  lab.memory.fill(S.program, C.VIDEO_START, C.VISIBLE_VIDEO_END, 0)

  S.last_event_sequence = 0
  S.last_redraw_sequence = 0
  install_shortcuts()

  printf('[WOW SPRITE] SPRITE BROWSER MODULE %s', M.VERSION)
  printf('[WOW SPRITE] catalog=%d fixed 20x18 2bpp ROM sprites; grid=%dx%d; catalog rows=%d',
    #CATALOG, C.GRID_COLUMNS, C.GRID_VISIBLE_ROWS,
    math.ceil(#CATALOG / C.GRID_COLUMNS))
  printf('[WOW SPRITE] native controller %s-%s; state %s-%s; stack %s',
    hex4(C.NATIVE_CODE), hex4(C.NATIVE_CODE + #code - 1),
    hex4(C.STATE_BASE), hex4(C.STATE_END), hex4(C.STACK_TOP))
  printf('[WOW SPRITE] renderer: WoW Draw_Actor_Record %s -> Magic RAM + Pattern Board',
    hex4(C.DRAW_ACTOR_RECORD))
  printf('[WOW SPRITE] rotate: injected native iWizard/Nutter eight-write 4x4 adapter at %s',
    hex4(labels.rotate_sprite_90))
  print('[WOW SPRITE] rotate geometry: fixed 20x18 ROM source -> 20x20 zero-padded output; writes=200')
  printf('[WOW SPRITE] labels: WoW Print_String_With_Color %s; four-digit ROM address per cell',
    hex4(C.PRINT_STRING_COLOR))
  print('[WOW SPRITE] text colors: addresses blue; selected address red; version/instructions yellow')
  print('[WOW SPRITE] cursor: four visible rows; gallery scrolls only across top/bottom edge')
  print('[WOW SPRITE] controls: joystick browse; Fire info; 1P Exit; 2P Magic menu')
  print('[WOW SPRITE] Magic menu: edge-triggered Up/Down item; Left/Right change; Fire reset; 2P close')
  printf('[WOW SPRITE] preview workspace: %dx%d pixels; native renderer selected per Magic mode',
    C.PREVIEW_WORKSPACE_WIDTH * 4, C.PREVIEW_WORKSPACE_HEIGHT)
  print('[WOW SPRITE] preview anchor: native flop/right-edge and flip/bottom-edge adjustment')
  printf('[WOW SPRITE] video diagnostics: core %s; header capture xbyte=0..79 y=0..31',
    tostring(S.video_debug.VERSION or 'ACTIVE'))
  print('[WOW SPRITE] highlight cleanup: explicit old visible-row and column tracking')
  printf('[WOW SPRITE] selection reserve: bitmap %s; animation list %s (%d)',
    hex4(C.SELECTION_BITMAP), hex4(C.ANIMATION_LIST), C.ANIMATION_CAPACITY)
  printf('[WOW SPRITE] native Magic action record: %s-%s',
    hex4(C.ACTION_TRACE_BUFFER), hex4(C.ACTION_TRACE_END))
  print('[WOW SPRITE] palette writes: NONE; current initialized WoW palette retained')
  audit_catalog(false)
  print_help()
  print_selected('INITIAL')

  lab.native:handoff(C.NATIVE_CODE, C.STACK_TOP)
end

function M.update(_lab)
  if not S.active or not S.program then return end

  local redraw = S.program:read_u8(C.STATE_REDRAW_SEQUENCE)
  if redraw ~= S.last_redraw_sequence then
    S.last_redraw_sequence = redraw
    printf('[WOW SPRITE] REDRAW seq=%d first_row=%d first_index=%d', redraw,
      S.program:read_u8(C.STATE_FIRST_ROW), S.program:read_u8(C.STATE_FIRST_INDEX) + 1)
  end

  local event = S.program:read_u8(C.STATE_EVENT_SEQUENCE)
  if event ~= S.last_event_sequence then
    S.last_event_sequence = event
    local event_type = S.program:read_u8(C.STATE_EVENT_TYPE)
    if event_type == 1 then
      print_selected('SELECT')
    elseif event_type == 2 then
      print_selected('FIRE')
      print('[WOW SPRITE] Fire multi-selection is reserved for the animation phase')
    elseif event_type == 3 then
      local item = S.program:read_u8(C.STATE_MENU_ITEM)
      printf('[WOW SPRITE] MENU %s ITEM=%s',
        S.program:read_u8(C.STATE_MENU_ACTIVE) ~= 0 and 'OPEN' or 'CLOSED',
        MAGIC_ITEM_NAMES[item + 1] or tostring(item))
    elseif event_type == 4 then
      print_magic_trace()
    else
      printf('[WOW SPRITE] native event seq=%d type=%d', event, event_type)
    end
  end
end

function M.stop(_lab)
  if not S.active then return end
  S.active = false
  restore_shortcuts()
  if S.video_debug then S.video_debug:clear(HEADER_SNAPSHOT_NAME) end
  print('[WOW SPRITE] return to Wizard of Wor Lab')
  S.program = nil
  S.video_debug = nil
  S.lab = nil
end

return M
