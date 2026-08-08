<!-- README.md -->
# Wizard of Wor Klingon X11

This revision resets the Klingon experiment to a deliberately conservative runtime architecture.

The Klingon fragment namespace now matches the resident English fragment namespace exactly: 79 fragment IDs `$00-$4E`. The X11 ROM uses the exact resident English 80-entry phrase table. This keeps laughter, Worlord substitution, fragment counts, and phrase boundaries in known-good locations while the Klingon SC-01 pronunciation is tuned.

## Votrax JSON versus X11 ROM

`votrax_library_wowk.json` is for direct player audition. Every record ends with `$3F STOP` so selecting any library item has a deterministic playback end.

The X11 ROM does **not** store that terminal STOP. Wizard of Wor already sends STOP when the speech queue becomes empty. The ROM record therefore stores only the direct fragment phoneme bytes and its leading length.

## Runtime structure

- X11 header: `$C000-$C00C`
- 23 localized text records: `$C00D-$C1D0`
- alignment byte: `$C1D1`
- alternate font area: `$C1D2-$C1FF`
- Klingon speech records: `$C200-$C8CF`
- explicit erased fill through `$CD8C`
- 84 fragment-pointer slots: `$CD8D-$CE34`
- 80 phrase records: `$CE35-$CF1A`
- erased alignment: `$CF1B-$CF1C`
- checksum compensation: `$CF1D`
- preserved compatibility tail: `$CFEB-$CFFF`

Slots `$4F-$53` are null in this compatibility build.

## Rank substitution

The resident code still performs:

```text
$09 -> $40
$37 -> $41
```

when `Dungeon_Class != 0`. Those four Klingon slots correspond to `SuvwI'` and `SuvwI' joH`.

## zmac v1.3

After the initial `ORG $C000`, the source contains no further `ORG` gaps. Every unused byte is emitted explicitly as `$FF`. This avoids the assembler-fill mismatch that caused the previous source to assemble to a nonzero checksum even though the separately generated reference binary had checksum zero.

## Reference image

- size: 4096 bytes
- additive checksum: `$00`
- checksum compensation: `$BC`
- CRC32: `7c9e5c39`
