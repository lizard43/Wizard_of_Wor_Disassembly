<!-- README.md -->
# Wizard of Wor Klingon X11 language ROM

This directory contains an experimental Klingon (`tlhIngan Hol`) language ROM for the Wizard of Wor X11 socket. It uses the same data-driven interface documented by the preserved German X11 ROM: 23 localized display strings, language-local speech fragments, an 80-entry phrase table, coinage data, an alternate-font pointer, and the ROM diagnostic checksum.

This is a first playable engineering pass, not a claim of a professionally vetted Klingon literary translation. The ROM is designed so the text, phrase translations, and individual SC-01 pronunciations can be refined without changing the main Wizard of Wor program.

## X11 interface

| Address | Field | Purpose |
| --- | --- | --- |
| `$C000` | `X11_Speech_Fragment_Table_Ptr` | Pointer to `Klingon_Speech_Fragment_Pointers`. |
| `$C002` | `X11_Speech_Phrase_Table_Ptr` | Pointer to the 80-entry `Klingon_Speech_Phrase_Table`. |
| `$C004` | `X11_Coinage_Value_Table` | Six foreign-mode coinage values, retained from the German X11 ABI. |
| `$C00A` | `X11_ROM_Checksum_Expected` | Expected modulo-256 diagnostic checksum (`$00`). |
| `$C00B` | `X11_Alternate_Font_Ptr` | Pointer to reserved alternate-font storage. |
| `$C00D` | `Klingon_Localized_Text_Table` | Base of the 23 localized display strings. |

## Display text

The arcade text format cannot directly represent normal Klingon orthography. Record bytes below `$30` are interpreted as string-length delimiters, which prevents using the ASCII apostrophe, and the resident display font is effectively uppercase. The source therefore documents canonical mixed-case Klingon in comments while emitting an uppercase, apostrophe-free display transliteration.

Examples:

- `Huch yIlan` -> `HUCH@YILAN`
- `mIvwa' nIv` -> `MIVWA@NIV`
- `SuvwI' joH bIghHa'` -> `SUVWI@JOH@BIGHHA`

`@` is the display-space convention already used by the German ROM.

## Speech architecture

The main game continues to request the same 80 phrase IDs `$00-$4F`. The Klingon phrase table maps those IDs into a language-specific fragment vocabulary. Unlike English and German, this ROM is free to choose its own fragment boundaries.

Four fragment IDs are ABI-significant and are deliberately preserved:

| Fragment | Klingon | Runtime role |
| ---: | --- | --- |
| `$09` | `SuvwI'` | Worrior/rank token |
| `$37` | `SuvwI'` | Padded Worrior/rank token |
| `$40` | `SuvwI' joH` | Worlord token |
| `$41` | `SuvwI' joH` | Padded Worlord token |

When `Dungeon_Class != 0`, the resident game code substitutes `$09 -> $40` and `$37 -> $41` before language-specific pointer lookup. Phrase records that address the player by rank use `$37`, so the existing game logic changes the spoken Klingon rank without any main-ROM modification.

## SC-01 approximation

The SC-01 does not contain several Klingon consonants, so the ROM uses deterministic approximations. This table is the starting point for listening/tuning:

| Klingon | SC-01 approximation | Note |
| --- | --- | --- |
| `a` | `AH1` | open Klingon `a` |
| `e` | `EH` | short/open `e` |
| `I` | `I` | Klingon capital-I vowel |
| `o` | `O` | rounded `o` |
| `u` | `U` | rounded `u` |
| `b` | `B` | direct |
| `ch` | `T CH` | SC-01 affricate approximation |
| `D` | `D` | retroflex quality cannot be reproduced exactly |
| `gh` | `G H` | voiced velar/uvular fricative approximation |
| `H` | `H` | uvular/fricative quality is approximate |
| `j` | `D J` | SC-01 affricate approximation |
| `l` | `L` | direct |
| `m` | `M` | direct |
| `n` | `N` | direct |
| `ng` | `NG` | direct |
| `p` | `P` | direct |
| `q` | `K` | uvular stop approximated by `K` |
| `Q` | `K H` | stronger `q`/fricative release approximation |
| `r` | `R` | trill cannot be reproduced exactly |
| `S` | `SH` | Klingon retroflex `S` approximated by `SH` |
| `t` | `T` | direct |
| `tlh` | `T L H` | lateral affricate approximation |
| `v` | `V` | direct |
| `w` | `W` | direct |
| `y` | `Y` | direct |
| `'` | `PA0` | glottal stop approximated by a short closure/pause |

The first-pass encoded ROM records use direct SC-01 phoneme IDs with bits 6-7 clear. That selects the base inflection while remaining compatible with the game's speech decoder. The Votrax library contains the same direct six-bit SC-01 values and is intended for audition and tuning.

## Build

Place the files in the repository as:

```text
src/klingon/KLINGON_X11.asm
src/klingon/README.md
```

The updated build script accepts either spelling requested for the Klingon build:

```sh
./build.sh -k
./build.sh -klingon
./build.sh --klingon
```

The output is `roms/klingon.x11`. German and Klingon are mutually exclusive in a single build because they target the same X11 language-ROM socket.

Stock MAME definitions may still expect the preserved German X11 filename/CRC for a foreign-language clone. `klingon.x11` is intentionally kept as a distinct development artifact; installation/ROM-definition handling can be adjusted after the first hardware/MAME speech test.

## Votrax player library

`votrax_library_wowk.json` contains the exact language-local fragments generated for this ROM. Its `name` is `wowk`, following the existing `wow` / `wowg` convention. Fragment labels retain the hexadecimal fragment ID so the player, ASM pointer table, and phrase table can be compared directly.

## Validation

The generated image is exactly 4096 bytes. The complete image has an 8-bit additive checksum of `$00`, matching `X11_ROM_Checksum_Expected`. The generated reference binary has CRC32 `44f0d9ef`.

The first required test pass is therefore not structural; it is auditory. Build the source with zmac, confirm that the produced 4096-byte image matches the reference binary, boot with the foreign-language DIP selected, and then tune Klingon SC-01 pronunciation fragment-by-fragment in the Votrax player.
