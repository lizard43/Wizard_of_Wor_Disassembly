# Wizard of Wor Lab Maze Browser Module

The Maze Browser is a native Wizard of Wor Lab module for displaying all 24
packed mazes directly from the Wizard of Wor ROM.

Native Z80 owns maze selection, joystick repeat, screen clearing, maze
expansion, maze drawing, version/status text, and the bottom instruction line.
Lua owns module lifecycle and console diagnostics. The module does not patch
ROM and does not copy maze artwork or topology into its application image.

## Installation

Copy the Lua file into the Lab's dynamically scanned module directory as:

```text
tools/Lua/wow_lab/modules/maze_browser.lua
```

Start the Lab normally, select **MAZE BROWSER**, and press Fire.

The cache-busted source deliverables install under their repository names:

```text
wow_disassembly_20260817-1623.asm  -> src/wow_disassembly.asm
wow_equates_20260817-1623.include -> src/wow_equates.include
```

## Display

The initial screen shows maze index 00. The game renderer occupies the normal
maze area, including the fixed side corridors, lower boundary cells, and red
portal gates.

- `V11` appears in the unused top-right screen margin.
- One centered blue line appears between the two lower boundary cells:
  `MAZE 00 1B1D`.
- The fixed 18-byte / 11-by-6 geometry is reported in the startup console log
  instead of consuming a display line.
- The bottom row is yellow and reads:

```text
JOY UR NEXT DL PREV 2P FLASH 1P EXIT
```

The information line fits inside the center gap below the 11-by-6 core and does
not overwrite either lower boundary cell. The three-character version fits
inside the right margin and does not replace the outer maze wall.

## Controls

- **Up or Right** — next maze
- **Down or Left** — previous maze
- **2P Start** — run the game's Worluk-death maze-color flash
- **1P Start** — return to the Wizard of Wor Lab menu

Selection wraps in both directions: 23 advances to 00, and 00 retreats to 23.
Cardinal directions repeat after a short hold. Diagonal and opposing-direction
states release repeat rather than selecting a direction arbitrarily.

## Native ROM path

Each redraw follows the game's resident path:

1. Read the selected little-endian maze pointer from `$1AED`.
2. Store the zero-based selection in `Maze_Index` at `$D318`.
3. Call `Expand_Selected_Maze` at `$1A7D`.
4. The game expands the 18 packed bytes into 66 cell masks at `$D178-$D1B9`.
5. Call `Draw_Maze_With_Portal_Gates` at `$17AA`.
6. The complete entry calls the core renderer at `$17C5`, which draws cells
   through `$185F`, then overlays the two red portal gates.
7. Draw version, address, geometry, and controls through the resident
   `Print_String_With_Color` routine at `$03B5`.

`$1A7D` is the expansion sub-entry after the gameplay-only dungeon-counter
increment at `$1A79`. The browser therefore uses the game decoder without
advancing `Dungeon_Number`.

The module forces the normal blue maze expansion selector before `$17AA`.
The complete renderer changes XPAND and Magic mode as its drawing contract
requires. Palette changes are confined to the resident Worluk-death flash path
described below.

## 2P native color flash

The game-code trace identifies this as the **Worluk-killed** effect, not Wizard
death:

1. At command-stream `$128B`, `Stream_Jump_If_Nonzero` checks
   `Special_Actor_Color_State` at `$D1D8`. In this result path, a nonzero value
   records the Worluk escape and branches to `$12B0`, bypassing the kill-only
   flash.
2. The killed path falls through to command-stream `$1291`, where
   `Stream_Write_Byte` writes `$20` to `Worluk_Death_Flash_Countdown` at
   `$D1BD`.
3. On alternating game frame phases,
   `Update_Worluk_Death_Maze_Flash` at `$075B` uses the divider at `$D1BE`,
   alternates `COL1L`, `COL2L`, and `COL3L` between `$00` and `$07`, and counts
   down the 32 steps.
4. On completion it enters `Restore_Default_Foreground_Palette` at `$0752`,
   restoring the normal palette and sparkle setup.

The browser makes a new 2P Start edge perform the same `$D1BD=$20` state
write. Its foreground loop calls `$075B` every other display frame, matching
the game's alternating frame-service cadence. A 1P exit during the effect
forces the native completion path first so the Lab menu receives the restored
palette.

## Maze index and address catalog

The live pointer table defines this order:

