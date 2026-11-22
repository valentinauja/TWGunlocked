const CACHE='twg27unlocked-v5';
const CORE=['./','./index.html','./admin.html','./manifest.webmanifest','./icon.svg'];
self.addEventListener('install',e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(CORE)).then(()=>self.skipWaiting())));
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',e=>{const u=new URL(e.request.url);if(e.request.method!=='GET'||u.origin!==self.location.origin)return;e.respondWith(fetch(e.request).then(r=>{if(r&&r.ok&&(u.pathname.endsWith('.html')||u.pathname.endsWith('.css')||u.pathname.endsWith('.js')||u.pathname.endsWith('.svg')||u.pathname.endsWith('.webmanifest'))){const c=r.clone();caches.open(CACHE).then(x=>x.put(e.request,c))}return r}).catch(()=>caches.match(e.request).then(c=>c||caches.match('./index.html'))))});
