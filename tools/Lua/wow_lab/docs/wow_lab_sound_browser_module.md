# Wizard of Wor Lab Sound Browser Module

The Sound Browser is the Wizard of Wor Lab module for browsing, playing, tracing, and capturing the 24 non-speech sound requests decoded by *Wizard of Wor*.

Playback is native. The injected Z80 controller posts WoW's `$D240-$D243` request bits, calls the resident request dispatcher, and uses the game's original ROM sound streams and software sound engines. Lua installs the module, prepares native UI data, exposes diagnostic commands, and records read-only execution evidence.

The module does not synthesize sound in Lua and does not replace the WoW sound engine with captured register playback.

For the complete hardware and resident-engine description, see [`SOUND_MAP.md`](../../../../docs/SOUND_MAP.md).

For the Lab module contract and permanent memory boundary, see [Wizard of Wor Lab Modules](wow_lab_modules.md).

## Launch

Start the Lab:

```sh
mame -console -window -autoboot_script tools/Lua/wow_lab/wow_lab.lua -rompath roms/ wow
```

Select **SOUND BROWSER** and press Fire.

The module version is displayed in the upper-right corner. Version `1.1.8-20260817-1344` displays as `V118`.

## Controls

- **Up / Down** — select one of the 24 request entries
- **Fire** — play the selected request
- **Fire on the active selection** — stop the active sound
- **Fire on a different selection** — replace the active sound with the new request
- **2P Start** — start or stop Play All
- **1P Start** — return to the Wizard of Wor Lab menu

Left and Right are unused.

During Play All, Fire stops the current sound and advances to the next catalog entry after the normal gap. 2P Start ends the complete Play All run.

## Screen

The catalog columns are:

| Column | Meaning |
| --- | --- |
| `REQ` | WoW request selector, such as `R2B1` |
| `PSTR` | primary ROM sound-bytecode entry address, or `----` |
| `SSTR` | secondary ROM sound-bytecode entry address, or `----` |
| `EVENT` | gameplay/event identification |
| `Vxxx` | compact module version |

`PSTR` and `SSTR` are ROM data pointers. They are not Z80 program counters, callable routines, RAM addresses, or Astrocade I/O ports.

The blue engine row shows each resident sound engine's current phase and saved stream pointer. A retained pointer can remain in an idle engine record; the phase determines whether that stream is active.

### Engine phases

| Phase | Meaning |
| --- | --- |
| `DECODE` | the stream-ready state allows WoW's decoder to execute commands |
| `WAIT` | the engine wait counter is active |
| `MODn` | `n` modulator slots currently have nonzero countdowns |
| `LATCH` | decoder, wait, and modulator activity are clear while the saved volume image remains audible |
| `IDLE` | decoder, wait, modulator, and audible-volume activity are clear |

## The complete native sound path

The browser exposes three distinct identities for a sound request:

```text
gameplay/event identity
        |
        v
WoW request selector
R1.B0 ... R4.B3
        |
        v
ROM sound-bytecode entry
PSTR and/or SSTR
```

Playback then continues through the resident software engine and the Astrocade hardware:

```text
selected catalog entry
        |
        v
native browser writes request bit in $D240-$D243
        |
        v
$8003  WoW request dispatcher
        |
        v
$851D  install selected ROM stream
        |
        +--> primary engine RAM at $D270
        |       modulators at $D246
        |
        +--> secondary engine RAM at $D2AC
                modulators at $D282
        |
        v
$8437  WoW sound-stream decoder
        |
        v
engine register image and modulation state in RAM
        |
        v
$8000 / $80E6 periodic resident sound service
        |
        v
OTIR through block port $18 or $58
        |
        v
Astrocade custom I/O IC registers
$10-$17 primary / $50-$57 secondary
```

This is the core reverse-engineering value of the module: a visible request ID can be correlated with its static gameplay producer, its installed ROM stream address, the resident engine RAM that executes it, and the hardware writes produced by that execution.

## Address spaces: do not mix them

Several address classes appear together on the Sound Browser. They have different meanings.

| Address range/example | Space | Meaning |
| --- | --- | --- |
| `$8000`, `$8003`, `$8006`, `$8437` | ROM code | resident WoW Z80 routines |
| `$887B`, `$8928`, `$8A81` | ROM data | interpreted WoW sound-bytecode streams |
| `$D240-$D2BD` | work RAM | sound requests, modulators, engine records |
| `$D400-$DFFF` | work RAM | active Lab module application |
| `$10-$18`, `$50-$58` | Z80 I/O | Astrocade custom I/O IC sound ports |

