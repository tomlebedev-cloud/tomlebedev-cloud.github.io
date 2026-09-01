/* Service worker: puslapis veikia ir be interneto.
   Pakeitus failus butina padidinti VERSIJA - kitaip telefonas rodys sena. */
const VERSIJA = 'fotografija-v4';
const MAX_NUOTRAUKU = 80;   // kiek nuotrauku laikom talpykloje

const APVALKALAS = [
  './',
  './index.html',
  './assets/style.css',
  './assets/app.js',
  './photos.js',
  './manifest.json',
  './404.html',
  './og-image.png',
  './icons/favicon-32.png',
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

// Neleidziam talpyklai augti be ribos: virsijus MAX_NUOTRAUKU
// pasalinam seniausiai idetas nuotraukas (Cache API issaugo eiliskuma).
async function apkarpykTalpykla() {
  const c = await caches.open(VERSIJA);
  const raktai = (await c.keys()).filter((r) => new URL(r.url).pathname.includes("/photos/"));
  const perteklius = raktai.length - MAX_NUOTRAUKU;
  for (let i = 0; i < perteklius; i++) await c.delete(raktai[i]);
}

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
          caches.open(VERSIJA).then((c) => c.put(e.request, kopija)).then(apkarpykTalpykla);
        }
        return atsakymas;
      }).catch(() => caches.match('./index.html'));
    })
  );
});
