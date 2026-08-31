/* Service worker: puslapis veikia ir be interneto.
   Pakeitus failus butina padidinti VERSIJA - kitaip telefonas rodys sena. */
const VERSIJA = 'fotografija-v1';

const APVALKALAS = [
  './',
  './index.html',
  './assets/style.css',
  './assets/app.js',
  './photos.js',
  './manifest.json',
  './icons/icon-180.png',
  './icons/icon-192.png',
  './icons/icon-512.png'
];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(VERSIJA)
      .then((c) => c.addAll(APVALKALAS))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((v) => Promise.all(v.filter((k) => k !== VERSIJA).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (e) => {
  const url = new URL(e.request.url);
  if (e.request.method !== 'GET' || url.origin !== location.origin) return;

  e.respondWith(
    caches.match(e.request).then((rasta) => {
      if (rasta) return rasta;

      return fetch(e.request).then((atsakymas) => {
        // nuotraukas issaugom, kai jos pirma karta parsiunciamos
        if (atsakymas.ok && url.pathname.includes('/photos/')) {
          const kopija = atsakymas.clone();
          caches.open(VERSIJA).then((c) => c.put(e.request, kopija));
        }
        return atsakymas;
      }).catch(() => caches.match('./index.html'));
    })
  );
});
