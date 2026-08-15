# Wizard of Wor Sound Browser

`wow_sound_browser.lua` is a MAME Lua utility for browsing and testing the 24 non-speech sound requests in *Wizard of Wor*.

WoW boots normally. After startup speech and pending sound requests become idle, the browser takes over foreground execution while leaving the game's interrupt-driven sound service active. Playback uses WoW's original `$D240-$D243` request interface, ROM sound streams, and resident sound engine.

The utility does not synthesize the catalog in Lua and does not directly write the Astrocade sound registers for playback.

For the Astrocade sound hardware and WoW sound-engine map, see `docs/WOW_SOUND_MAP.md`.

## Run

From the repository root:

```sh
mame -console -window -autoboot_script tools/Lua/wow_sound_browser.lua wow
```

To use a locally built ROM set:

```sh
mame -console -window -autoboot_script tools/Lua/wow_sound_browser.lua -rompath roms/ wow
```

The browser is designed for MAME 0.289 or later.

## Controls

- **Up / Down** — move through the 24-sound catalog
- **Fire** — play the selected sound
- **Fire on the active sound** — stop it
- **Fire on a different sound** — stop the current sound and play the new selection
- **2P Start** — play all 24 sounds; press again to stop Play All
- **1P Start** — exit MAME

Left and Right are unused.

During Play All, Fire stops the current sound and continues to the next catalog entry after the normal pause.

## Screen

The catalog uses these columns:

| Column | Meaning |
| --- | --- |
| `REQ` | WoW request selector, for example `R3B5` |
| `LVL` | Native WoW sound priority, 0-2 |
| `PRI` | Primary sound-stream entry address, or `----` |
| `SEC` | Secondary sound-stream entry address, or `----` |
| `EVENT` | Current event identification |
| `Vxxx` | Browser version |

The `LIVE` line shows the current state of the primary and secondary WoW sound engines.

Example:

```text
LIVE P WAIT 8A91  S WAIT 8A7E
```

The address shown for an active engine is its saved next-command pointer. It advances through the ROM sound sequence as WoW decodes commands, waits, jumps, and modulators. It is not a Z80 program counter.

Idle engines display `----` instead of the stale pointer remaining in their RAM record.

### Live states

| State | Meaning |
| --- | --- |
| `DECODE` | WoW may decode more stream commands |
| `WAIT` | A native wait counter is active |
| `MODn` | `n` native modulator slots are active |
| `LATCH` | Stream activity has stopped but audible register state remains |
| `IDLE` | No active stream, wait, modulator, or audible volume state |

## Play All

Play All starts at the first catalog entry and auditions all 24 requests in order.

- Pause between sounds: **0.75 seconds**
- Naturally terminating sounds advance as soon as both WoW sound engines reach `IDLE`
- A sound still active after **4.0 seconds** is reset so the run cannot be blocked by sustained effects
- **2P Start** stops the complete Play All run
- **Fire** stops only the current sound and continues with the next entry

The four-second cutoff is a Play All safety limit, not a declaration that a sound is infinite.

## Console commands

```text
wsplay(n)              Play catalog entry 1..24
wsplay("R2B1")         Play a request by request/bit identifier
wsall()                Play all 24 catalog entries
wsstop()               Stop the current sound or Play All run
wslist()               List the complete catalog
wsinfo()               Show selected request and engine state
wsstate()              Show both native sound-engine records
wsdiag()               Show ROM/RAM anchors, request bytes, and engine state
wsinput()              Show raw and decoded WoW input state
wsexit()               Exit MAME
wshelp()               Show the command list
```

## Trace logging

Each played request automatically produces an engine-state trace in the MAME console. A blank line separates sound sequences.

Example:

```text
[WOW SOUND] PLAY R3B5 request=$D242 mask=$20 pri=1 P8A81 S8A6C  DUAL CHIP EVENT
[WOW SOUND] TRACE R3B5 START entry=P8A81 S8A6C
[WOW SOUND] TRACE R3B5 P WAIT $8A91  S WAIT $8A7E
[WOW SOUND] TRACE R3B5 P DECODE $8A91  S DECODE $8A7E
[WOW SOUND] TRACE R3B5 P MOD1 $8A69  S MOD2 $8A69
[WOW SOUND] TRACE R3B5 P IDLE ----  S IDLE ----
[WOW SOUND] TRACE R3B5 END IDLE
```

The `START` addresses are the stream entry points installed by the request. Later addresses are the saved next-command pointers inside those streams.

`wsstate()` provides the lower-level record values, including stream pointer, priority, ready flag, wait counter, active modulator count, and the eight-register sound image.

## Runtime operation

The browser waits at least two seconds after startup and takes over only when the startup speech queue and pending sound requests are idle.

Foreground execution is replaced by a small RAM loop that keeps interrupts enabled, calls WoW's native request dispatcher, and services the native on-screen UI. WoW's normal interrupt path continues to run the periodic sound/speech service.

The browser uses these work-RAM locations after takeover:

```text
$D400-$D414  foreground HALT / request-dispatch / UI loop
$D418        UI repaint-pending flag
$D420-...    generated native WoW UI code
$D600-...    current UI strings
$DFE0        private browser stack
```

The screen is drawn through WoW's resident text renderer and character table. No MAME overlay is used.

Before takeover, the script validates key WoW ROM signatures, including the sound service jump table, sound-stream opcode table, fallback stream byte, and native text renderer. A mismatched ROM is rejected rather than driven with fixed WoW addresses.

## Native request/reset behavior

Every manual audition begins by resetting both WoW sound engines through the game's own request mechanism before posting the selected request. This prevents an earlier sustained or higher-priority sound from blocking the next selection.

The Stop operation uses the same native reset path.

The browser keeps `$D244` enabled after takeover so WoW's normal sound/speech service continues while foreground gameplay is frozen.

## Notes

- The catalog contains the 24 request selectors actually decoded as sounds by the English WoW ROM.
- SC-01 speech is not part of this tool.
- Generic names such as `GLOBAL EVENT`, `DUAL CHIP EVENT`, and `UNRESOLVED EVENT` are retained where the exact gameplay identity has not yet been established.
- Primary and secondary stream addresses refer to WoW ROM sound-command data, not callable Z80 routines.
