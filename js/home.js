/* Home page — ported from siteJS + home skin module in
   Sources/BezzubickMCPlay/main.swift (minus the WASM loader).
   FIXes vs Swift: index page now actually renders the live stream
   (Swift only filled carousel+totals, live section stayed dead);
   local-date calendar keys; escaped titles; single wheel listener. */
import {
  BASE, store, applyTheme, nextTheme, setVisibility, fmtCount, esc,
  fetchJson, fetchData, fetchHistory, readSnapshot, localKey, setupOffline,
  applyMockFromQuery, initSkinViewer, registerSW,
} from './common.js';

const $ = (id) => document.getElementById(id);
const state = {
  theme: store.theme, lang: store.lang,
  data: { followerCounts: {}, youtubeVideos: [], liveStream: { type: 'none' } },
  links: [],
  history: { events: [] },
  cal: { year: new Date().getFullYear(), month: new Date().getMonth() },
};

const MONTHS = {
  ru: ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'],
  en: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
};
const WDAYS = { ru: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'], en: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'] };
const STR = {
  ru: { followers: 'Всего подписчиков: ', navTitle: 'Навигация', navDesc: 'Перейдите на страницу со всеми моими ссылками, соцсетями, скином и dev‑инфо.', navCta: 'Перейти к ссылкам', skinTitle: 'Мой скин Minecraft', skinDl: 'Скачать скин', videosTitle: 'Последние видео', tlTitle: 'Лента канала', expand: 'Развернуть', collapse: 'Свернуть', liveEmpty: 'Сейчас стрима нет', liveSub: 'Обычно стримы по пятницам, 17:00–19:00 МСК.', legendYt: 'YouTube', legendTw: 'Twitch', legendBoth: 'Оба', legendPlanned: 'Потенциальный', legendMissed: 'Зачёркнутые — стрима не было', twitchAlso: 'Стрим также идёт на Twitch!', twitchCta: 'Смотреть на Twitch' },
  en: { followers: 'Total Subscribers: ', navTitle: 'Navigation', navDesc: 'Go to the page with all my links, socials, skin, and dev info.', navCta: 'Go to Links', skinTitle: 'My Minecraft Skin', skinDl: 'Download Skin', videosTitle: 'Latest Videos', tlTitle: 'Channel Timeline', expand: 'Expand', collapse: 'Collapse', liveEmpty: 'No stream right now', liveSub: 'Streams are usually on Fridays, 17:00–19:00 MSK.', legendYt: 'YouTube', legendTw: 'Twitch', legendBoth: 'Both', legendPlanned: 'Planned', legendMissed: 'Struck-out — there was no stream', twitchAlso: 'Stream is also live on Twitch!', twitchCta: 'Watch on Twitch' },
};
const t = (k) => (STR[state.lang] || STR.ru)[k] || '';

function setTxt(id, val) { const e = $(id); if (e && val !== undefined) e.textContent = val; }

function updateTexts() {
  setTxt('totals', `${t('followers')}—`);
  setTxt('nav-title', t('navTitle')); setTxt('nav-desc', t('navDesc'));
  setTxt('nav-cta-text', t('navCta'));
  setTxt('skin-title', t('skinTitle')); setTxt('skin-download-text', t('skinDl'));
  setTxt('videos-title', t('videosTitle')); setTxt('timeline-title', t('tlTitle'));
  setTxt('tl-expand-text', t('expand')); setTxt('tl-collapse-text', t('collapse'));
  setTxt('live-empty-title', t('liveEmpty')); setTxt('live-empty-sub', t('liveSub'));
  setTxt('legend-yt', t('legendYt')); setTxt('legend-tw', t('legendTw'));
  setTxt('legend-both', t('legendBoth')); setTxt('legend-planned', t('legendPlanned'));
  setTxt('legend-missed', t('legendMissed'));
  setTxt('twitch-text', t('twitchAlso')); setTxt('twitch-cta', t('twitchCta'));
  document.querySelectorAll('[data-lang]').forEach((el) => {
    el.style.display = el.getAttribute('data-lang') === state.lang ? '' : 'none';
  });
  document.documentElement.lang = state.lang;
}

