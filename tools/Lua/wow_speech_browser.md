# Wizard of Wor native speech browser

`wow_speech_browser_20260815-1819.lua` boots Wizard of Wor normally and then
installs a 1,020-byte Z80 foreground controller in work RAM. The screen remains
an in-game WoW display rendered through the resident `printstr` and `CHRTBL`
code. No MAME overlay or ROM patch is used.

This version removes the former Lua-driven controller. Lua does not poll the
joysticks, move the selection, build executable draw programs, initialize a
fragment's phoneme pointer, manufacture a return address, or redirect the CPU
for each request.

## Ownership

| Function | Owner |
| --- | --- |
| Validate WoW/X11 ROM signatures | Lua |
| Build descriptions and seven-row page text | Lua |
| Inject and byte-verify the assembled payload | Lua |
| WAV recording and read-only console trace | Lua |
| Exit MAME after the native 1P request | Lua |
| IM 2 vector and once-per-frame controller | Z80 |
| P1/P2 joystick and Start-switch polling | Z80 |
| Pane, selection, viewport and Play All state | Z80 |
| Native `printstr` calls and selector rendering | Z80 |
| Phrase request through `$8009 -> $827D` | Z80 + resident WoW |
| Fragment queue insertion and loading | Z80 + resident WoW |
| SC-01 A/R polling, command decode and strobe | Resident WoW |
| Periodic sound/speech service through `$8000 -> $84F2` | Z80 + resident WoW |

Lua sets `PC=$D400` once at takeover. It does not modify `PC`, `SP`, `HALT`,
`IFF1` or `IFF2` again.

## Native speech paths

Phrase playback loads the selected logical phrase ID into `A` and calls the
resident `$8009` entry. WoW selects the English or X11 phrase table, expands the
phrase into fragment pointers and appends them to its circular queue.

Fragment playback writes one selected ROM record address into the queue at
`$D2BE`, advances the queue write pointer and sets `Speech_Active`. It does not
write `Speech_Phoneme_Pointer` (`$D2CE`) or
`Speech_Phonemes_Remaining` (`$D2D0`). The next resident service call loads the
record through WoW's `Service_Speech_Queue` path at `$81F8` and its
`Speech_Load_Next_Queued_Fragment` branch at `$8201`.

The browser-owned IM 2 handler calls `$8000` once per frame. WoW's resident
service checks the SC-01 A/R signal on P1 port bit 7, differentially decodes
speech command bit 7, advances the ROM pointer and issues the hardware command
strobe. The Lua code never writes the Votrax port.

## MAME SC-01 defect; no browser shim

The original English ROM is never patched. Fragment `$3C` at `$9270` contains
the valid words “of my” as the encoded SC-01 transition `V -> M` at
`$9285 -> $9286`. MAME 0.289 can wedge its Votrax audio state at that boundary:
the filter output runs away, later speech can become inaudible, and shutdown can
leave a buzz. The SC-01 A/R timer is independent of this audio-path failure.

Source-level investigation identified the emulator defect in
`votrax_sc01_device::build_injection_filter`: its F2 noise-path denominator
subtracts `c2t`, making the modeled filter unstable for 91 of 512 possible
F2/F2Q states. The `M` target state has a pole magnitude of `1.2346078`. The
candidate MAME fix changes that subtraction to addition; its full state sweep
has no unstable poles and the ROM-driven `$9270` regression completes normally.
A full rebuilt-MAME listening test is still required.

The experimental 3.0.1 RAM shadow did not fix the failure in testing and has
been removed completely. This build inserts no `PA0`, contains no `$9270`
shadow record, and performs no phrase-queue pointer redirection. Standalone and
phrase playback both queue the original ROM address and preserve the original
`V -> M` command sequence. On an unpatched MAME 0.289 build, the emulator defect
is therefore expected to remain visible.

There is also a two-second native progress watchdog. If MAME holds A/R low and
the resident phoneme pointer does not advance, the controller deliberately
invalidates the queue write pointer and calls WoW's `$8006` reset/validation
entry. Resident `Validate_Speech_Queue_State` empties the queue and sends STOP.
The browser increments `$D3A8`, and Lua reports a read-only
`NATIVE STALL RECOVERY` diagnostic. It does not repair or replace any ROM byte.

