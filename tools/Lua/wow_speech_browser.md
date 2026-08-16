# Wizard of Wor native speech browser

`wow_speech_browser.lua` boots *Wizard of Wor*, validates the active game and X11 program ROMs, and installs a Z80 foreground controller at `$D400`. The browser remains an in-game WoW display rendered through the resident `printstr` and `CHRTBL` code. It uses the original phrase tables, fragment records, circular speech queue, SC-01 command decoder, and sound/speech service. No ROM byte, speech record, phrase pointer, or MAME overlay is substituted.

## Architecture and ownership

Lua owns the high-level shell and data presentation. Z80 owns the live browser and playback path.

| Function | Owner |
| --- | --- |
| Validate WoW and X11 ROM signatures | Lua |
| Build descriptions and seven-row page text | Lua |
| Inject and byte-verify the assembled controller | Lua |
| WAV recording and read-only console trace | Lua |
| Close MAME after a native exit request | Lua |
| IM 2 vector and once-per-frame controller | Z80 |
| P1/P2 joystick and Start-switch polling | Z80 |
| Pane, selection, viewport, key repeat, and Play All state | Z80 |
| Resident `printstr` calls and selector rendering | Z80 |
| Phrase request through `$8009 -> $827D` | Z80 + resident WoW |
| Fragment queue insertion and loading | Z80 + resident WoW |
| SC-01 A/R polling, command decode, and strobe | Resident WoW |
| Periodic sound/speech service through `$8000 -> $84F2` | Z80 + resident WoW |

After a two-second boot delay, Lua clears a reported HALT state when necessary, sets `SP=$8000`, and sets `PC=$D400` exactly once. It does not mutate CPU registers, interrupt state, `PC`, `SP`, or `HALT` after that handoff.

Lua supplies complete 40-character native-font rows through a shared page buffer. The Z80 requests a page by advancing a sequence byte, waits for Lua's matching acknowledgement, and performs the resident draw calls. Navigation, repeated input, playback, and Play All continue entirely in the frame controller.

## Native speech paths

### Phrase playback

The controller loads the selected logical phrase ID into `A` and calls WoW's `$8009` entry. `Queue_Speech_Request` at `$827D` selects the resident English or X11 phrase table, expands the phrase into language-local fragment pointers, and appends them to the resident circular queue.

### Fragment playback

The controller appends the selected fragment record address to the queue at `$D2BE-$D2CD`, advances the resident write pointer, and sets `Speech_Active`. It does not prime `Speech_Phoneme_Pointer` (`$D2CE`) or `Speech_Phonemes_Remaining` (`$D2D0`). WoW's next service call loads the record through `Service_Speech_Queue` at `$81F8` and `Speech_Load_Next_Queued_Fragment` at `$8201`.

The browser-owned IM 2 handler calls `$8000` once per frame. WoW polls SC-01 A/R on P1 port bit 7, differentially decodes command bit 7, preserves command bit 6, advances the ROM pointer, and issues the hardware command strobe. Lua never writes the Votrax port.

### Watchdog and exit

The Z80 watchdog expects the resident phoneme pointer to advance within two seconds while speech is active. A stalled pointer invokes WoW's `$8006` reset/validation entry with an intentionally invalid queue write pointer. The resident validator empties the queue and sends SC-01 STOP. The controller increments `$D3A8`; Lua reports the event as a read-only `NATIVE STALL RECOVERY` diagnostic.

Both 1P Start and `wexit()` follow the native exit path. The controller stops sound through `$8006`, waits six frames for STOP to settle, and posts the exit request consumed by Lua.

## MAME SC-01 accuracy requirement

English fragment `$3C` at `$9270` contains the valid encoded `V -> M` transition at `$9286-$9287`. In MAME 0.289, `votrax_sc01_device::build_injection_filter` constructs the F2 noise-injection denominator with a subtraction:

```cpp
double k1 = m_cclock * (c1b * c3 / c2t - c2t);
```

The two capacitance contributions are additive:

```cpp
double k1 = m_cclock * (c1b * c3 / c2t + c2t);
```

The subtractive realization is unstable for 91 of 512 SC-01 internal ROM states and can make `$9270` run away, silence later speech, and leave a buzz at exit. The additive realization has 0 unstable states out of 512. Accurate complete playback therefore requires a MAME build containing the additive coefficient.

