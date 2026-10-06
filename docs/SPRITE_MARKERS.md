# ASM sprite markers

`src/wow_disassembly.asm` is the sprite library source. Its 90 marked WoW
sprites each contain a raw 20 × 18 pixel bitmap: five bytes per row, 18 rows.
Markers are assembler comments and emit no bytes.

```asm
; BURWOR_1
; 5 bytes/row = 20 pixels wide, 18 rows
; @sprite bpp=2 bytesPerRow=5 rows=18 header=none
BURWOR_1:
        DB       $00,$00,$00,$00,$40
        ; remaining 17 rows...
```

The existing colon-terminated ASM label is the canonical sprite name. No name,
ROM address, or source line number is duplicated in the marker. Current source
positions are returned by the parser. ROM addresses require an assembler listing
or symbol map; this parser does not assemble code or calculate addresses.

## Marker fields

Fields are case-sensitive, whitespace-separated `key=value` tokens. No spaces
are permitted inside a field value. Unknown or duplicate fields are errors.

| Field | Meaning |
| --- | --- |
| `bpp=2` | Required packed 2bpp format; four pixels per byte, high bits first. |
| `bytesPerRow=5` | Required integer from 1 through 255; width is this value × 4 pixels. |
| `rows=18` | Required integer from 1 through 255. |
| `header=none` | Raw bitmap, with no emitted dimension header. Used by all 90 WoW sprites. |
| `header=wh` | Two leading emitted bytes specify bytes per row and rows. They must agree with the marker and are excluded from returned bitmap data. |
| `colors=$00,$F4,$7D,$63` | Optional four hardware color bytes, in pixel-value order 0–3. Preview metadata; the comment does not alter game palettes. |
| `preview=#000000,#123456,#ABCDEF,#FFFFFF` | Optional four display colors in pixel-value order 0–3. |

The marker must appear before its label, with only blank/comment lines between
them. Labels may have a byte directive on the same line. Sprite byte directives
accept `DB`, `.DB`, and `DEFB`, case-insensitively, and comma-separated literals:
`$FF`, `0xFF`, `0FFH`, `11111111B`, or decimal `255`. Inline semicolon comments
are ignored. Expressions, symbols, strings, macros, and other directives within
a marked bitmap are rejected rather than partially parsed.

The declared geometry determines the exact byte count. The parser stops at the
last required byte directive, leaving following padding and other data alone.
A directive that crosses that boundary is an error; put unrelated bytes on a
separate directive. Incomplete sprites, unexpected labels, conflicting WH
headers, and duplicate sprite labels (including case-only duplicates) are errors.

## Parser API

`tools/sprites/asm-sprite-library.mjs` has no dependencies or Node-specific
imports and can be imported by a browser module or Node:

```js
import { parseAsmSpriteLibrary } from './asm-sprite-library.mjs';
const library = parseAsmSpriteLibrary(asmText, { sourceName: 'wow_disassembly.asm' });
```

The result has `lastUsed`, `entries`, and `source`. Each entry matches the current
Astrocade gallery/editor bitmap model: `width`, `height`, `bytesPerRow`,
`rawFixedSizeMode`, `data` (hex strings), and optional `colorBytes` and
`colorPreviewHex`. `lastUsed` initially selects the first sprite in source order.
No JSON file needs to be maintained alongside the ASM.

`source.sprites[label]` contains 1-based `markerLine`, `labelLine`, and
`dataLines`, plus zero-based UTF-16 `start`/exclusive `end` offsets covering the
marker through the last byte directive. `operandSpans` identifies only each
byte directive's operand text, also with exclusive end offsets. These are positions
in the exact input string, including CRLF where present. Keep the original text
and this source map outside the UI's normalized entry model for later source
editing. Reloading the ASM recalculates every position.

For inspection, the CLI prints the parsed model to stdout:

```sh
node tools/sprites/parse-sprites.mjs src/wow_disassembly.asm
node --test tools/sprites/asm-sprite-library.test.mjs
```

The tests check all 90 names and bitmap bytes against a fixed digest derived
from the existing July 27 WoW JSON library, plus parser errors, header handling,
palettes, CRLF positions, and exclusion of unmarked data.

This change supplies the marker format and parser. Connecting the gallery/editor
load controls and implementing full-source ASM saving are subsequent work.
