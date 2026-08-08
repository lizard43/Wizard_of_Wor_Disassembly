<!-- README.md -->
# Wizard of Wor Klingon X11 language ROM

This directory contains an experimental Klingon (`tlhIngan Hol`) language ROM
for the Wizard of Wor X11 socket. This compatibility pass uses the same data-only
interface and the same important physical layout addresses as the preserved
German X11 ROM.

## Why this revision exists

The first prototype proved that MAME could read Klingon X11 text and that its
SC-01 records produced speech, but its fragment IDs were allocated mostly in
phrase-creation order. That made the Votrax library misleading: for example,
fragment `$04` was only punctuation even though English/German fragment `$04`
means “The Wizard of Wor.”

This revision fixes the data model before pronunciation tuning continues.

## Compatibility layout

| Address | Field |
| --- | --- |
| `$C000` | fragment-pointer table pointer |
| `$C002` | 80-entry phrase-table pointer |
| `$C004` | six foreign-mode coinage values |
| `$C00A` | expected additive checksum (`$00`) |
| `$C00B` | alternate-font pointer |
| `$C00D` | 23 localized display records |
| `$C1D1` | alignment byte |
| `$C1D2` | reserved alternate-font area |
| `$C200` | Klingon speech records |
| `$CD8D` | 84-slot fragment pointer table |
| `$CE35` | 80-entry phrase table |
| `$CF1D` | checksum compensation |
| `$CFEB` | ROM identification tail |

The fixed addresses from `$C1D1` onward deliberately match the known-good German
ROM. The pointer-based ABI does not require all of them, but retaining them
removes an unnecessary variable during runtime testing.

## Fragment IDs versus phrase IDs

The game has 80 phrase IDs (`$00-$4F`). Those phrase IDs expand into reusable
language-local fragments.

Klingon fragments `$00-$4E` now follow the English semantic fragment slots:

- `$04` = `Wor 'IDnar pIn` — “The Wizard of Wor”
- `$0B` = `HISam` — “Find me”
- `$10` = laughter
- `$09/$37` = `SuvwI'`
- `$40/$41` = `SuvwI' joH`
- `$50-$52` = Klingon-only grammar helpers
- `$4F` and `$53` = null

`KLINGON_PHRASE_MAP.md` contains separate fragment and phrase tables so the two
namespaces cannot be mistaken for each other.

## Rank substitution

The resident game performs:

```text
$09 -> $40
$37 -> $41
```

when `Dungeon_Class != 0`. The Klingon slots preserve this contract, changing
`SuvwI'` to `SuvwI' joH` before the X11 fragment pointer is resolved.

## Speech cadence

The first prototype ended nearly every Klingon fragment with `PA1`. That did not
match the original WoW fragment boundaries and inserted long pauses inside some
multi-fragment phrases.

For `$00-$4E`, this revision mirrors the corresponding English fragment's
leading/trailing `PA0`/`PA1` boundary behavior. Fragments intended to join
directly no longer gain an artificial final pause.

The ROM currently stores neutral direct SC-01 values in bits 0-5 with bits 6-7
clear. Inflection is deliberately deferred until the phrase selection, queueing,
and gameplay behavior are stable.

## Display text

The arcade scanner treats bytes below `$30` as record boundaries, so normal
Klingon apostrophes cannot be emitted as display characters. Screen strings use
uppercase apostrophe-free transliteration and `@` for spaces; canonical Klingon
is retained in comments.

Each display record is padded to the exact encoded length of its German
counterpart. This keeps the downstream X11 layout fixed.

## Build and MAME filename

Use:

```sh
./build.sh -k
./build.sh -klingon
./build.sh --klingon
```

The project artifact is written as `roms/klingon.x11`.

MAME's existing `wowg` definition expects the X11 socket filename `german.x11`.
For a Klingon build, `build.sh` stages the same Klingon image as `german.x11`
inside `wow.zip` while retaining the truthful `klingon.x11` artifact on disk.

German and Klingon are mutually exclusive because they occupy the same X11
socket.

## Validation

- size: 4096 bytes
- range: `$C000-$CFFF`
- additive checksum: `$00`
- checksum compensation: `$31` at `$CF1D`
- CRC32: `8024422a`
- fragment-pointer slots: 84
- actual Klingon fragments: 82
- game phrase records: 80

The Klingon translation and SC-01 pronunciation remain experimental. Structural
correctness and pronunciation quality are intentionally treated as separate
test phases.