The browser always queues the original `$9270` record and preserves its original command sequence. The watchdog is a bounded recovery path for an unresponsive device; it is not a speech-data patch and does not replace the emulator correction.

## Work RAM map

| Range | Use |
| --- | --- |
| `$D050-$D077` | 40-character header supplied by Lua |
| `$D078-$D18F` | Seven 40-character catalog rows |
| `$D190-$D207` | Three 40-character control rows |
| `$D208-$D21C` | Seven native `{id,address}` records |
| `$D240-$D37F` | Resident sound/speech and game state retained for high-ROM services |
| `$D380-$D3A8` | Fixed Lua/Z80 mailbox, input-repeat, exit, and watchdog state |
| `$D3CA-$D3CB` | Browser IM 2 vector pointer |
| `$D400-$D7FB` | Assembled Z80 controller, 1,020 bytes |
| `$7FC0-$7FFF` | Non-visible video-RAM stack margin below `SP=$8000` |

`Dungeon_Class` at `$D350` is set to the basic-dungeon value so browser phrase playback retains literal fragment IDs `$09` and `$37` instead of applying the resident Worlord substitutions.

## Run

From the repository root:

```sh
mame -console -window -autoboot_script tools/Lua/wow_speech_browser.lua wow
mame -console -window -autoboot_script tools/Lua/wow_speech_browser.lua wowg
```

Use `-rompath roms/` for a local ROM directory. For German or Klingon X11 program ROMs, use the corresponding MAME-compatible driver/archive and select the Foreign language DIP.

## Controls

- Up / Down: move through the current list, with wraparound
- Left / Right: toggle fragments and phrases on every new press
- Fire: play the selected entry
- 1P Start: stop sound and request MAME exit
- 2P Start: start Play All; press again to stop after the current entry

The initial page has no selection. Down selects the first entry; Up selects the last. A held vertical direction repeats after 15 frames and then every four frames. Fragment pages retain physical ROM-address order. Phrase pages retain logical phrase-ID order.

## Console tools

```text
wwav()          toggle WAV capture
wwav(true)      enable WAV capture
wwav(false)     disable WAV capture
wtrace()        toggle read-only detailed trace
wall()          post a native Play All command
wstop()         post a native stop-after-current command
wexit()         post a native exit command
whelp()         show the command list
```

`wall()`, `wstop()`, and `wexit()` write one command byte to the shared mailbox. The Z80 performs the same state transitions used by the cabinet controls. WAV capture uses native event pre-roll so Lua can close the preceding file after post-roll and open the next file before speech begins.

## Source and byte identity

`wow_speech_browser.asm` is the injected controller source. Assemble it with zmac 1.3-compatible syntax:

```sh
zmac --zmac --oo cim,lst wow_speech_browser.asm
```

The resulting CIM is 1,020 bytes with SHA-256:

```text
1068a34a6dd89548f3cb45715811ece5d2215be1cdfe2c941be1ccb535fe8481
```

The Lua loader parses the embedded hexadecimal payload, verifies its 1,020-byte length and FNV-1a value `9D86CCDE`, writes it to `$D400`, and reads every byte back before the one-time CPU handoff. The embedded payload must remain byte-identical to the assembled CIM.

## Validated behavior

Validation with the additive MAME Votrax coefficient produced these results:

| Configuration | Result |
| --- | --- |
| Resident English fragments | 79 of 79 complete; clean subsequent playback |
| Resident English phrases | 80 of 80 complete |
| English `$9270` / phrase `$3C` | Original adjacent `V M` commands complete normally |
| Browser navigation | Repeated Left/Right toggles; Up/Down wraparound and paging pass |
| Play All | Native start and stop-after-current pass |
| Exit | SC-01 STOP settles; no residual buzz |
| `wowg` baseline | Pass |
| Project German and Klingon X11 program ROMs | Fragment and phrase playback pass |

Speech was clean and crisp across the completed passes, with no recurring crackle observed.

## Diagnostics

Enable `wtrace(true)` to log phrase expansion, fragment addresses, encoded phonemes, completion timing, and watchdog recovery. For native-state diagnosis, capture `$D380-$D3A8`. For payload identity, save `$D400-$D7FB` after takeover and compare all `$03FC` bytes with the assembled CIM.

Future controller additions should preserve the ownership boundary: Lua may provide high-level catalog content and host services, while input, state transitions, playback, and resident-service interaction remain native Z80 behavior.
