# Wizard of Wor Sound Browser

`wow_sound_browser.lua` provides an in-game browser for the 24 non-speech sound requests in *Wizard of Wor* under MAME 0.289+.

WoW boots normally. When startup speech and pending sound requests are idle, Lua installs a native Z80 controller in work RAM and transfers foreground execution to it. The controller polls WoW inputs, posts the game's `$D240-$D243` sound requests, calls the resident reset/dispatch entry points, and runs Play All. WoW's interrupt-driven sound service continues the installed ROM streams and updates the two Astrocade custom I/O ICs.

Lua provides ROM validation, code/data injection, native menu preparation, console commands, and engine-state trace output.

Hardware and resident sound-engine details are documented in `docs/SOUND_MAP.md`.

## Run

```sh
mame -console -window -autoboot_script tools/Lua/wow_sound_browser.lua wow
```

With a local ROM path:

```sh
mame -console -window -autoboot_script tools/Lua/wow_sound_browser.lua -rompath roms/ wow
```

## Controls

- **Up / Down** — select a catalog entry
- **Fire** — play the selected sound
- **Fire on the active selection** — stop the sound
- **Fire on a different selection** — replace the active sound with the selected sound
- **2P Start** — start or stop Play All
- **1P Start** — exit MAME

During Play All, Fire ends the current sound and advances after the inter-sound gap.

## Screen

| Column | Meaning |
| --- | --- |
| `REQ` | WoW request selector, for example `R3B5` |
| `PSTR` | Primary ROM sound-stream entry address, or `----` |
| `SSTR` | Secondary ROM sound-stream entry address, or `----` |
| `EVENT` | Event identification |
| `Vxxx` | Browser version |

Stream-install priority is reported as `pri=` in the console `PLAY`, `wslist()`, and `wsinfo()` output.

The screen uses WoW's resident text renderer and character table.

### Engine status row

The blue status row reports each engine phase and saved stream pointer:

```text
        P WAIT   8A91  S WAIT   8A7E
READY   P IDLE   ----  S IDLE   ----
```

The leading field is blank while either engine is active. At idle it reports browser state:

| State | Meaning |
| --- | --- |
| `READY` | Browser is idle and ready to play; also shown after natural sound completion |
| `PAUSE` | Play All inter-sound gap is active |
| `STOPPED` | Playback was explicitly stopped with Fire or 2P Start |

Engine phases:

| Phase | Meaning |
| --- | --- |
| `DECODE` | Stream-ready state allows the decoder to execute commands |
| `WAIT` | Native wait counter is active |
| `MODn` | `n` modulator slots have a nonzero countdown |
| `LATCH` | Decoder, wait, and modulator activity are clear while the saved volume image remains audible |
| `IDLE` | Decoder, wait, modulator, and audible-volume activity are clear |

The displayed pointer is the engine's saved next-command address. It advances through the ROM stream as commands execute. An engine record can retain its last pointer after becoming idle; that retained value does not indicate active decoding.

## Play All

Play All starts at catalog entry 1 and runs all 24 requests in order.

- Inter-sound gap: **45 native ticks** (about 0.75 seconds)
- Natural completion advances when both sound engines reach `IDLE`
- Active-sound limit: **240 native ticks** (about 4 seconds)
- **Fire** ends the current sound and continues the run
- **2P Start** ends the Play All run

The active-sound limit provides deterministic progression for sustained effects.

## Console commands

```text
wsplay(n)              Play catalog entry 1..24 through the native mailbox
wsplay("R2B1")         Play by request/bit identifier
wsstop()               Request a native stop
wsall()                Toggle native Play All
wslist()               List the 24 catalog entries
wsinfo()               Show selected request and browser state
wsstate()              Show both sound-engine states
wsexit()               Exit MAME
wshelp()               Show command list
```

The mailbox at `$D70C-$D70D` carries administrative play/stop/Play All requests from the console to the injected controller. The Z80 controller executes those operations through WoW's resident sound system.

## Trace logging

Lua observes the two WoW sound-engine records and reports state transitions. Playback itself is performed by the injected Z80 controller and WoW's resident sound code.

A normal startup reports the native controller and request table:

