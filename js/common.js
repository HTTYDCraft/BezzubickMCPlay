/* Shared helpers — ported from Sources/BezzubickMCPlay/main.swift (siteJS/linksJS).
   FIX vs Swift: BASE is auto-detected (Swift hardcoded '/BezzubickMCPlay',
   which broke custom domains and local preview). */
export const BASE = (() => {
  if (window.__BASE__ !== undefined) return window.__BASE__;
  const s = document.currentScript?.src || '';
  const m = s.match(/^(.*)\/js\/(common|home|links)\.js/);
  return m ? m[1] : '';
})();

export const THEMES = ['dark', 'light', 'glass-dark', 'glass-light'];

const params = new URLSearchParams(location.search);

/* Platform theme policy: everywhere glass, on Android Material You
   (dark/light). Toggle cycles only the platform set. */
/* Platform theme policy: Material You only in Chrome on Android
   (Fennec/Firefox/Opera keep glass); everywhere else glass. */
export function isMaterialPlatform() {
  const ua = navigator.userAgent || '';
  const isAndroid = /Android/i.test(ua) || navigator.userAgentData?.platform === 'Android';
  if (!isAndroid) return false;
  if (/Firefox|Fennec|OPR\/|EdgA\//i.test(ua)) return false;
  return /Chrome\/\d+|Chromium\/\d+/i.test(ua);
}

export function themeSet() {
  return isMaterialPlatform() ? ['dark', 'light'] : ['glass-dark', 'glass-light'];
}

function schemeIsLight() {
  return !!matchMedia?.('(prefers-color-scheme: light)').matches;
}

function coerceTheme(t) {
  const set = themeSet();
  if (set.includes(t)) return t;
  if (isMaterialPlatform()) return t === 'glass-light' || t === 'light' ? 'light' : 'dark';
  return t === 'light' || t === 'glass-light' ? 'glass-light' : 'glass-dark';
}

function lsGet(k) { try { return localStorage.getItem(k); } catch { return null; } }
function lsSet(k, v) { try { localStorage.setItem(k, v); } catch { /* private mode */ } }

export const store = {
  get theme() {
    // Deep link ?theme= / ?debugTheme= opens exactly that theme and remembers it.
    const p = params.get('debugTheme') || params.get('theme');
    if (p && THEMES.includes(p)) { lsSet('theme', p); return p; }
    const s = lsGet('theme');
    if (s && THEMES.includes(s)) return s;
    const set = themeSet();
    return schemeIsLight() ? set[1] : set[0];
  },
  set theme(t) { lsSet('theme', t); },
  get lang() {
    // Deep link ?lang= wins once and is remembered; otherwise stored
    // choice wins; first visit falls back to the browser language.
    const p = params.get('lang');
    if (p === 'ru' || p === 'en') { lsSet('lang', p); return p; }
    const s = lsGet('lang');
    if (s === 'ru' || s === 'en') return s;
    return navigator.language?.startsWith('ru') ? 'ru' : 'en';
  },
  set lang(l) { lsSet('lang', l); },
};

export function applyTheme(theme, iconEl) {
  if (!THEMES.includes(theme)) theme = themeSet()[0];
  const cls = theme === 'dark' ? 'dark-theme' : theme === 'light' ? 'light-theme'
    : theme === 'glass-dark' ? 'glass-dark' : 'glass-light';
  document.body.classList.remove('dark-theme', 'light-theme', 'glass-dark', 'glass-light');
  document.body.classList.add(cls);
  store.theme = theme;
  const bg = theme === 'glass-light' ? '#f5f0ff' : theme === 'light' ? '#ffffff' : '#000000';
  // NOTE: no background on <html> — body background propagates to the canvas
  // and covers overscroll. Toolbar color goes via theme-color meta.
  document.querySelector('meta[name="theme-color"]')?.setAttribute('content', bg);
  document.documentElement.style.colorScheme = theme === 'dark' || theme === 'glass-dark' ? 'dark' : 'light';
  if (iconEl) iconEl.textContent = theme === 'dark' ? 'light_mode' : theme === 'light' ? 'dark_mode' : theme === 'glass-dark' ? 'light_mode' : 'dark_mode';
  return theme;
}

export function nextTheme(t) {
  const set = themeSet();
  return set[(set.indexOf(coerceTheme(t)) + 1 + set.length) % set.length];
}

export function setVisibility(el, visible) { if (el) el.classList.toggle('hidden', !visible); }

export function fmtCount(n, loading = '—') {
  if (n == null || Number.isNaN(n)) return loading;
  if (n >= 1e6) return (n / 1e6).toFixed(1).replace(/\.0$/, '') + 'M';
  if (n >= 1e3) return (n / 1e3).toFixed(1).replace(/\.0$/, '') + 'K';
  return String(n);
}

export function esc(s) {
  return String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

/* FIX vs Swift: fetch without timeout could hang offline banner state. */
export async function fetchJson(url, timeoutMs = 12000) {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(url, { cache: 'no-store', signal: ctrl.signal });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } finally {
    clearTimeout(t);
  }
}

/* Build-time snapshot baked into the HTML (tools/build.py): instant first
   paint without waiting for the network; JS refreshes after. */
export function readSnapshot(id, fallback) {
  try {
    const el = document.getElementById(id);
    if (!el) return fallback;
    const v = JSON.parse(el.textContent);
    return v ?? fallback;
  } catch {
    return fallback;
  }
}

export async function fetchData() {
  try {
    return await fetchJson(`${BASE}/data.json?t=${Date.now()}`);
  } catch (e) {
    console.warn('[Data] fetch failed, offline?', e);
    return { followerCounts: {}, youtubeVideos: [], liveStream: { type: 'none' }, debugInfo: { fetch_error: String(e) } };
  }
}

export async function fetchHistory() {
  try {
    return await fetchJson(`${BASE}/streams_history.json?t=${Date.now()}`);
  } catch {
    return { events: [] };
  }
}

/* Local-date key. FIX vs Swift: Swift used toISOString().slice(0,10) (UTC),
   which shifted MSK evening streams to the wrong calendar day. */
export function localKey(d) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

export function setupOffline(id = 'offline-warning') {
  const w = document.getElementById(id);
  if (!w) return;
  const upd = () => setVisibility(w, !navigator.onLine);
  addEventListener('online', upd);
  addEventListener('offline', upd);
  upd();
}

export function applyMockFromQuery(live) {
  const s = new URLSearchParams(location.search).get('mockLive');
  if (!s) return live;
  if (s === 'none') return { type: 'none' };
  const [kind, a, b] = s.split(':');
  if (kind === 'both') return { type: 'youtube', id: a || 'e7K5ijK2VOo', title: 'Mock YT', twitchLive: { type: 'twitch', id: 'mock', title: 'Mock TW', twitchChannelName: b || 'monstercat' } };
  if (kind === 'youtube') return { type: 'youtube', id: a || 'e7K5ijK2VOo', title: 'Mock YT' };
  if (kind === 'twitch') return { type: 'twitch', id: 'mock', title: 'Mock TW', twitchChannelName: a || 'monstercat' };
  return live;
}

/* 3D skin viewer (skinview3d UMD from js/vendor/). Falls back to PNG. */
export async function initSkinViewer({ viewerEl, canvas, controlsEl, skinUrl, downloadBtn }) {
  if (!viewerEl || !canvas) return;
  const skinview3d = window.skinview3d || null;
  let viewer = null;
  let active = 'stop';
  const fallback = () => {
    try { viewer?.dispose?.(); } catch { /* noop */ }
    viewer = null;
    viewerEl.innerHTML = `<img loading="eager" decoding="async" src="${esc(skinUrl)}" alt="Minecraft skin" class="w-full h-full object-contain" />`;
    if (controlsEl) controlsEl.innerHTML = '';
  };
  const syncButtons = () => {
    controlsEl?.querySelectorAll('.mini-button').forEach((b) => {
      const on = b.getAttribute('data-anim') === active;
      b.classList.toggle('active', on);
      b.setAttribute('aria-pressed', on ? 'true' : 'false');
    });
  };
  const setAnim = (key) => {
    if (!viewer || !skinview3d) return;
    try {
      let anim = null;
      if (key === 'idle' && skinview3d.IdleAnimation) anim = new skinview3d.IdleAnimation();
      else if (key === 'walk' && skinview3d.WalkingAnimation) anim = new skinview3d.WalkingAnimation();
      else if (key === 'run' && skinview3d.RunningAnimation) anim = new skinview3d.RunningAnimation();
      else if (key === 'rotate' && skinview3d.RotatingAnimation) anim = new skinview3d.RotatingAnimation();
      viewer.animation = anim;
      active = key;
      syncButtons();
    } catch (e) { console.warn('[Skin] anim failed', key, e); }
  };
  await new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)));
  if (!skinview3d) { fallback(); return; }
  try {
    const w = Math.max(1, viewerEl.offsetWidth || viewerEl.clientWidth || 320);
    const h = Math.max(1, viewerEl.offsetHeight || viewerEl.clientHeight || 320);
    viewer = new skinview3d.SkinViewer({ canvas, width: w, height: h });
    await viewer.loadSkin(skinUrl);
    if (skinview3d.IdleAnimation) { viewer.animation = new skinview3d.IdleAnimation(); active = 'idle'; }
    else if (skinview3d.WalkingAnimation) { viewer.animation = new skinview3d.WalkingAnimation(); active = 'walk'; }
    try {
      const controls = skinview3d.createOrbitControls(viewer);
      if (controls) { controls.enablePan = false; controls.enableZoom = true; controls.target?.set?.(0, 17, 0); controls.update?.(); }
    } catch { /* orbit controls optional */ }
    if (controlsEl) {
      controlsEl.innerHTML = '';
      const opts = [
        { key: 'idle', icon: 'accessibility', ok: !!skinview3d.IdleAnimation },
        { key: 'walk', icon: 'directions_walk', ok: !!skinview3d.WalkingAnimation },
        { key: 'run', icon: 'directions_run', ok: !!skinview3d.RunningAnimation },
        { key: 'rotate', icon: 'autorenew', ok: !!skinview3d.RotatingAnimation },
        { key: 'stop', icon: 'stop_circle', ok: true },
      ];
      for (const o of opts) {
        if (!o.ok) continue;
        const b = document.createElement('button');
        b.type = 'button';
        b.className = 'mini-button';
        b.setAttribute('data-anim', o.key);
        b.setAttribute('aria-label', o.key);
        b.innerHTML = `<span class="material-symbols-outlined mini-icon" aria-hidden="true">${o.icon}</span>`;
        b.addEventListener('click', () => setAnim(o.key));
        controlsEl.appendChild(b);
      }
      syncButtons();
    }
    new ResizeObserver(() => {
      if (!viewer) return;
      viewer.setSize(Math.max(1, viewerEl.offsetWidth || 320), Math.max(1, viewerEl.offsetHeight || 320));
    }).observe(viewerEl);
  } catch (e) {
    console.error('[Skin] init failed, PNG fallback', e);
    fallback();
  }
  downloadBtn?.addEventListener('click', async (ev) => {
    ev.preventDefault();
    try {
      const url = new URL(skinUrl, location.href).toString();
      const res = await fetch(url, { cache: 'no-store' });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const blob = await res.blob();
      const blobUrl = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = blobUrl;
      a.download = 'minecraft_skin.png';
      document.body.appendChild(a);
      a.click();
      a.remove();
      setTimeout(() => URL.revokeObjectURL(blobUrl), 1000);
    } catch {
      window.open(new URL(skinUrl, location.href).toString(), '_blank', 'noopener');
    }
  });
}

export function registerSW() {
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register(`${BASE}/sw.js`).catch((e) => console.warn('SW registration failed', e));
  }
}

/* Pause the ambient drift while the user scrolls (see CSS
   body.is-scrolling). Passive listener, class toggles only. */
let scrollTimer = 0;
addEventListener('scroll', () => {
  document.body.classList.add('is-scrolling');
  clearTimeout(scrollTimer);
  scrollTimer = setTimeout(() => document.body.classList.remove('is-scrolling'), 250);
}, { passive: true });
