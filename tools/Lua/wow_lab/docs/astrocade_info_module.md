# Astrocade Info module

Version `1.2.0-20260820-0925`

`astrocade_info.lua` is the hardware-information module for the current Wizard of Wor Lab. Its subject is the Bally/Midway Astrocade arcade platform; game-specific decoding is kept at the edges so the module can move into a broader Astrocade Lab.

The cabinet screen is intentionally an instrument panel. It shows hardware values, decoded state, ROM identity, and navigation. Capture mechanics and implementation details stay in this document and the console log.

## Installation and versions

Changed files in this revision install at these stable paths:

```text
core/astrocade_probe.lua      1.2.0-20260820-0925
modules/astrocade_info.lua    1.2.0-20260820-0925
modules/sound_browser.lua     1.1.9-20260820-0925
```

This revision keeps the current Lab baseline unchanged:

```text
core/lab.lua                  1.4.1-20260820-0825
core/native.lua               1.1.0-20260816-1900
core/memory.lua               1.1.0-20260816-1900
core/module_loader.lua        1.1.1-20260817-0848
core/video_debug.lua          1.0.0-20260817-1645
core/lab_fonts.lua            1.0.1-20260820-0825
core/lab_text.lua             1.0.0-20260819-2213
core/path.lua                 1.0.5-20260816-1814
```

`lab_fonts.lua` is not changed in this revision. The Tiny `$` glyph improvement remains the one already present in font core `1.0.1`.

## Controls

```text
LEFT or UP       previous tab
RIGHT or DOWN    next tab
1P START         return to Lab menu
```

The native controller reads only the P1/P2 direction ports needed for tab navigation. There is no general-purpose INPUT page; Wizard of Wor already provides its cabinet/DIP input test through the game's service diagnostics.

## Tabs

The module now has six tabs:

```text
SYSTEM   VIDEO   PALETTE   ROM   AUDIO   LAB
```

### SYSTEM

Shows the running MAME machine and CPU, the arcade memory map, populated 4K ROM-window count, hardware profile, and the captured video-mode/HORCB/VERBL state.

The hardware profile is based on the running MAME machine. ROM identity is separate. A WoW-compatible homebrew running under the WoW driver can therefore retain the WoW hardware interpretation even when its program CRCs are not canonical WoW CRCs.

### VIDEO

Shows the captured Astrocade video/data-chip state:

```text
$08  CONCM   consumer/commercial mode
$09  HORCB   horizontal color boundary + background pixel
$0A  VERBL   vertical blank line
$0D  INFBK   interrupt vector low byte
$0E  INMOD   interrupt mode/enable
$0F  INLIN   interrupt scanline
$0C  MAGIC   last Function Generator mode
$19  XPAND   last expansion color pair
$78-$7E      last Pattern Board register writes
```

Magic is decoded as shift bits `1:0`, ROTATE bit `2`, EXPAND bit `3`, OR bit `4`, XOR bit `5`, FLOP bit `6`, and bit `7` as `B7`. Pattern Board vertical transfer direction is separate from the Magic byte.

XPAND bits `1:0` select the destination pixel for a source zero and bits `3:2` select the destination pixel for a source one.

### PALETTE

The page shows both physical four-color banks at the same time.

The eight Astrocade color registers map as:

```text
LEFT                    RIGHT
P0 -> register 4        P0 -> register 0
P1 -> register 5        P1 -> register 1
P2 -> register 6        P2 -> register 2
P3 -> register 7        P3 -> register 3
```

For canonical WoW the ROM table at `$00C5-$00CC` is:

```text
51 7C F3 C7 00 56 09 9E
```

WoW sends those bytes through `$0B` with `OTIR`. The block port maps the eight writes in descending transfer order:

```text
byte 0 -> register 7 = $51
byte 1 -> register 6 = $7C
byte 2 -> register 5 = $F3
byte 3 -> register 4 = $C7
byte 4 -> register 3 = $00
byte 5 -> register 2 = $56
byte 6 -> register 1 = $09
byte 7 -> register 0 = $9E
```

The probe preserves the `$0B` bus event and also projects every block write into its physical color-register latch. The screen therefore compares the ROM transfer bytes with the captured register image and reports `MATCH=YES` when they agree.

#### Showing both physical palettes

A normal WoW screen places HORCB beyond the visible 80-byte row, so only the left bank is normally visible. A real 2bpp pixel cannot display a right-bank color while it remains on the left side of HORCB.

For the PALETTE tab only, the native Info controller temporarily moves the horizontal color boundary to split the display into two visible regions. The left swatches are therefore displayed by registers `4-7`, and the right swatches are displayed by registers `0-3`. These are real hardware palette results, not RGB approximations calculated by Lua.

The page reports both values:

```text
CAPTURE $09=...       game HORCB captured before Lab takeover
PALETTE VIEW $09=...  temporary split used by the palette display
```

Leaving the PALETTE tab restores the captured game `$09` value. Returning to the Lab menu while PALETTE is active also restores it before the menu is redrawn.

On the WoW/Gorf sparkle hardware path, ordinary P0 pixels display black; the raw P0 color-register bytes are still shown alongside their swatches.

### ROM

CRC32s the bytes currently mapped in these 4K CPU windows:

