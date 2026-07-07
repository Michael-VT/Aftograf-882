/**
 * Build bundle.js from source modules.
 * Strips import/export statements and concatenates in dependency order.
 */
import { readFileSync, writeFileSync, copyFileSync } from 'fs';

const files = [
  'settings.js',
  'memory.js',
  'cpu8080.js',
  'main.js',
];

const parts = ['// Autograf-882 bundle\n\n'];

for (const f of files) {
  let src = readFileSync(f, 'utf-8');

  // Strip top-level imports (multi-line or single)
  src = src.replace(/^import\s+.*?from\s+['"].*?['"];\n?/gm, '');
  // Strip top-level exports
  src = src.replace(/^export\s+/gm, '');

  parts.push(src);
  parts.push('\n\n\n');
}

writeFileSync('bundle.js', parts.join(''));
console.log('bundle.js written');
