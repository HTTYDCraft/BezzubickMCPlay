/* Service worker for BezzubickMCPlay (GitHub Pages project site).
   App shell is cache-first, data files are network-first with offline fallback. */
'use strict';

var CACHE = 'bezzubick-v1';
var BASE = '/BezzubickMCPlay';

var APP_SHELL = [
  BASE + '/',
  BASE + '/links/',
  BASE + '/scripts/skinview3d.bundle.js',
  BASE + '/scripts/javascriptkit.js',
  BASE + '/assets/avatar.png',
  BASE + '/assets/skin.png'
];

// Always try the network first for these so fresh counts arrive when online.
// Cached under their bare pathname because the site appends a ?t= cache buster.
var NETWORK_FIRST = [BASE + '/data.json', BASE + '/streams_history.json'];

self.addEventListener('install', function (event) {
  event.waitUntil(
    caches.open(CACHE).then(function (cache) {
      // Best effort: installation must not fail because one asset is missing.
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
  if (url.origin !== location.origin) return; // let fonts/CDNs/embeds pass through

  if (NETWORK_FIRST.indexOf(url.pathname) !== -1) {
    // Network first; ignore the ?t= cache buster when storing/matching.
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

  // Cache first with background refresh (stale-while-revalidate).
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