A hexadecimal value alone is therefore not enough to identify its role. The Browser labels and documentation keep the address space attached to the value.

### Example: player fire

```text
PLAYER FIRE gameplay path
        |
        v
R2.B1
$D241 bit 1
        |
        v
$8003 request dispatch
        |
        v
secondary stream $887B
        |
        v
secondary engine record $D2AC-$D2BD
modulators             $D282-$D2AB
        |
        v
hardware ports $50-$57
```

The screen therefore reports:

```text
R2B1  ----  887B  PLAYER FIRE
```

`887B` means “secondary ROM sound-stream entry `$887B`,” not “player-fire Z80 routine.”

### Example: player death

```text
PLAYER DEATH gameplay path
        |
        v
R2.B0
$D241 bit 0
        |
        v
$8003 request dispatch
        |
        v
secondary stream $8928, priority 1
        |
        v
secondary engine record $D2AC-$D2BD
        |
        v
$8437 decodes sound bytecode beginning at $8928
        |
        v
$8000/$80E6 services resulting engine state
        |
        v
Astrocade secondary sound IC
```

The Sound Map carries the static producer-to-request-to-stream correlations used for event naming.

## Resident WoW sound RAM

The Browser observes and drives the real WoW sound structures:

| RAM | Purpose |
| --- | --- |
| `$D240` | request bank 1 |
| `$D241` | request bank 2 |
| `$D242` | request bank 3 |
| `$D243` | request bank 4 |
| `$D244` | sound-service enable |
| `$D246-$D26F` | primary modulator area: six 7-byte slots |
| `$D270-$D281` | primary 18-byte sound-engine record |
| `$D282-$D2AB` | secondary modulator area: six 7-byte slots |
| `$D2AC-$D2BD` | secondary 18-byte sound-engine record |

These are ordinary Z80 work-RAM addresses. They are not memory-mapped sound registers.

The engine records contain the active ROM stream pointer, priority, eight-byte sound-register image, coupling state, wait counter, service state, and stream-ready state. The periodic resident sound service transfers the register image to the Astrocade I/O IC through port `$18` or `$58`.

The detailed engine layout and modulator semantics are maintained in [`SOUND_MAP.md`](../../../../docs/SOUND_MAP.md).

## Sound Browser module RAM

The Sound Browser owns the Lab application workspace while active:

```text
$D380-$D3BF   permanent Lab ABI               preserved
$D3C0-$D3FD   permanent Lab IM2 kernel        preserved
$D3FE-$D3FF   permanent Lab IM2 vector        preserved

$D400-$D720   Sound Browser native controller
$D740-$D83F   generated native draw-code area
$D840-$D855   browser state and mailboxes
$D900-$DAFF   dynamic UI text/data, bounded below $DB00
$DB00-$DB2F   24-entry native request table
$DFE0         browser stack top
```

The request table contains two bytes per catalog entry:

```text
request-bank offset from $D240
request bit mask
```

For `R2.B1`, the pair is:

```text
$01,$02
```

which resolves to `$D241` with mask `$02`.

### Browser state

The native controller uses `$D840-$D855` for selection, active entry, Play All state, timers, UI synchronization, console mailbox commands, play/stop sequence numbers, stop reason, batch result, and request-dispatch cadence.

Important anchors are:

| Address | Purpose |
| --- | --- |
| `$D840` | selected catalog index |
| `$D841` | active catalog index; `$FF` = none |
| `$D842` | mode: manual / Play All |
| `$D845` | next Play All entry |
| `$D846` | completed Play All count |
| `$D847` | active-sound timer |
| `$D848` | inter-sound gap timer |
| `$D84C-$D84D` | Lua-to-native command mailbox and argument |
| `$D84E` | play sequence |
| `$D84F` | stop sequence |
| `$D850` | stop reason |
| `$D852` | Play All result |
| `$D853-$D854` | dispatcher countdown and period |
| `$D855` | play-begin sequence |

The state block is module-local. The WoW sound-engine RAM at `$D240-$D2BD` is resident game state. Keeping those regions separate is essential when interpreting traces or debugger captures.

## Native controller

The module installs its controller at `$D400` and hands foreground execution to it with stack top `$DFE0`.

The controller:

