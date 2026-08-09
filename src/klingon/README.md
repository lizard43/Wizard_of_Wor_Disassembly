<!-- README.md -->
# Wizard of Wor Klingon X11

This directory contains the Klingon (`tlhIngan Hol`) X11 language ROM for Wizard of Wor. The ROM uses the same 4 KB data interface as the German X11 ROM.

## X11 interface

| Address | Field | Klingon ROM use |
|---|---|---|
| `$C000` | speech-fragment pointer-table pointer | `$CD8D` |
| `$C002` | speech-phrase table pointer | `$CE35` |
| `$C004` | foreign coinage values | retained from German X11 |
| `$C00A` | expected diagnostic checksum | `$00` |
| `$C00B` | alternate-font pointer | `$C1D2` |
| `$C00D` | localized display table | 23 length-prefixed records |
| `$C200` | speech record area | fixed German physical record layout |
| `$CD8D` | fragment pointer table | 84 slots (`$00-$53`) |
| `$CE35` | phrase table | 80 game phrase IDs (`$00-$4F`) |
| `$CF1D` | checksum compensation | `$DC` in this image |
| `$CFEB` | ROM identification | `KLINGONWIZARD` / `DNA` |

## Display text

The game scans localized strings as a length byte below `$30` followed by character bytes at or above `$30`. Klingon cannot store ASCII apostrophe `$27` directly in a text record.

This ROM uses two safe extended character codes that `char2gfx` already routes through the X11 alternate-font pointer:

- `$62` = Klingon apostrophe `'`
- `$63` = lowercase `q`

The apostrophe is a consonant in Klingon, and `q` and `Q` are different letters. Preserving those two forms makes the arcade display much closer to normal Klingon orthography. The other alphabetic characters use the resident uppercase WoW glyphs.

The 23 display strings use natural record lengths. They do not have to match the German string lengths; the main program searches the records dynamically. Unused bytes before `$C1D1` remain erased so the speech area still begins at `$C200`.

## Speech layout

The current working speech data retains the German X11 physical record addresses and count bytes. For every speech payload position, stored bits 7-6 remain unchanged from the working German-template baseline; the Klingon pronunciation occupies the low six SC-01 phoneme bits.

The pointer table remains at `$CD8D`, with `$4F` null. Slots `$50-$52` are short Klingon grammar helpers used by the phrase table; `$53` remains a non-null compatibility record but is not referenced by Klingon phrases.

The phrase table is language-local. It is based on the resident English semantic composition, with seven deliberate Klingon changes: `$08`, `$11`, `$12`, `$23`, `$30`, `$33`, and `$42`. These changes select the padded rank token where appropriate, correct Klingon word order, add the minimum required grammar helpers, and avoid a duplicated “dungeons of Wor” fragment.

The resident `Dungeon_Class` substitution remains unchanged:

```text
$09 -> $40
$37 -> $41
```

This changes the spoken rank from Worrior to Worlord before the selected fragment pointer is resolved.

## Translation status

The display strings received a targeted language cleanup using established vocabulary such as `chen'ong` (maze), `tlhapragh` (monster), `Huch jengva'` (coin), `mIvwa'mey` (score/tally), `leQ` (button/switch), and `HotlhwI'` (scanner).

## Runtime status

Current MAME testing shows the Klingon set progressing normally through attract mode, score tables, instruction screens, coin/player selection, radar display, and active gameplay. Speech is event-driven with normal pauses rather than the previous continuous-output failure.

This establishes the X11 runtime structure as working. It does not by itself certify every Klingon translation or SC-01 pronunciation; the remaining language items are tracked in `KLINGON_PHRASE_MAP.md`.

## Build and validation

Use:

```bash
./build.sh -k
```

The Klingon build first creates `roms/wowk.zip`. It contains the seven WoW CPU ROMs, `sc01.bin` when present, and the language ROM as `klingon.x11`.

MAME 0.280 does not define a `wowk` machine. The Astrocade driver defines `wowg` for the foreign-language X11 configuration and expects the X11 ROM to be named `german.x11`. After `wowk.zip` is created, the build runs `src/klingon/renameK.sh`. The script copies `wowk.zip` to `roms/wowg.zip` and renames only the X11 archive member:

```text
wowk.zip:klingon.x11
        ->
wowg.zip:german.x11
```

The X11 data is unchanged; only its filename inside the MAME compatibility archive changes. `wowk.zip` remains the Klingon project artifact. The generated `wowg.zip` is the package used to run Klingon with the existing MAME driver.

Run it with:

```bash
mame -window -skip_gameinfo -rompath roms/ wowg
```

The `-k` build therefore produces:

- `roms/wowk.zip` containing `wow.x1` through `wow.x7`, `sc01.bin`, and `klingon.x11`
- `roms/wowg.zip` containing the same game and speech ROMs, with the Klingon X11 stored as `german.x11`