/* Same counter as the links page: only platforms with showCount. */
async function loadLinks() {
  try {
    const links = await fetchJson(`${BASE}/assets/links.json?t=${Date.now()}`);
    return Array.isArray(links) ? links : null;
  } catch {
    return null;
  }
}

function renderTotals() {
  let total = 0;
  const counts = state.data.followerCounts || {};
  if (state.links.length) {
    for (const l of state.links) {
      if (l.showCount && typeof counts[l.platform] === 'number') total += counts[l.platform];
    }
  } else {
    for (const v of Object.values(counts)) if (typeof v === 'number') total += v;
  }
  setTxt('totals', t('followers') + fmtCount(total));
}

function renderVideos() {
  const vids = state.data.youtubeVideos || [];
  const el = $('carousel');
  if (!el) return;
  el.innerHTML = '';
  for (const v of vids) {
    const a = document.createElement('a');
    a.href = `https://www.youtube.com/watch?v=${encodeURIComponent(v.id)}`;
    a.target = '_blank';
    a.rel = 'noopener';
    a.className = 'flex-shrink-0 w-64 rounded-2xl overflow-hidden m3-shadow-md card';
    a.innerHTML = `<img loading="eager" decoding="async" src="${esc(v.thumbnailUrl)}" alt="${esc(v.title)}" class="w-full h-36 object-cover"><div class="p-3"><p class="text-sm font-medium leading-tight">${esc(v.title)}</p></div>`;
    el.appendChild(a);
  }
}

/* FIX vs Swift: the generated index page never showed a live stream.
   Same rules as the links page: YouTube embed, Twitch notice, Twitch-only. */
function renderLive() {
  const live = state.data.liveStream || { type: 'none' };
  const has = live.type !== 'none';
  const grid = $('content-grid');
  grid?.classList.toggle('has-live', has);
  grid?.classList.toggle('no-live', !has);
  const wrap = $('live');
  const embed = $('live-embed');
  setVisibility(wrap, has);
  setVisibility($('live-empty-title'), !has);
  setVisibility($('live-empty-sub'), !has);
  if (!has) { if (embed) embed.src = 'about:blank'; return; }
  if (live.type === 'youtube' && live.id) {
    embed.src = `https://www.youtube.com/embed/${encodeURIComponent(live.id)}?autoplay=1&mute=1`;
    setVisibility($('twitch-notice'), !!live.twitchLive);
    if (live.twitchLive && $('twitch-link')) $('twitch-link').href = `https://www.twitch.tv/${encodeURIComponent(live.twitchLive.twitchChannelName)}`;
  } else if (live.type === 'twitch' && live.twitchChannelName) {
    const parent = location.hostname || 'localhost';
    embed.src = `https://player.twitch.tv/?channel=${encodeURIComponent(live.twitchChannelName)}&parent=${encodeURIComponent(parent)}&autoplay=true&mute=1`;
    setVisibility($('twitch-notice'), false);
  }
}

function renderCal() {
  const label = $('cal-label'), head = $('cal-weekdays'), grid = $('cal-grid');
  if (!label || !head || !grid) return;
  const m = MONTHS[state.lang] || MONTHS.ru, w = WDAYS[state.lang] || WDAYS.ru;
  label.textContent = `${m[state.cal.month]} ${state.cal.year}`;
  head.innerHTML = w.map((d) => `<div>${d}</div>`).join('');
  const byDate = {};
  for (const e of state.history.events || []) {
    (byDate[e.date] ||= { yt: false, tw: false, items: [] });
    if (e.platform === 'youtube') byDate[e.date].yt = true;
    if (e.platform === 'twitch') byDate[e.date].tw = true;
    byDate[e.date].items.push(e);
  }
  const first = new Date(state.cal.year, state.cal.month, 1);
  const startDow = (first.getDay() + 6) % 7;
  const days = new Date(state.cal.year, state.cal.month + 1, 0).getDate();
  const today = new Date(); today.setHours(0, 0, 0, 0);
  let htmlStr = '';
  for (let i = 0; i < startDow; i++) htmlStr += '<div></div>';
  for (let d = 1; d <= days; d++) {
    const dt = new Date(state.cal.year, state.cal.month, d);
    const isToday = dt.getTime() === today.getTime();
    const isPast = dt.getTime() < today.getTime();
    const dow = (dt.getDay() + 6) % 7;
    const cls = ['cell'];
    if (dow === 4) cls.push('fri');
    if (isToday) cls.push('today');
    const info = byDate[localKey(dt)];
    let dot = '', chips = '';
    if (info) {
      dot = info.yt && info.tw ? '<span class="dot both"></span>' : info.yt ? '<span class="dot yt"></span>' : info.tw ? '<span class="dot tw"></span>' : '';
      const yt = info.items.find((x) => x.platform === 'youtube');
      const tw = info.items.find((x) => x.platform === 'twitch');
      if (yt) chips += `<a href="${esc(yt.url)}" target="_blank" rel="noopener">YT</a>`;
      if (tw) chips += (chips ? ' · ' : '') + `<a href="${esc(tw.url)}" target="_blank" rel="noopener">TW</a>`;
    } else if (dow === 4) {
      if (isPast) cls.push('passed', 'no-stream');
      else dot = '<span class="dot planned"></span>';
    }
    htmlStr += `<div class="${cls.join(' ')}"><div>${d}</div>${dot}${chips ? `<div>${chips}</div>` : ''}</div>`;
  }
  grid.innerHTML = htmlStr;
}

