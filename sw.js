/* Service worker — ported from Resources/sw.js.
   FIX vs Swift version: versioned cache (old 'bezzubick-v1' never updated,
   clients stuck on stale shell), no WASM entries, links.json covered,
   BASE derived from scope instead of hardcoded. */
'use strict';

var CACHE = 'bezzubick-v2';
var BASE = new URL(registration.scope).pathname.replace(/\/$/, '');

var APP_SHELL = [
  BASE + '/',
  BASE + '/links/',
  BASE + '/css/style.css',
  BASE + '/js/common.js',
  BASE + '/js/home.js',
  BASE + '/js/links.js',
  BASE + '/js/vendor/skinview3d.bundle.js',
  BASE + '/assets/avatar.png',
  BASE + '/assets/skin.png',
  BASE + '/assets/links.json',
  BASE + '/manifest.webmanifest',
];

var NETWORK_FIRST = [
  BASE + '/data.json',
  BASE + '/streams_history.json',
  BASE + '/assets/links.json',
];

self.addEventListener('install', function (event) {
  event.waitUntil(
    caches.open(CACHE).then(function (cache) {
      return Promise.all(APP_SHELL.map(function (url) {
        return cache.add(url).catch(function () {});
      }));
    }).then(function () { return self.skipWaiting(); })
  );
});

self.addEventListener('activate', function (event) {
  event.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(keys.filter(function (k) { return k !== CACHE; })
        .map(function (k) { return caches.delete(k); }));
    }).then(function () { return self.clients.claim(); })
  );
});

self.addEventListener('fetch', function (event) {
  var req = event.request;
  if (req.method !== 'GET') return;
  var url = new URL(req.url);
  if (url.origin !== location.origin) return;

  if (NETWORK_FIRST.indexOf(url.pathname) !== -1) {
    event.respondWith(
      fetch(req).then(function (resp) {
        if (resp && resp.status === 200) {
          var copy = resp.clone();
          caches.open(CACHE).then(function (c) { c.put(url.pathname, copy); });
        }
        return resp;
      }).catch(function () {
        return caches.match(url.pathname);
      })
    );
    return;
  }

  event.respondWith(
    caches.match(req).then(function (cached) {
      var network = fetch(req).then(function (resp) {
        if (resp && resp.status === 200) {
          var copy = resp.clone();
          caches.open(CACHE).then(function (c) { c.put(req, copy); });
        }
        return resp;
      }).catch(function () { return cached; });
      return cached || network;
    })
  );
});