```text
[WOW SOUND] 2.1.3-20260815-1349 loaded from wow_sound_browser.lua; takeover begins after 2.0s when startup speech/requests are idle
[WOW SOUND] native browser takeover active (auto); Z80 controller=$D400-$D6F6 catalog=$DB00
```

### Natural completion

These three captured sounds progress through different native engine paths and all terminate naturally:

```text
[WOW SOUND] PLAY R2B0 request=$D241 mask=$01 pri=1 P---- S8928  PLAYER DEATH
[WOW SOUND] TRACE R2B0 START entry=P---- S8928
[WOW SOUND] TRACE R2B0 P IDLE $8741  S MOD2 $894F
[WOW SOUND] TRACE R2B0 P IDLE $8741  S DECODE $894F
[WOW SOUND] TRACE R2B0 P IDLE $8741  S WAIT $8953
[WOW SOUND] TRACE R2B0 P IDLE $8741  S DECODE $8953
[WOW SOUND] TRACE R2B0 P IDLE $8741  S IDLE $8954
[WOW SOUND] TRACE R2B0 END IDLE

[WOW SOUND] PLAY R2B1 request=$D241 mask=$02 pri=0 P---- S887B  PLAYER FIRE
[WOW SOUND] TRACE R2B1 START entry=P---- S887B
[WOW SOUND] TRACE R2B1 P IDLE $8741  S MOD2 $88A4
[WOW SOUND] TRACE R2B1 P IDLE $8741  S MOD1 $88A4
[WOW SOUND] TRACE R2B1 P IDLE $8741  S DECODE $88A4
[WOW SOUND] TRACE R2B1 P IDLE $8741  S MOD1 $88B2
[WOW SOUND] TRACE R2B1 P IDLE $8741  S DECODE $88B2
[WOW SOUND] TRACE R2B1 P IDLE $8741  S IDLE $88B3
[WOW SOUND] TRACE R2B1 END IDLE

[WOW SOUND] PLAY R3B1 request=$D242 mask=$02 pri=0 P---- S890E  MONSTER DEATH
[WOW SOUND] TRACE R3B1 START entry=P---- S890E
[WOW SOUND] TRACE R3B1 P IDLE $8741  S WAIT $8927
[WOW SOUND] TRACE R3B1 P IDLE $8741  S DECODE $8927
[WOW SOUND] TRACE R3B1 P IDLE $8741  S IDLE $8928
[WOW SOUND] TRACE R3B1 END IDLE
```

`END IDLE` means both software sound engines satisfied the browser's idle test. For these examples, the active secondary engine moves through modulation, decode, and/or wait states before returning to idle.

### Sustained sounds and replacement

Some requests establish sound state that does not reach idle on its own. A trace can settle in `LATCH`, `MODn`, or a long `WAIT` until another request or an explicit stop resets the engine.

```text
[WOW SOUND] PLAY R1B0 request=$D240 mask=$01 pri=0 P89BE S89E5  GLOBAL EVENT 0
[WOW SOUND] TRACE R1B0 START entry=P89BE S89E5
[WOW SOUND] TRACE R1B0 P WAIT $89CE  S WAIT $89F5
[WOW SOUND] TRACE R1B0 P DECODE $89CE  S DECODE $89F5
[WOW SOUND] TRACE R1B0 P WAIT $89D6  S WAIT $89FD
[WOW SOUND] TRACE R1B0 P DECODE $89D6  S DECODE $89FD
[WOW SOUND] TRACE R1B0 P LATCH $89E5  S LATCH $8A0C

[WOW SOUND] PLAY R1B1 request=$D240 mask=$02 pri=0 P89A0 S89AF  GLOBAL EVENT 1
[WOW SOUND] TRACE R1B1 START entry=P89A0 S89AF
[WOW SOUND] TRACE R1B1 P LATCH $89AF  S LATCH $89BE
[WOW SOUND] TRACE R1B1 END NEW PLAY
```

`END NEW PLAY` records replacement by another browser selection. `END FIRE STOP` records an explicit Fire stop.

The stream at `$8740` contains WoW's reset-engine fallback command. A transition to `$8740` therefore reflects native reset/fallback processing rather than a new catalog sound.

### Play All

Play All reports its native timing limits and an end reason for each sound that requires intervention:

