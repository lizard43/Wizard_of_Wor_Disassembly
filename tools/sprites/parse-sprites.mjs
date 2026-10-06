#!/usr/bin/env node
import { readFile } from 'node:fs/promises';
import { parseAsmSpriteLibrary } from './asm-sprite-library.mjs';

const args = process.argv.slice(2);
if (args.length !== 1) {
  console.error('Usage: node tools/sprites/parse-sprites.mjs path/to/source.asm');
  process.exitCode = 1;
} else {
  try {
    const text = await readFile(args[0], 'utf8');
    const result = parseAsmSpriteLibrary(text, { sourceName: args[0] });
    process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
