# Wizard of Wor Speech Browser

`wow_speech_browser.lua` is a MAME Lua utility for browsing, testing and capturing WAV files.

WoW boots normally, then the Lua browser Insert Z80 code into work RAM to take over the foreground while leaving the game's interrupt-driven sound and SC-01 speech service active. 

The browser uses WoW's native character renderer and supports resident English speech or an active X11 language ROM.

## Run

From the repository root:

```sh
mame -console -window -autoboot_script tools/Lua/wow_speech_browser.lua wow

mame -console -window -autoboot_script tools/Lua/wow_speech_browser.lua wowg

mame -console -window -autoboot_script tools/Lua/wow_speech_browser.lua -rompath roms/ wow

mame -console -window -autoboot_script tools/Lua/wow_speech_browser.lua -rompath roms/ wowg
```

Use `wow` for resident English. Use the appropriate MAME-compatible archive/driver for an X11 language ROM (such as wowg for German)

Use -rompath to use local built ROMs else mame will use its versions.

## Game Screen Controls

- **Up / Down** — move through the current list
- **Left / Right** — switch between fragments and phrases
- **Fire** — play the selected entry
- **1P Start** — exit MAME
- **2P Start** — play all entries in the current view; press again to stop after the current item

The list shows each entry's ROM address and description. Fragment lists are ordered by physical ROM address.

## Lua Console Commands

```text
wwav()         Toggle WAV capture for played entries
wwav(true)     Enable WAV capture
wwav(false)    Disable WAV capture

wall()         Play all entries in the current view
wstop()        Stop play-all after the current item

wtrace()       Toggle detailed speech tracing
wtrace(true)   Enable detailed tracing
wtrace(false)  Disable detailed tracing

wexit()        Exit MAME
whelp()        Show the command list
```

Console logging reports the selected entry, ROM address, decoded SC-01 phonemes, and completion status.

Fragment example:

```text
[WOW SPEECH] PLAY FRAGMENT id=$00 address=$8B66 text="Kill Worluk for double score"
[WOW SPEECH] PHONEMES PA0 K I I3 L PA0 W O O1 R L UH K PA0 F O1 R D UH B UH3 L S K O O1 R PA1 PA0
[WOW SPEECH] END FRAGMENT id=$00 address=$8B66 elapsed=3.264s phonemes=29
```

Phrase example:

```text
[WOW SPEECH] PLAY PHRASE id=$01 address=$9516 text="Find me + The Wizard of Wor"
[WOW SPEECH]   FRAGMENT 1/2 id=$0B address=$8E8B text="Find me"
[WOW SPEECH]     PHONEMES F AH1 I3 Y N D M E E1 PA1
[WOW SPEECH]   FRAGMENT 2/2 id=$04 address=$8BDF text="The Wizard of Wor"
[WOW SPEECH]     PHONEMES PA1 THV UH W I Z ER D UH V PA0 W O O1 R R PA1
[WOW SPEECH] END PHRASE id=$01 address=$9516 elapsed=3.297s
```

`id` is the logical WoW speech ID. `address` is the ROM address of the fragment or phrase record. Phrase logging expands the phrase into its component fragments in playback order and shows each fragment's ID, ROM address, text, and decoded phoneme stream.

The `PHONEMES` line uses SC-01 phoneme mnemonics decoded from the ROM data. Names such as `AH1`, `I3`, `O1`, and `THV` are SC-01 speech sounds; `PA0` and `PA1` are pause phonemes. This makes the console useful for comparing what is stored in ROM with what is heard during playback.

Detailed tracing adds raw speech bytes, SC-01 command decoding, speech state, and per-phoneme progress.

## WAV capture

When WAV capture is enabled, each played fragment or phrase is recorded separately. The console reports the completed filename with `WAV saved:`.

Example filenames:

```text
wow_klingon_fragment_C26E.wav
wow_klingon_phrase_CE37.wav
```

`wall()` follows the current `wwav()` setting. With WAV capture disabled it only plays the list; with WAV capture enabled it records each entry separately.

## Notes

- Speech is played directly from the loaded ROM; the browser does not patch or rewrite ROM data.
- Foreground takeover runs from work RAM at `$D400`; native UI code is staged at `$D420`.
- The screen is rendered through WoW's `L03B5 printstr` path, resident `CHRTBL`, and Astrocade Magic RAM. No MAME overlay is used.
- Browser UI colors use the game's native blue, yellow, and red palette entries.