function stepMonth(delta) {
  state.cal.month += delta;
  if (state.cal.month < 0) { state.cal.month = 11; state.cal.year--; }
  if (state.cal.month > 11) { state.cal.month = 0; state.cal.year++; }
  renderCal();
}

document.addEventListener('DOMContentLoaded', async () => {
  applyTheme(state.theme, $('theme-icon'));
  updateTexts();
  setupOffline();

  document.querySelectorAll('#timeline details').forEach((d) => {
    const icon = d.querySelector('.material-symbols-outlined');
    d.addEventListener('toggle', () => { if (icon) icon.style.transform = d.open ? 'rotate(180deg)' : 'rotate(0deg)'; });
  });
  $('tl-expand') && ($('tl-expand').onclick = () => document.querySelectorAll('#timeline details').forEach((d) => { d.open = true; }));
  $('tl-collapse') && ($('tl-collapse').onclick = () => document.querySelectorAll('#timeline details').forEach((d) => { d.open = false; }));

  $('theme-toggle') && ($('theme-toggle').onclick = () => { state.theme = applyTheme(nextTheme(state.theme), $('theme-icon')); });
  $('lang-toggle') && ($('lang-toggle').onclick = () => {
    state.lang = state.lang === 'ru' ? 'en' : 'ru';
    store.lang = state.lang;
    updateTexts(); renderTotals(); renderCal();
  });

  $('cal-prev') && ($('cal-prev').onclick = () => stepMonth(-1));
  $('cal-next') && ($('cal-next').onclick = () => stepMonth(1));

  const carousel = $('carousel');
  carousel?.addEventListener('wheel', (e) => {
    if (e.deltaY !== 0) { e.preventDefault(); carousel.scrollLeft += e.deltaY; }
  }, { passive: false });

  state.data = readSnapshot('data-snapshot', state.data);
  state.history = readSnapshot('history-snapshot', state.history);
  state.links = readSnapshot('links-snapshot', []);
  state.data.liveStream = applyMockFromQuery(state.data.liveStream);
  renderTotals();
  renderVideos();
  renderLive();
  renderCal();

  // Background refresh: replace snapshot with live data when it arrives.
  (async () => {
    try {
      const [links, data, history] = await Promise.all([loadLinks(), fetchData(), fetchHistory()]);
      if (Array.isArray(links) && links.length) state.links = links;
      state.data = data;
      state.data.liveStream = applyMockFromQuery(state.data.liveStream);
      state.history = history;
      renderTotals();
      renderVideos();
      renderLive();
      renderCal();
    } catch (e) { console.warn('[Refresh] failed, snapshot kept', e); }
  })();

  await initSkinViewer({
    viewerEl: $('skin-viewer'),
    canvas: $('skin-canvas'),
    controlsEl: $('skin-controls'),
    skinUrl: `${BASE}/assets/skin.png`,
    downloadBtn: $('download-skin'),
  });

  registerSW();
});