| Index | ROM address | Index | ROM address | Index | ROM address |
|---:|---:|---:|---:|---:|---:|
| 00 | `$1B1D` | 08 | `$1B9B` | 16 | `$1C3D` |
| 01 | `$1C19` | 09 | `$1BAD` | 17 | `$1C4F` |
| 02 | `$1B2F` | 10 | `$1BBF` | 18 | `$1C61` |
| 03 | `$1B41` | 11 | `$1BD1` | 19 | `$1C73` |
| 04 | `$1B53` | 12 | `$1BE3` | 20 | `$1C85` |
| 05 | `$1B65` | 13 | `$1BF5` | 21 | `$1C97` |
| 06 | `$1B77` | 14 | `$1C07` | 22 | `$1CA9` |
| 07 | `$1B89` | 15 | `$1C2B` | 23 | `$1CBB` |

The index-01 address is intentionally non-sequential because the pointer table,
not physical data order, defines gameplay selection order.

## Source labels and equates

`wow_equates.include` is included before `ORG $0000`, which is the correct
placement: every hardware, memory-map, gameplay, and legacy address symbol is
defined before the first emitting statement.

The maze source now names the public resident path directly:

```text
$17AA  Draw_Maze_With_Portal_Gates
$17C5  Draw_Maze_From_Expanded_Cells
$185F  Draw_Maze_Cell_At_HL
$1A79  Load_And_Expand_Selected_Maze
$1A7D  Expand_Selected_Maze
$1AED  Maze_Pointer_Table
$075B  Update_Worluk_Death_Maze_Flash
$0752  Restore_Default_Foreground_Palette
$0807  Stream_Write_Byte
$082B  Stream_Jump_If_Nonzero
$16BC  Start_Foreground_Palette_Fade_Out
$16C7  Start_Foreground_Palette_Fade_In
```

Maze record names are keyed to `Maze_Index`, so `Maze_00_Data` is at `$1B1D`,
`Maze_01_Data` is at `$1C19`, and `Maze_23_Data` is at `$1CBB`. The equate file
also identifies the expanded maze buffer, packed/expanded geometry, palette
fade state, special-actor color state, and Worluk flash countdown/divider.

The relabeled source assembles to the same 45,056-byte CPU image as the supplied
source. The two CIM files are byte-identical with SHA-256:

```text
465994cda903d965b6ff03a8b8f4d05ea290c53568df8c7b01eac7d55f014b26
```

## Editor-library relationship

The JSON library's 24 `mazeIndex` and `address` fields agree with the resident
pointer table. Its topology policy deliberately normalizes non-reciprocal edges.
That changes the stored `compressedBytes` for maze indices 16, 17, 19, and 20
relative to ROM. The Maze Browser therefore uses the JSON address catalog only
as an audit reference; display always comes from live game ROM bytes.

## Module memory map

```text
$D380-$D3BF  permanent Lab ABI                         preserved
$D3C0-$D3FD  permanent Lab IM2 kernel                  preserved
$D3FE-$D3FF  permanent IM2 vector                      preserved

$D400-$D5EE  Maze Browser native controller and text
$D5EF-$D6FF  controller reserve
$D700-$D70C  selection, input, event, address, redraw, 2P/flash state
$DFE0         native application stack top

$D178-$D1B9  resident expanded maze cells              game-owned
$D1BD-$D1BE  resident Worluk flash countdown/divider    game-owned
```

The foreground runs an `EI` / `HALT` loop. The permanent Lab kernel continues
to service WoW sound/speech cadence, heartbeat, and the universal 1P return
request.

## Console diagnostics

These commands exist only while the Maze Browser is active:

```text
wmzinfo()          selected maze, pointer, ROM address, bytes, and hash
wmzstatus()        native PC, input, selection, redraw, 2P, and flash state
wmzlist([n],[c])   list from zero-based maze index n for c entries
wmzaudit([detail]) audit live pointers; true prints all 24 entries
wmzredraw()        request a native redraw
wmzhelp()          command summary
```

## First test capture

Please capture these items from the first MAME run:

1. The complete startup console block through `catalog audit`.
2. A screenshot of initial maze 00 showing `V11`, the blue `MAZE 00 1B1D`
   line, and the yellow instruction row.
3. Console and screenshots after one Right and one Up. Expected selections are
   index 01 at `$1C19`, then index 02 at `$1B2F`.
4. Console and screenshots after one Left and one Down to verify both reverse
   controls.
5. From index 00, press Left once and capture index 23 at `$1CBB`; press Right
   once and capture the wrap back to index 00.
6. Hold Right long enough to produce several repeats, then run `wmzstatus()`.
7. Run `wmzaudit(true)` and capture the complete 24-entry pointer/hash list.
8. Press 2P Start and capture several phases of the native color flash, its
   automatic palette restoration, and the console `FLASH` line.
9. Press 1P Start and capture the return line plus the restored Lab menu.

If any wall, portal gate, lower boundary cell, status text, or version glyph is
misplaced, include the screenshot plus `wmzstatus()` and `wmzinfo()` output.