Both 1P Start and `wexit()` now take a native exit path: resident `$8006` sends
STOP, the controller waits six frames for the emulated device to settle, and
only then asks Lua to exit MAME. This prevents the stuck-speech exit buzz.

## Work RAM map

| Range | Use |
| --- | --- |
| `$D050-$D077` | 40-character header supplied by Lua |
| `$D078-$D18F` | Seven 40-character catalog rows |
| `$D190-$D207` | Three 40-character control rows |
| `$D208-$D21C` | Seven native `{id,address}` records |
| `$D380-$D3A8` | Fixed Lua/Z80 mailbox, input-repeat, exit and watchdog state |
| `$D3CA-$D3CB` | Browser IM 2 vector pointer |
| `$D400-$D7FB` | Assembled Z80 controller, 1,020 bytes |
| `$7FC0-$7FFF` | WoW's non-visible video-RAM stack margin; `SP=$8000` |

WoW's resident sound/speech state at `$D240-$D37F` remains available to the
high-ROM service. `$D350` is set to basic-dungeon class so phrase IDs `$09` and
`$37` are not changed to their Worlord substitutions while browsing.

## Run

From the repository root:

```sh
mame -console -window -autoboot_script tools/Lua/wow_speech_browser.lua wow
mame -console -window -autoboot_script tools/Lua/wow_speech_browser.lua wowg
```

Use `-rompath roms/` when testing a locally built archive. Use the appropriate
MAME-compatible driver/archive for an active German or Klingon X11 image and
select the Foreign language DIP.

## Controls

- Up / Down: move through the current list
- Left / Right: toggle fragments and phrases; every new press toggles
- Fire: play the selected entry
- 1P Start: request MAME exit through the Lua shell
- 2P Start: start Play All; press again to stop after the current entry

The initial page has no selection. Down selects the first entry; Up selects the
last entry. A held vertical direction repeats after 15 frames and then every
four frames. Fragment pages retain physical ROM-address order.

## Console tools

```text
wwav()          toggle WAV capture
wwav(true)      enable WAV capture
wwav(false)     disable WAV capture
wtrace()        toggle read-only detailed trace
wall()          post a native Play All command
wstop()         post a native stop-after-current command
wexit()         exit MAME
whelp()         show the command list
```

`wall()` and `wstop()` write a command byte. The Z80 controller performs the
same state transition used by 2P Start. WAV capture adds native pre-roll so Lua
can close the preceding file after its post-roll and start the next file before
speech begins.

## Source and byte identity

`wow_speech_browser_native_20260815-1819.asm` is the injected program. Rename it
to the repository's stable `wow_speech_browser_native.asm` path, then assemble it
with zmac:

```sh
zmac --zmac --oo cim,lst wow_speech_browser_native.asm
```

The resulting CIM is 1,020 bytes and has SHA-256:

```text
1068a34a6dd89548f3cb45715811ece5d2215be1cdfe2c941be1ccb535fe8481
```

The Lua loader parses its embedded hexadecimal payload, verifies its 1,020-byte
length and FNV-1a value `9D86CCDE`, writes it to `$D400`, and reads every byte
back before the one-time CPU handoff.

## First test captures

Please retain these console/screen captures from the first MAME run:

1. Startup through `native takeover active`, including bank and catalog counts.
2. Initial fragments page before a selection, then after one Down press.
3. One English fragment and one English phrase, including `PLAY`, `PHONEMES`
   and `END` lines.
4. Press Right at least three times, then Left at least three times; every press
   must toggle the pane. Scroll across a seven-row boundary.
5. Start Play All with 2P, allow three entries, then press 2P again. Capture the
   footer change and the final current entry.
6. Repeat one fragment and phrase with German X11 and Klingon X11.
7. After rebuilding MAME with the Votrax fix, play English fragment `$3C` /
   address `$9270`; confirm the trace contains the original adjacent `V M`
   phonemes, no shim message appears, the line finishes, later entries still
   play, and exit is silent. Also test phrase `$3C`, which contains the same
   fragment.
8. Run `wtrace(true)` for one fragment if any speech stalls or buzzes. A forced
   recovery prints `NATIVE STALL RECOVERY` and must leave later speech usable.

For a byte comparison in the MAME debugger, save `$D400-$D7FB` (length `$03FC`)
after takeover and compare it with
`wow_speech_browser_native_20260815-1819.cim`. Also capture
`$D380-$D3A8` if the page, controls, Play All, or watchdog state stops advancing.