```text
[WOW SOUND] PLAY ALL START: 24 sounds; native gap 45 ticks; native limit 240 ticks

[WOW SOUND] PLAY R1B0 request=$D240 mask=$01 pri=0 P89BE S89E5  GLOBAL EVENT 0
[WOW SOUND] TRACE R1B0 START entry=P89BE S89E5
[WOW SOUND] TRACE R1B0 P WAIT $89CE  S WAIT $89F5
[WOW SOUND] TRACE R1B0 P DECODE $89CE  S DECODE $89F5
[WOW SOUND] TRACE R1B0 P LATCH $89E5  S LATCH $8A0C
[WOW SOUND] TRACE R1B0 P DECODE $8740  S DECODE $8740
[WOW SOUND] TRACE R1B0 END PLAY ALL LIMIT
```

`END PLAY ALL LIMIT` means the sound was still active when the 240-tick limit expired. The controller resets the engines, waits the 45-tick inter-sound gap, and advances to the next catalog entry. Natural terminators report `END IDLE`.

A complete run ends with:

```text
[WOW SOUND] PLAY R4B3 request=$D243 mask=$08 pri=1 P8B2E S8B5D  DUAL CHIP EVENT
[WOW SOUND] TRACE R4B3 START entry=P8B2E S8B5D
[WOW SOUND] TRACE R4B3 P MOD1 $8B4C  S MOD1 $8B4C
[WOW SOUND] TRACE R4B3 P DECODE $8B4C  S DECODE $8B4C
[WOW SOUND] TRACE R4B3 P MOD1 $8B5C  S MOD1 $8B5C
[WOW SOUND] TRACE R4B3 P DECODE $8B5C  S DECODE $8B5C
[WOW SOUND] TRACE R4B3 P IDLE $8B5D  S IDLE $8B5D
[WOW SOUND] TRACE R4B3 END IDLE
[WOW SOUND] PLAY ALL COMPLETE: 24 sounds
```

### Log fields

`PLAY` identifies the request byte, bit mask, stream-install priority, primary/secondary stream entries, and event label:

```text
PLAY R4B0 request=$D243 mask=$01 pri=2 P88E2 S8905  SPECIAL DEATH EVENT
```

`TRACE ... START` repeats the initial stream entries. Transition lines report the current phase of each engine and its saved stream pointer. The phase names are the same classifications used by the on-screen status row.

Trace end reasons are:

| End reason | Meaning |
| --- | --- |
| `IDLE` | Both engines reached natural idle |
| `FIRE STOP` | Fire stopped the active sound |
| `NEW PLAY` | Another selection replaced the active sound |
| `PLAY ALL LIMIT` | Play All reached the 240-tick active-sound limit |
| `PLAY ALL STOP` | Play All was stopped with 2P Start |

## Native controller

The fixed controller occupies `$D400-$D6F6`. Each foreground service pass wakes from `HALT`, calls WoW's request dispatcher at `$8003`, services the console mailbox, polls controls, advances manual/Play All state, and executes a prepared native UI display list when requested.

Playing a catalog entry calls WoW's `$8006` sound initialization entry, reads the request-bank offset and mask from the table at `$DB00`, writes the corresponding request bit, and calls `$8003` to dispatch it. `$8006` resets both sound engines and also validates WoW's speech-queue state. The normal interrupt path continues the sound stream through the resident periodic service.

### Work RAM

```text
$D400-$D6F6  native browser controller
$D700-$D712  browser state and console mailbox
$D740-$D837  generated native UI display program
$D900-$DADF  current UI text, markers, status, and footer
$DB00-$DB2F  24-entry request table
$DFE0        browser stack top
```

Before takeover, Lua validates the expected WoW sound and text entry points, installs the controller and request table, initializes the display, and starts execution at `$D400`.

## Implementation notes

- The catalog contains the 24 non-speech request selectors decoded by WoW.
- `PSTR` and `SSTR` identify ROM sound-stream data entry points.
- `MODn` counts modulator slots whose countdown byte is nonzero.
- Generic event labels mark requests awaiting gameplay call-site identification.
- Speech uses WoW's separate SC-01 subsystem and speech browser.

## Possible enhancements

- Resolve generic event names from WoW request call sites.
- Add optional opcode-level stream decoding to the console trace.
- Add modulator-slot detail to `wsstate()` or an optional diagnostic trace.
- Make the Play All gap and active-sound limit configurable in native state.
