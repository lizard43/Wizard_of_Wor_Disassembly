<!-- README.md -->
# Wizard of Wor German X11 language ROM

This directory contains the reverse source for the 4 KB German language ROM used by Wizard of Wor in socket X11. The cleaned source preserves the original ROM bytes while documenting the interface expected by the main game program.

## X11 language-ROM interface

The X11 image occupies `$C000-$CFFF`. The main program selects the resident English resources when SETTINGS/DIP bit 3 is set and X11 resources when the bit is clear. The language switch is sampled where the resource is used rather than copied into a permanent global language variable.

| Address | Field | Purpose |
| --- | --- | --- |
| `$C000` | `X11_Speech_Fragment_Table_Ptr` | Pointer to the language-local speech fragment pointer table. |
| `$C002` | `X11_Speech_Phrase_Table_Ptr` | Pointer to the 80-entry language-local phrase table. |
| `$C004` | `X11_Coinage_Value_Table` | Six foreign-mode coinage conversion values used by the credit logic. |
| `$C00A` | `X11_ROM_Checksum_Expected` | Expected modulo-256 additive checksum used by diagnostics for ROM X. |
| `$C00B` | `X11_Alternate_Font_Ptr` | Pointer to optional alternate glyph data used by `char2gfx`. |
| `$C00D` | `German_Localized_Text_Table` | Base of 23 length-prefixed localized display strings. |

## Localized text

The main game identifies text records by a 1-based index. A record begins with a length byte below `$30`, followed by display characters whose encoded values are `$30` or above. The scanner therefore recognizes the next byte below `$30` as the next record header. The format permits a maximum record length of `$2F` (47) characters.

The German table contains 23 records and can use different string lengths from the resident English text because the main program searches records dynamically.

## Speech architecture

Speech requests use language-independent phrase IDs `$00-$4F` (80 total). A phrase table record begins with `$81-$84`; the low seven bits are the number of speech fragments in the phrase and the following bytes are fragment indexes. The fragment indexes are language-local.

The German X11 image provides 84 fragment pointers (`$00-$53`). Each pointer resolves to a length-prefixed encoded SC-01 stream. The playback code maintains the inflection state separately, so stored speech bytes should be treated as the game's encoded SC-01 stream rather than as independent raw phoneme IDs.

When RAM state `$D350` is nonzero, the main program substitutes fragment `$09` with `$40` and fragment `$37` with `$41` before pointer lookup. The gameplay meaning of `$D350` is not yet assigned a semantic name; a replacement language ROM must preserve compatible entries for those substitutions.

## Diagnostics and checksum

With English selected, diagnostics test the seven resident program ROMs. With foreign language selected, the test includes an eighth item, ROM `X`, redirects the scan from the empty `$B000` socket to `$C000`, sums the complete 4 KB X11 image modulo 256, and compares the result with the byte at `$C00A`.

The German ROM expects checksum `$00`. `German_Checksum_Compensation` at `$CF1D` contains `$B6`; the remaining bytes sum to `$4A`, and `$4A + $B6` wraps to `$00`. This makes the full 4 KB additive checksum match the header value.

## Build

The project build script supports the optional German ROM with:

```sh
./build.sh --german
```

The German source is assembled independently and copied to `roms/german.x11` before the MAME archive is created.

## Verification

The cleaned `GERMAN_X11.asm` reconstructs the same 4096-byte image as the supplied reverse source:

- Size: 4096 bytes
- CRC32: `16f84d73`
- Additive checksum (low 8 bits): `$00`

## Historical README

The text below is retained verbatim as provenance for the supplied reverse source. Some statements describe the state of MAME or unresolved structures at the time the original notes were written and are superseded by the documentation above.

---

Original READ ME DIZ.txt contents below:

-------------------------------

NOTE: Probably disassembled by Richard Degler

READ ME DIZ (Description In ZIP) for my Reverse Source of the file "GERMAN.X11" (C) 1981 DNA, for WIZARD OF WOR (a BALLY Commercial Arcade Game) ROM socket x11.


Don't rember the exact BBS naming convention, but all file archives had inserted
in them a READ_ME.1ST, FILE_ID.DIZ and ORIGINAL.BBS - and those extentions were
usually associated as being text files by whatever reader was in use back then.
The practice was to hard-wrap all lines to 79 or 80 characters for EGA monitors!
         1         2         3         4         5         6         7         8
12345678901234567890123456789012345678901234567890123456789012345678901234567890

Nowadays, since the turn of the century, we turn on auto word-wrap and only hit Return to start a new paragraph.  Sometimes that's not good, like in .asm files.


So, this is "GERMAN_X11.asm" foreign language file for WIZARD OF WOR arcade game dis-assembled and commented by me.  Some lines must extend up to 160 characters.
MAME currently does NOT recognize "GERMAN.X11", or should it be named "WOW.X11"?

First up at LC000: is the location of 84 GERMAN Speech String pointers which are indexed by an 80-entry GERMAN Phrase Data table (which is pointed to by LC002:).
These contain 1 to 4 entries each as noted by the flagged hex numbers $81 to $84 and still need to be extrapolated from the speech string data, based on a SC-01.

Next at LC004: is a Funny table of 6 entries of ASCII values, of unknown usage.

At LC00A: is the CHECKSUM Byte of 0, which is not even checked by the self-test?

And at LC00B: is the address of an ALTernate FoNT that needs taken advantage of!

Starting at LC00D: are 23 text strings preceded by their length - and these are displayed instead of the English equivalent when the "FOREIGN" dip-switch is on.
The 47 character limit is imposed as ASCII 48 and above are ignored counting up.

Finally, at the very end, after 205 filler bytes, is LCFEB: (ROM Identification only) of "GERMAN WIZARD", "DNA" and what could be the Date stamp of 4/30/1981 - that refers to Dave Nutting Associates (A Bally Co.), who still owns the rights?


"Welcome to my Dungeons of Wor!" (C) 1980 Midway Mfg. Co. "VIDEO IS OUR GAME" tm
