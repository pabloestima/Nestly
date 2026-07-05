const CACHE = 'nestly-v1';
const ASSETS = ['./index.html'];

// Install: cache the app shell
self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(c => c.addAll(ASSETS))
  );
  self.skipWaiting();
});

// Activate: clean up old caches
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// Fetch: serve from cache, fall back to network
self.addEventListener('fetch', e => {
  e.respondWith(
    caches.match(e.request).then(cached => cached || fetch(e.request))
  );
});

// Background sync: check kick reminder on periodic wake-up
self.addEventListener('periodicsync', e => {
  if (e.tag === 'kick-reminder-check') {
    e.waitUntil(checkKickReminder());
  }
});

// Push notification handler (for future server-side push)
self.addEventListener('push', e => {
  const data = e.data ? e.data.json() : {};
  e.waitUntil(
    self.registration.showNotification(data.title || 'Nestly', {
      body: data.body || "Time to check in on baby's movements.",
      icon: './icon-192.png',
      badge: './icon-192.png',
      tag: 'nestly-reminder',
      renotify: true,
      vibrate: [200, 100, 200]
    })
  );
});

// Notification click: open the app
self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(list => {
      const existing = list.find(c => c.url.includes('index.html') && 'focus' in c);
      if (existing) return existing.focus();
      return clients.openWindow('./index.html');
    })
  );
});

async function checkKickReminder() {
  // Read reminder settings from IndexedDB or postMessage if needed.
  // Minimal implementation: show a reminder notification from the SW.
  const allClients = await clients.matchAll();
  // If the app is open, let the in-page JS handle it.
  if (allClients.length > 0) return;

  await self.registration.showNotification('Time to check in! 👶', {
    body: "Don't forget to log baby's movements today.",
    icon: './icon-192.png',
    tag: 'baby-kicks-reminder',
    renotify: true,
    vibrate: [200, 100, 200]
  });
}
