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
  'NOTICES', // 1.4 MB of licence text, only opened from the About dialog
]);

// The renderer ships in several variants but a browser loads only one: canvaskit/chromium/* on
// Chrome and Edge, canvaskit/canvaskit.* elsewhere. The others (skwasm, wimp, webparagraph) are
// only for other build modes. Instead of precaching ~30 MB of them, the worker caches just the
// variant its browser uses (see CANVASKIT in sw.template.js).
const CANVASKIT = {
  chromium: ['canvaskit/chromium/canvaskit.js', 'canvaskit/chromium/canvaskit.wasm'],
  full: ['canvaskit/canvaskit.js', 'canvaskit/canvaskit.wasm'],
};

function walk(dir) {
  return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) return entry.name === '.vercel' ? [] : walk(full);
    if (SKIP_NAMES.has(entry.name) || entry.name.endsWith('.symbols')) return [];
    if (relative(buildDir, full).split(sep)[0] === 'canvaskit') return [];
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
// The renderer variants count toward the version too (and the build fails if one is missing), so
// a Flutter upgrade replaces the cached renderer.
for (const file of Object.values(CANVASKIT).flat()) hash.update(file).update(readFileSync(join(buildDir, file)));
const version = hash.digest('hex').slice(0, 12);

const output = readFileSync(templatePath, 'utf8')
  .replaceAll('__VERSION__', () => version)
  .replaceAll('__PRECACHE__', () => JSON.stringify(precache, null, 2))
  .replaceAll('__CANVASKIT__', () => JSON.stringify(CANVASKIT, null, 2));
writeFileSync(join(buildDir, 'sw.js'), output);
// index.html carries the same version so the page can tell when its cached worker is out of date.
// It is stamped after hashing; the hash already covers the rest of index.html.
const indexPath = join(buildDir, 'index.html');
writeFileSync(indexPath, readFileSync(indexPath, 'utf8').replaceAll('__TROPA_BUILD__', () => version));
console.log(`sw.js: version ${version}, ${precache.length} files precached`);
