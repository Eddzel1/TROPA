// Generates <buildDir>/sw.js from scripts/sw.template.js with the list of files to precache and a
// content hash as the cache version. Usage: node scripts/gen_sw.mjs build/web
import { createHash } from 'node:crypto';
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const buildDir = process.argv[2] ?? 'build/web';
const templatePath = join(dirname(fileURLToPath(import.meta.url)), 'sw.template.js');

const SKIP_NAMES = new Set([
  '.last_build_id',
  '.gitignore',
  'vercel.json',
  'sw.js',
  'flutter_service_worker.js',
]);

function walk(dir) {
  return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) return entry.name === '.vercel' ? [] : walk(full);
    if (SKIP_NAMES.has(entry.name) || entry.name.endsWith('.symbols')) return [];
    return [full];
  });
}

const files = walk(buildDir).sort();
const hash = createHash('sha256');
const precache = files.map((file) => {
  const path = relative(buildDir, file).split(sep).join('/');
  hash.update(path).update(readFileSync(file));
  return path;
});
const version = hash.digest('hex').slice(0, 12);

const output = readFileSync(templatePath, 'utf8')
  .replaceAll('__VERSION__', () => version)
  .replaceAll('__PRECACHE__', () => JSON.stringify(precache, null, 2));
writeFileSync(join(buildDir, 'sw.js'), output);
console.log(`sw.js: version ${version}, ${precache.length} files precached`);