- polls cabinet controls;
- services the module console mailbox;
- resets sound engines through WoW `$8006` when playback requires a clean start;
- posts the selected bit to `$D240-$D243`;
- calls WoW `$8003` to dispatch requests;
- runs manual stop/replacement logic;
- runs Play All sequencing;
- determines native engine idle state from WoW engine RAM;
- executes the generated native UI program when needed.

The permanent Lab IM2 kernel remains at `$D3C0` and calls WoW `$8000` every interrupt. That resident interrupt service advances the installed sound streams and updates the sound hardware.

The default foreground request-dispatch period is four native ticks. `wsdispatch("fast")` changes it to one tick for diagnostic work; `wsdispatch("wow")` restores the four-tick cadence.

## Catalog

The current catalog is:

| Request | Pri | PSTR | SSTR | Event |
| --- | ---: | ---: | ---: | --- |
| `R1.B0` | 0 | `$89BE` | `$89E5` | Warlord dungeon cue |
| `R1.B1` | 0 | `$89A0` | `$89AF` | Global event 1 |
| `R1.B2` | 0 | `$8741` | `$8772` | Radar cue |
| `R1.B3` | 0 | `$8981` | — | Attract event 3 |
| `R1.B4` | 0 | `$8A0C` | `$8A27` | Round start cue |
| `R1.B5` | 0 | `$8971` | — | Coin up |
| `R2.B0` | 1 | — | `$8928` | Player death |
| `R2.B1` | 0 | — | `$887B` | Player fire |
| `R2.B2` | 1 | — | `$87EA` | Worluk proximity |
| `R2.B3` | 0 | — | `$883B` | Thorwor visible |
| `R2.B4` | 0 | — | `$8825` | Garwor visible |
| `R2.B6` | 0 | — | `$8988` | Player input state |
| `R2.B7` | 1 | `$8741` | — | Dungeon intro primary |
| `R3.B0` | 1 | `$8AA1` | `$8ADD` | Worluk death |
| `R3.B1` | 0 | — | `$890E` | Monster death |
| `R3.B2` | 0 | — | `$8851` | Monster fire |
| `R3.B3` | 0 | — | `$8851` | Monster fire alt |
| `R3.B4` | 0 | — | `$8A42` | Magic door transit |
| `R3.B5` | 1 | `$8A81` | `$8A6C` | Worluk escape |
| `R3.B7` | 1 | `$877B` | — | Worluk entry |
| `R4.B0` | 2 | `$88E2` | `$8905` | Wizard death |
| `R4.B1` | 1 | `$8AF6` | `$8B1F` | Wizard appear |
| `R4.B2` | 1 | — | `$8AF3` | Wizard fire |
| `R4.B3` | 1 | `$8B2E` | `$8B5D` | Worluk escaped |

Event names follow static gameplay producers where the source supports the identification. Generic/contextual names remain where the exact semantic trigger is intentionally not overstated.

## Play All

Play All executes the 24 catalog requests in order.

- Initial gap: one native tick
- Inter-sound gap: **45 native ticks**, about 0.75 seconds
- Natural completion: advance when both resident sound engines reach `IDLE`
- Active-sound limit: **240 native ticks**, about 4 seconds
- Fire: stop the current sound and continue the run
- 2P Start: stop the complete run

The four-second limit provides deterministic progress for sustained or latched requests. It is not a claim that the underlying ROM stream is infinite.

Native stop reasons are recorded as:

```text
IDLE
FIRE STOP
NEW PLAY
PLAY ALL LIMIT
PLAY ALL STOP
```

## Console commands

The Sound Browser installs these commands only while the module is active:

```text
wsplay(n|R#B#)   play a request through the native mailbox
wsstop()         stop/reset the active sound
wsall()          toggle native Play All
wslist()         list the 24-request catalog
wsinfo()         show selected/native state and capture status
wsstate()        show resident primary and secondary engine state
wsdispatch(m)    select "wow" four-tick or "fast" one-tick dispatch cadence
wssteps([m])     toggle detailed step logging; compact trace is used when off
wscapstatus()    show capture counters and active segment
wscaplist()      list completed and active captures
wscapsave(p)     save versioned JSON; path is optional
wscapclear()     clear completed captures
wshelp()         show the command list
```

The administrative play/stop/Play All commands write the module mailbox at `$D84C-$D84D`. The Z80 controller consumes that mailbox and performs the same native operations used by cabinet controls.

Returning to the Lab removes these commands and restores any globals that existed before module entry.

## Compact trace

Every played sound produces a compact transition trace by default.

Example:

