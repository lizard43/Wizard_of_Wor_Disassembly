import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { parseAsmSpriteLibrary } from './asm-sprite-library.mjs';

const marker = '; @sprite bpp=2 bytesPerRow=1 rows=2 header=none';
const fixture = `${marker}\nSPRITE:\n    DB $1B ; four pixels\n    DEFB 0E4H\n`;

test('WoW: all 90 named bitmaps match the established library digest', async () => {
  const text = await readFile(new URL('../../src/wow_disassembly.asm', import.meta.url), 'utf8');
  const result = parseAsmSpriteLibrary(text);
  assert.equal(Object.keys(result.entries).length, 90);
  const canonical = Object.entries(result.entries).sort(([a], [b]) => a.localeCompare(b))
    .map(([name, entry]) => `${name}:${entry.data.join('')}`).join('\n');
  assert.equal(createHash('sha256').update(canonical).digest('hex'),
    '1b51f33838c81732f07bff003b78e8c78dc23d6c68115c277c04467a596c886e');
  for (const [name, entry] of Object.entries(result.entries)) {
    assert.equal(entry.width, 20);
    assert.equal(entry.height, 18);
    assert.equal(entry.data.length, 90);
    assert.equal(entry.rawFixedSizeMode, true);
    const position = result.source.sprites[name];
    assert.equal(text.split('\n')[position.labelLine - 1], `${name}:`);
    assert.equal(position.dataLines.length, 18);
  }
});

test('literal formats, comments, palettes, and header-defined bitmaps', () => {
  const text = '; @sprite bpp=2 bytesPerRow=1 rows=2 header=wh colors=$00,0xF4,125,63H preview=#000000,#123456,#ABCDEF,#FFFFFF\n' +
    'IMAGE: .DB 1,2 ; actual size header\n    DEFB 00011011B,0xE4\n';
  const result = parseAsmSpriteLibrary(text, { sourceName: 'example.asm' });
  assert.deepEqual(result.entries.IMAGE.data, ['0x1B', '0xE4']);
  assert.deepEqual(result.entries.IMAGE.colorBytes, ['0x00', '0xF4', '0x7D', '0x63']);
  assert.equal(result.entries.IMAGE.rawFixedSizeMode, false);
  assert.equal(result.source.name, 'example.asm');
});

test('source positions move with comments; CRLF and exact operand offsets survive', () => {
  const text = `; unrelated note\r\n${fixture.replaceAll('\n', '\r\n')}`;
  const result = parseAsmSpriteLibrary(text);
  const position = result.source.sprites.SPRITE;
  assert.equal(position.markerLine, 2);
  assert.equal(position.labelLine, 3);
  assert.deepEqual(position.dataLines, [4, 5]);
  assert.deepEqual(position.operandSpans.map(span => text.slice(span.start, span.end)), ['$1B', '0E4H']);
});

test('unmarked code and padding after a complete sprite are excluded', () => {
  const result = parseAsmSpriteLibrary(`DB $FF\n${fixture}DB $99\nRoutine:\n LD A,$40\n`);
  assert.deepEqual(result.entries.SPRITE.data, ['0x1B', '0xE4']);
  assert.equal(Object.keys(result.entries).length, 1);
});

const invalid = [
  ['no markers', 'Label: DB $00', /No @sprite/],
  ['short sprite', `${marker}\nSPRITE: DB $00`, /Incomplete sprite/],
  ['extra bytes in a directive', `${marker}\nSPRITE: DB $00,$00,$00`, /exceeds/],
  ['expressions', `${marker}\nSPRITE: DB $01+1,$00`, /Unsupported byte/],
  ['out of range', `${marker}\nSPRITE: DB 256,0`, /Unsupported byte/],
  ['missing label', `${marker}\nDB 0,0`, /colon-terminated/],
  ['unexpected code', `${marker}\nSPRITE:\nLD A,0`, /Expected literal/],
  ['next label too soon', `${marker}\nSPRITE: DB 0\nOTHER: DB 0`, /Unexpected/],
  ['next marker too soon', `${marker}\nSPRITE: DB 0\n${fixture}`, /New marker/],
  ['duplicate names', fixture + fixture.replace('SPRITE:', 'sprite:'), /Duplicate sprite label/],
  ['unknown fields', fixture.replace('bpp=2', 'bpp=2 typo=1'), /Unknown sprite field/],
  ['duplicate fields', fixture.replace('bpp=2', 'bpp=2 bpp=2'), /Duplicate sprite field/],
  ['invalid geometry', fixture.replace('rows=2', 'rows=0'), /rows must/],
  ['missing bpp', fixture.replace('bpp=2 ', ''), /bpp=2/],
  ['invalid header', fixture.replace('header=none', 'header=guess'), /header must/],
  ['inconsistent header', fixture.replace('header=none', 'header=wh').replace('DB $1B', 'DB 2,2,$1B'), /WH bytes/],
  ['invalid palette', fixture.replace('bpp=2', 'bpp=2 colors=0,1,2'), /four byte/],
  ['invalid preview', fixture.replace('bpp=2', 'bpp=2 preview=#000,#111,#222,#333'), /four #RRGGBB/]
];
for (const [name, source, error] of invalid) {
  test(`rejects ${name}`, () => assert.throws(() => parseAsmSpriteLibrary(source), error));
}
