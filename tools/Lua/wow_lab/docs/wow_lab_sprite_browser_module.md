# Wizard of Wor Lab Sprite Browser Module

The Sprite Browser is a native Wizard of Wor Lab module for inspecting the
game's fixed 20-by-18-pixel, packed 2bpp ROM sprites as a scrollable gallery.

This first complete browser cut implements display, native joystick navigation,
the moving selection border, and vertical gallery scrolling. Fire reports the
selected sprite for diagnostics. Rotation, pixel shifting, multi-selection,
and animation are reserved for later phases.

## Installation

Copy the Lua file into the Lab's dynamically scanned module directory as:

```text
tools/Lua/wow_lab/modules/sprite_browser.lua
```

Start the Lab normally, select **SPRITE BROWSER**, and press Fire.

## Controls

- **Up / Down / Left / Right** — move the selected sprite border
- **Fire** — report the selected catalog entry in the MAME console
- **1P Start** — return to the Wizard of Wor Lab menu

Cardinal directions repeat after a short hold. Diagonal and opposing direction
states do not move the selection.

## Gallery geometry

The Astrocade display is treated as 80 packed bytes by 204 visible rows. The
browser fits ten sprite cells across and eight down:

```text
10 columns x 8 visible rows = 80 visible sprites
104 catalog entries         = 11 catalog rows
```

Each cell is 8 packed bytes (32 pixels) wide and 24 scanlines high. A raw
5-byte-by-18-row sprite sits inside a 7-byte-by-22-row one-pixel selection box.
The remaining cell space separates neighboring sprites.

Moving below or above the visible eight-row window changes the first visible
catalog row and redraws the gallery. Movement inside the current window erases
only the old border and draws the new border; it does not redraw the sprites.

## Native rendering path

Sprite pixels are not decoded or painted by Lua. The native controller builds
the same five-byte draw descriptor used by Wizard of Wor and calls the resident
routine:

```text
$0B92  Draw_Actor_Record
```

For every visible catalog entry, the descriptor contains:

```text
byte 0    Magic control: shift 0, PLOP, no rotation
bytes 1-2 ROM sprite address
bytes 3-4 Magic-RAM destination offset
```

`Draw_Actor_Record` programs Magic RAM and the Pattern Board for the game's
fixed five-byte by eighteen-row actor transfer. The source remains in the
original WoW ROM. The browser does not copy sprite artwork into work RAM and
does not patch ROM.

The selection border uses direct packed-2bpp video writes in the padded area
around each sprite. Color index 3 forms the border. Border erasure writes only
the padding bytes, so the selected sprite is not damaged.

## Palette behavior

This version makes no palette-port writes and no XPAND-color writes. The
palette initialized before Lab takeover remains in effect exactly as requested.
Raw sprite pixel values 0 through 3 therefore use the current in-game color
mapping.

## Catalog

The module contains 104 unique ROM locations selected from the JSON records
that meet all of these conditions:

- an explicit WoW address is present;
- width is 20 pixels;
- height is 18 rows;
- row stride is five bytes;
- raw fixed-size mode is set;
- bitmap length is exactly 90 bytes.

Where the current disassembly has stronger labels than the JSON, the catalog
uses the current labels. In particular, the address groups now identified as
Burwor, Garwor, and Thorwor fire frames use their `*_FIRE_*` names, and the
single low-ROM Garwor frame at `$3CD5` is `GARWOR_3_UP`.

The catalog is grouped by animation family so later frame sequencing can use a
deliberate order instead of a raw address sort.

## Module memory map

```text
$D380-$D3BF  permanent Lab ABI                         preserved
$D3C0-$D3FD  permanent Lab IM2 kernel                  preserved
$D3FE-$D3FF  permanent IM2 vector                      preserved

$D400-$D6FF  Sprite Browser native controller reserve
$D700-$D713  selection, input, event and redraw state
$D720-$D724  five-byte WoW actor draw descriptor
$D800-$D8CF  104-entry ROM-address catalog
$D900-$D99F  80 Magic-RAM sprite destinations
$D9A0-$DA3F  80 physical-VRAM border destinations
$DFE0         native application stack top
```

The controller enters an `EI` / `HALT` foreground loop. The permanent Lab IM2
kernel continues to service WoW sound/speech cadence, the Lab heartbeat, and
the universal 1P Start return request.

## Logging and console diagnostics

Startup logging reports:

- module version;
- catalog and grid sizes;
- native controller, state, and stack addresses;
- use of resident `$0B92`;
- confirmation that palette writes are absent;
- catalog address/blank-image audit result.

Every native selection change reports the 1-based catalog index, absolute row
and column, visible row window, ROM address, live 90-byte FNV-1a hash, nonzero
byte count, and sprite label. A full redraw reports its sequence number and new
first row.

Module commands exist only while the Sprite Browser is active:

```text
wginfo()          selected sprite, ROM hash and grid state
wgstatus()        controller, CPU, input, event and redraw state
wglist([n],[c])   catalog list from 1-based entry n for c entries
wgaudit([detail]) catalog audit; true prints every live ROM hash
wgredraw()        request a native full-gallery redraw
wghelp()          command summary
```

## First test capture

Please capture these items from the first MAME run:

1. The complete startup console block through `catalog audit`.
2. A screenshot of the initial 10-by-8 gallery with the border on entry 1.
3. Console output after one Right, one Down, and one Left move.
4. A screenshot and the `REDRAW`/`SELECT` lines after moving Down from catalog
   row 7 into row 8, which is the first scrolling boundary.
5. The console return line after pressing 1P Start.

If the sprite shapes are mirrored, shifted, vertically inverted, or have row
tearing, include the screenshot and the output of `wgstatus()` and `wginfo()`.