```text
[WOW SOUND] PLAY R2B1 request=$D241 mask=$02 pri=0 P---- S887B  PLAYER FIRE
[WOW SOUND] TRACE R2B1 START entry=P---- S887B
[WOW SOUND] TRACE R2B1 P IDLE ----  S MOD2 $88A4
[WOW SOUND] TRACE R2B1 P IDLE ----  S MOD1 $88A4
[WOW SOUND] TRACE R2B1 P IDLE ----  S MOD1 $88B2
[WOW SOUND] TRACE R2B1 P IDLE ----  S IDLE ----
[WOW SOUND] TRACE R2B1 END IDLE
```

`START` reports the catalog stream entry point. Later pointers are the saved next-command addresses observed in the resident engine record.

The compact trace reports state transitions rather than every counter decrement, which keeps normal console output readable.

## Detailed step trace

`wssteps()` enables the detailed engine-step table. The detailed mode records and prints frame/time, engine phase, saved pointers, waits, modulator counts, state changes, and observed register activity.

Use it when a particular ROM stream needs instruction-by-instruction sound-engine analysis. Disable it for catalog sweeps and normal playback.

## Read-only capture

The module automatically captures native sound execution while requests play.

Capture taps observe:

- Astrocade primary and secondary sound I/O writes;
- WoW primary and secondary engine-record writes;
- engine snapshots and state transitions;
- request identity and installed stream addresses;
- decoded sound-stream command programs;
- frame and emulated-time timing;
- native completion/stop reason.

The capture path does not post requests, alter engine state, synthesize audio, or rewrite sound-stream bytes.

Retention is bounded per capture:

| Data | Maximum retained |
| --- | ---: |
| raw bus events | 24,000 |
| engine-write events | 48,000 |
| engine samples | 6,000 |
| detailed steps | 6,000 |
| decoded stream commands | 4,096 |
| visits to one decoded stream address | 8 |

Dropped/truncated counts are retained in the exported record so a bounded capture is not mistaken for a complete unbounded trace.

## JSON capture files

`wscapsave()` writes a `wow-sound-capture` format document. With no path, the filename is timestamped:

```text
wow_sound_capture_YYYYMMDD-HHMMSS.json
```

Each file identifies:

- format and format version;
- Sound Browser producer version;
- ROM/game name;
- Astrocade clock and screen timing when available;
- primary/secondary register model;
- one or more captured sound segments.

Each segment includes the catalog request, start/end timing, completion reason, event counts, decoded stream programs, raw I/O events, engine writes, engine samples, and detailed steps retained for that sound.

The module uses MAME's JSON encoder when available and contains a Lua JSON encoder fallback so capture export does not depend on a global MAME JSON binding.

## Module lifecycle

On `start` the module:

```text
initializes module-local Lua state
        |
        v
builds native controller
        |
        v
writes controller at $D400
writes request table at $DB00
        |
        v
clears visible bitmap
        |
        v
installs read-only capture taps
installs ws* console commands
        |
        v
handoff PC=$D400, SP=$DFE0
```

While active, `update` observes native play/stop sequences, services captures, and refreshes dynamic UI data.

On Lab return, `stop` finalizes any open capture with the `LAB RETURN` reason, removes capture taps, and restores console globals. The supervisor then reinstalls the native Lab menu. The menu entry initializes resident sound/speech services into a defined idle state before normal menu operation resumes.

The permanent Lab ABI, IM2 kernel, and vector are never part of the Sound Browser application image and therefore remain intact for the complete module session.

## Reverse-engineering workflow

The most useful correlation for a sound is:

```text
static gameplay producer
        |
        v
request selector R#.B#
        |
        v
PSTR/SSTR ROM sound bytecode
        |
        v
resident engine RAM behavior
        |
        v
Astrocade I/O writes
```

A practical workflow is:

1. Identify or play a request in the browser.
2. Record the `R#.B#`, `PSTR`, `SSTR`, priority, and event label.
3. Follow the request producer and decoder path in `wow_disassembly.asm`.
4. Use `wsstate()` or compact trace to inspect resident engine progression.
5. Enable `wssteps()` when detailed transitions are required.
6. Save a JSON capture when bus-level and engine-level evidence should be retained.
7. Cross-check structural findings against [`SOUND_MAP.md`](../../../../docs/SOUND_MAP.md).

This keeps gameplay semantics, request dispatch, interpreted ROM stream data, resident RAM state, and hardware output visible as separate but connected layers.
