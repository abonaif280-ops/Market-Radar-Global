/* أداة الجرد — تشغيل الواجهة عند انقطاع الإنترنت */
const C='jard-shell-v1';
self.addEventListener('install',e=>{self.skipWaiting();e.waitUntil(caches.open(C).then(c=>fetch('/',{credentials:'same-origin',cache:'no-store'}).then(r=>{if(r.ok&&!r.redirected)return c.put('/',r);}).catch(()=>{})));});
self.addEventListener('message',e=>{if(e.data==='refresh')caches.open(C).then(c=>fetch('/',{credentials:'same-origin',cache:'no-store'}).then(r=>{if(r.ok&&!r.redirected)return c.put('/',r);})).catch(()=>{});});
self.addEventListener('activate',e=>e.waitUntil(self.clients.claim()));
self.addEventListener('fetch',e=>{
  const req=e.request,u=new URL(req.url);
  if(req.method!=='GET'||u.origin!==location.origin||u.pathname.startsWith('/api/'))return;
  if(req.mode==='navigate'&&u.pathname==='/'){
    e.respondWith(fetch(req).then(r=>{
      if(r.ok&&!r.redirected){const cp=r.clone();caches.open(C).then(c=>c.put('/',cp));}
      return r;
    }).catch(()=>caches.open(C).then(c=>c.match('/')).then(r=>r||Response.error())));
    return;
  }
  if(/\/(icon-\d+\.png|manifest\.json)$/.test(u.pathname)){
    e.respondWith(caches.open(C).then(c=>c.match(req).then(h=>h||fetch(req).then(r=>{if(r.ok)c.put(req,r.clone());return r;}))));
  }
});
