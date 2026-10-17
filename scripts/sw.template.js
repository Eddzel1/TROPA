// Offline service worker for the TROPA web app. Generated into build/web/sw.js by
// scripts/gen_sw.mjs, which fills in the cache version and the precache file list.
'use strict';

const VERSION = '__VERSION__';
const CACHE = `tropa-${VERSION}`;
const FONT_CACHE = 'tropa-fonts';
const PRECACHE = __PRECACHE__;
// Renderer variants: Flutter loads canvaskit/chromium/* on Chromium browsers that support image
// decoding and its text segmentation, canvaskit/canvaskit.* elsewhere. Only the matching one is
// cached at install; anything else is cached the first time it is fetched (see cacheFirst).
const CANVASKIT = __CANVASKIT__;
const USES_CHROMIUM_CANVASKIT =
  !!(self.navigator.userAgentData &&
    self.navigator.userAgentData.brands.some((b) => b.brand === 'Chromium')) &&
  'ImageDecoder' in self &&
  !!(self.Intl && Intl.Segmenter && Intl.v8BreakIterator);
const FONT_HOSTS = ['fonts.googleapis.com', 'fonts.gstatic.com'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE);
      // Bypass the HTTP cache so a new version never stores stale files.
      await cache.addAll(PRECACHE.map((url) => new Request(url, { cache: 'reload' })));
      // The renderer was just downloaded by the page, so let the HTTP cache serve it. A failure
      // here doesn't block install; the renderer is then cached on its next fetch instead.
      const renderer = USES_CHROMIUM_CANVASKIT ? CANVASKIT.chromium : CANVASKIT.full;
      await cache.addAll(renderer).catch((e) => console.warn('Renderer not precached:', e));
      await self.skipWaiting();
    })()
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(
        keys
          .filter((key) => key.startsWith('tropa-') && key !== CACHE && key !== FONT_CACHE)
          .map((key) => caches.delete(key))
      );
      await self.clients.claim();
    })()
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);

  if (request.mode === 'navigate') {
    event.respondWith(networkFirstPage(request));
  } else if (url.origin === self.location.origin) {
    event.respondWith(cacheFirst(request));
  } else if (FONT_HOSTS.includes(url.hostname)) {
    event.respondWith(staleWhileRevalidate(request));
  }
  // Everything else (Supabase, PowerSync, map tiles) goes straight to the network.
});

async function networkFirstPage(request) {
  try {
    return await fetch(request);
  } catch (e) {
    const cache = await caches.open(CACHE);
    return (await cache.match('index.html')) || Response.error();
  }
}

async function cacheFirst(request) {
  const cache = await caches.open(CACHE);
  const cached = await cache.match(request, { ignoreSearch: true });
  if (cached) return cached;
  // Not precached (e.g. a renderer variant): cache it now so the next launch works offline.
  const response = await fetch(request);
  if (response.ok) cache.put(request, response.clone()).catch(() => {});
  return response;
}

async function staleWhileRevalidate(request) {
  const cache = await caches.open(FONT_CACHE);
  const cached = await cache.match(request);
  const network = fetch(request)
    .then((response) => {
      if (response.ok || response.type === 'opaque') cache.put(request, response.clone());
      return response;
    })
    .catch(() => cached || Response.error());
  return cached || network;
}
