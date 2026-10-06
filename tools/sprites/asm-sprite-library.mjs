/** Parse explicitly marked Astrocade sprites without assembling the surrounding code.
 * Browser-compatible module; source positions are derived afresh on every load.
 */
const LABEL = /^[A-Za-z_.$?@][A-Za-z0-9_.$?@]*$/;

function fail(line, message) {
  throw new Error(`Line ${line}: ${message}`);
}

function byte(token, line) {
  let value;
  if (/^\$[\da-f]{1,2}$/i.test(token)) value = parseInt(token.slice(1), 16);
  else if (/^0x[\da-f]{1,2}$/i.test(token)) value = parseInt(token.slice(2), 16);
  else if (/^[\da-f]{1,3}h$/i.test(token)) value = parseInt(token.slice(0, -1), 16);
  else if (/^[01]{1,8}b$/i.test(token)) value = parseInt(token.slice(0, -1), 2);
  else if (/^\d{1,3}$/.test(token)) value = Number(token);
  if (!Number.isInteger(value) || value > 255) fail(line, `Unsupported byte operand "${token}"`);
  return value;
}

function metadata(text, line) {
  const values = {};
  for (const item of text.trim().split(/\s+/)) {
    const match = item.match(/^([A-Za-z]+)=(\S+)$/);
    if (!match) fail(line, `Invalid sprite field "${item}"`);
    const [, key, value] = match;
    if (!['bpp', 'bytesPerRow', 'rows', 'header', 'colors', 'preview'].includes(key)) {
      fail(line, `Unknown sprite field "${key}"`);
    }
    if (Object.hasOwn(values, key)) fail(line, `Duplicate sprite field "${key}"`);
    values[key] = value;
  }
  if (values.bpp !== '2') fail(line, 'bpp=2 is required');
  for (const key of ['bytesPerRow', 'rows']) {
    if (!/^\d+$/.test(values[key] || '') || Number(values[key]) < 1 || Number(values[key]) > 255) {
      fail(line, `${key} must be an integer from 1 to 255`);
    }
    values[key] = Number(values[key]);
  }
  if (!['none', 'wh'].includes(values.header)) fail(line, 'header must be none or wh');
  if (values.colors) {
    const tokens = values.colors.split(',');
    if (tokens.length !== 4) fail(line, 'colors requires four byte operands');
    values.colors = tokens.map(token => byte(token, line));
  }
  if (values.preview) {
    const tokens = values.preview.split(',');
    if (tokens.length !== 4 || tokens.some(token => !/^#[\da-f]{6}$/i.test(token))) {
      fail(line, 'preview requires four #RRGGBB colors');
    }
    values.preview = tokens.map(token => token.toUpperCase());
  }
  return values;
}

const hex = value => `0x${value.toString(16).toUpperCase().padStart(2, '0')}`;

/** Return {lastUsed, entries, source}. Entries contain bitmap bytes only.
 * source.sprites holds 1-based line numbers and UTF-16 offsets into the input.
 * Unmarked assembly is ignored. Expressions/macros inside sprites are rejected.
 */
export function parseAsmSpriteLibrary(text, { sourceName = '' } = {}) {
  if (typeof text !== 'string') throw new TypeError('ASM source must be a string');
  const lines = text.split('\n');
  const offsets = [];
  let offset = 0;
  for (const line of lines) { offsets.push(offset); offset += line.length + 1; }
  const entries = Object.create(null);
  const positions = Object.create(null);
  const names = new Set();

  for (let i = 0; i < lines.length; i++) {
    const marker = lines[i].replace(/\r$/, '').match(/^\s*;\s*@sprite\b(.*)$/);
    if (!marker) continue;
    const markerLine = i + 1;
    const spec = metadata(marker[1], markerLine);
    let label;
    let labelLine;
    const data = [];
    const dataLines = [];
    const operandSpans = [];
    const needed = spec.bytesPerRow * spec.rows + (spec.header === 'wh' ? 2 : 0);
    let end;

    for (let j = i + 1; j < lines.length; j++) {
      const raw = lines[j];
      if (/^\s*;\s*@sprite\b/.test(raw)) fail(j + 1, 'New marker before preceding sprite was complete');
      const code = raw.split(';')[0].trim();
      if (!code) continue;
      let body = code;
      const labelMatch = code.match(/^([^\s:]+):\s*(.*)$/);
      if (labelMatch) {
        if (label || !LABEL.test(labelMatch[1])) fail(j + 1, 'Unexpected or invalid sprite label');
        label = labelMatch[1];
        labelLine = j + 1;
        if (names.has(label.toUpperCase())) fail(j + 1, `Duplicate sprite label "${label}"`);
        body = labelMatch[2];
        if (!body) continue;
      }
      if (!label) fail(j + 1, 'Sprite marker must precede a colon-terminated label');
      const db = body.match(/^(?:\.?DB|DEFB)\s+(.+)$/i);
      if (!db) fail(j + 1, 'Expected literal DB, .DB, or DEFB sprite bytes');
      const tokens = db[1].split(',').map(token => token.trim());
      const values = tokens.map(token => byte(token, j + 1));
      if (data.length + values.length > needed) fail(j + 1, 'Byte directive exceeds declared sprite size');
      data.push(...values);
      dataLines.push(j + 1);
      // Keep exact operand spans for a future source-preserving editor writer.
      const directive = raw.split(';')[0].match(/(?:^|\s)(?:\.?DB|DEFB)\s+(.+?)\s*$/i);
      const start = raw.indexOf(directive[1], directive.index);
      operandSpans.push({ start: offsets[j] + start, end: offsets[j] + start + directive[1].length });
      if (data.length === needed) { end = j; break; }
    }
    if (end === undefined) fail(markerLine, `Incomplete sprite: expected ${needed} bytes, found ${data.length}`);
    if (spec.header === 'wh' && (data[0] !== spec.bytesPerRow || data[1] !== spec.rows)) {
      fail(labelLine, 'WH bytes disagree with marker geometry');
    }
    const bitmap = spec.header === 'wh' ? data.slice(2) : data;
    const entry = {
      width: spec.bytesPerRow * 4,
      height: spec.rows,
      bytesPerRow: spec.bytesPerRow,
      rawFixedSizeMode: spec.header === 'none',
      data: bitmap.map(hex)
    };
    if (spec.colors) entry.colorBytes = spec.colors.map(hex);
    if (spec.preview) entry.colorPreviewHex = spec.preview;
    entries[label] = entry;
    positions[label] = {
      markerLine, labelLine, dataLines, operandSpans,
      start: offsets[i], end: offsets[end] + lines[end].replace(/\r$/, '').length
    };
    names.add(label.toUpperCase());
    i = end;
  }
  if (!names.size) throw new Error('No @sprite markers found');
  return { lastUsed: Object.keys(entries)[0], entries, source: { name: sourceName, sprites: positions } };
}