```text
$0000-$0FFF
$1000-$1FFF
$2000-$2FFF
$3000-$3FFF
$8000-$8FFF
$9000-$9FFF
$A000-$AFFF
$B000-$BFFF
$C000-$CFFF
```

Known WoW CRCs are labeled `WOW.X1` through `WOW.X7`; the known German X11 is labeled `GERMAN.X11`. Empty `$00`/`$FF` windows are identified separately. Other populated windows retain their CRC and are labeled `UNIDENTIFIED` rather than being treated as errors.

### AUDIO

Shows the captured register images for both Astrocade custom sound ICs:

```text
primary    $10-$17
secondary  $50-$57
```

The page decodes master oscillator, Tone A/B/C, vibrato, Tone A/B/C volume, modulation source, audible-noise enable, noise level, and noise mask. It also shows `$18/$58` block-write counts and the latest SC-01 command-bus read.

The sound block ports map selector `7..0` to registers in descending transfer order:

```text
$18 block                         $58 block
7 -> $17 Noise                    7 -> $57 Noise
6 -> $16 Volume A/B               6 -> $56 Volume A/B
5 -> $15 Vol C / modulation       5 -> $55 Vol C / modulation
4 -> $14 Vibrato                  4 -> $54 Vibrato
3 -> $13 Tone C                   3 -> $53 Tone C
2 -> $12 Tone B                   2 -> $52 Tone B
1 -> $11 Tone A                   1 -> $51 Tone A
0 -> $10 Master                   0 -> $50 Master
```

Probe `1.2.0` retains the original block-port event and projects it into these effective hardware registers.

### LAB

Shows the running Lab/core versions, Lab font geometry, probe counters, takeover-snapshot counters, and the Info module's native RAM allocations.

## Shared Astrocade I/O probe

`core/astrocade_probe.lua` begins observing Astrocade I/O during game boot because many output latches cannot be reconstructed later with an `IN` from the same numeric port.

Probe `1.2.0` adds a shared write-observer API. The global probe remains the single owner of the full Z80 I/O write tap; modules that need raw I/O events subscribe to that stream rather than installing an overlapping full-space tap.

This matters for Sound Browser. Version `1.1.8` installed its own full-I/O write tap when launched. With the resident Astrocade probe already active, MAME 0.289 could terminate in native code while the I/O tap set was being changed. Sound Browser `1.1.9` subscribes to the probe instead and keeps only its module-local program-space taps for WoW engine RAM and browser state.

If Sound Browser `1.1.9` encounters an older active probe without the shared-observer API, it disables capture diagnostics rather than attempting a second overlapping I/O tap. Playback remains separate from the diagnostic capture path.

The global probe no longer retains cabinet reads `$10-$13`; those are not needed by Astrocade Info after removal of the INPUT page. Module controllers continue to read their own cabinet controls directly.

## Display implementation

The title uses the Lab Compact 5x7 font in a 6x8 cell. The body uses Lab Tiny 3x5 in a 4x6 cell, providing an 80-column text grid on WoW's commercial display.

Tiny text and the palette swatches are written directly into packed video RAM. The only video-register write made by this module is the controlled `$09` HORCB change used to expose both physical palette banks on the PALETTE tab, followed by restoration of the captured value.

## Native application RAM

```text
$D400-$D7FF  native controller reserve
$D800-$D95D  Tiny font rows
$D960-$D97B  text color LUT + solid P0-P3 bytes
$D980-$DA27  Compact title bitmap
$DA40-$DEFF  current page display list
$DF00-$DF0A  native module state
$DFE0         stack top
```

The permanent Lab ABI/kernel below `$D400` remains separate.

## Console commands

While the module is active:

```text
ainfo()    module/tab/probe status
airoms()   mapped 4K ROM CRC32 list
aihelp()   command summary
```

## Validation

The changed Lua files were parsed and loaded with Lua 5.4, matching the Lua major/minor used by MAME 0.289 in the current Lab setup.

A probe test verified:

```text
$070B -> palette register 7
$000B -> palette register 0
$0718 -> primary sound $17
$0058 -> secondary sound $50
$3F17 read -> SC-01 command $3F
$0012 cabinet read -> not retained by global probe
```

The write-observer test verified that raw Astrocade writes reach a subscriber and stop after unsubscribe.

The Sound Browser capture test verified that an active Probe `1.2.0` results in zero private I/O-tap installations, one shared probe subscription, and the three existing program-space diagnostic taps. An older active probe is rejected safely without attempting a private I/O tap.

The Info module native controller assembles to 374 bytes (`$D400-$D575`). Static page generation produced:

```text
SYSTEM    546 bytes
VIDEO     480 bytes
PALETTE   488 bytes
ROM       455 bytes
AUDIO     445 bytes
LAB       611 bytes
```

All pages fit within the `$DA40-$DEFF` 1,216-byte display-list buffer. Both palette swatch groups fit their respective sides of the temporary commercial-mode boundary at packed byte 52.

Final acceptance still requires the MAME run: enter Astrocade Info, inspect both palette banks, leave PALETTE and verify the normal screen colors return, then enter Sound Browser and confirm normal playback/capture without a MAME process crash.
