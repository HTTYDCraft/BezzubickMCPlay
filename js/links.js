/* Links page — ported from linksJS in Sources/BezzubickMCPlay/main.swift
   (minus the WASM loader). Config now comes from assets/links.json,
   which tools/build.py generates from Config/links.yml (MD/YML configs
   stay the source of truth). FIXes vs Swift: escaped titles/URLs,
   fetch timeout, working dev-view toggle, ?dev=1 support. */
import {
  BASE, store, applyTheme, nextTheme, setVisibility, fmtCount, esc,
  fetchJson, fetchData, setupOffline, applyMockFromQuery, initSkinViewer, registerSW,
} from './common.js';

const $ = (id) => document.getElementById(id);

const appConfig = {
  showLiveStreamSection: true, showProfileSection: true,
  showMinecraftSkinSection: true, showLinksSection: true,
  showYouTubeVideosSection: true, showSupportButton: true,
  supportUrl: 'https://www.donationalerts.com/r/bezzubickmcplay',
};
const profileConfig = {
  name_key: 'profileName', description_key: 'profileDescription',
  avatar: `${BASE}/assets/avatar.png`, minecraftSkinUrl: `${BASE}/assets/skin.png`,
};

const strings = {
  en: { recentVideosTitle: 'Recent Videos', modalTitle: 'Welcome!', modalDescription: 'Swipe right on a link card to subscribe, swipe left on YouTube links to open the latest video or a live stream.', gotItButton: 'Got it!', watchOnTwitch: 'Watch on Twitch', totalFollowers: 'Total Followers: ', minecraftTitle: 'My Minecraft Skin', downloadSkin: 'Download Skin', loading: 'Loading...', supportButton: 'Support Me', offlineMessage: 'You are offline. Data might be outdated.', devPageTitle: 'Developer Info', devLastUpdatedLabel: 'Last Data Update:', devDataJsonContentLabel: 'data.json Content:', devDebugInfoContentLabel: 'API Debug Info:', backToMainText: 'Back to Main Site', profileName: 'BezzubickMCPlay', profileDescription: 'Minecraft adventures | Streams | Creativity', avatarAlt: 'BezzubickMCPlay profile avatar', twitchStreamAlsoLive: 'Stream also live on Twitch!' },
  ru: { recentVideosTitle: 'Последние видео', modalTitle: 'Добро пожаловать!', modalDescription: 'Проведите вправо по карточке ссылки, чтобы подписаться. Проведите влево по YouTube-ссылкам, чтобы открыть последнее видео или прямой эфир.', gotItButton: 'Понятно!', watchOnTwitch: 'Смотреть на Twitch', totalFollowers: 'Всего подписчиков: ', minecraftTitle: 'Мой скин Minecraft', downloadSkin: 'Скачать скин', loading: 'Загрузка...', supportButton: 'Поддержать меня', offlineMessage: 'Вы не в сети. Данные могут быть устаревшими.', devPageTitle: 'Информация для разработчиков', devLastUpdatedLabel: 'Последнее обновление данных:', devDataJsonContentLabel: 'Содержимое data.json:', devDebugInfoContentLabel: 'Отладочная информация API:', backToMainText: 'Назад к сайту', profileName: 'BezzubickMCPlay', profileDescription: 'Приключения в Minecraft | Стримы | Творчество', avatarAlt: 'Аватар профиля BezzubickMCPlay', twitchStreamAlsoLive: 'Стрим также идёт на Twitch!' },
};

const state = {
  theme: store.theme, lang: store.lang,
  data: { followerCounts: {}, youtubeVideos: [], liveStream: { type: 'none' } },
  links: [],
  devOpen: new URLSearchParams(location.search).get('dev') === '1',
};

async function loadLinks() {
  try {
    state.links = await fetchJson(`${BASE}/assets/links.json?t=${Date.now()}`);
  } catch (e) {
    console.warn('[Links] links.json missing (run tools/build.py)', e);
    state.links = [];
  }
}

function updateLanguage() {
  const s = strings[state.lang];
  setTxt('recent-videos-title', s.recentVideosTitle);
  setTxt('minecraft-title', s.minecraftTitle);
  setTxt('download-skin-text', s.downloadSkin);
  setTxt('support-button-text', s.supportButton);
  setTxt('offline-message', s.offlineMessage);
  setTxt('twitch-link-text', s.watchOnTwitch);
  setTxt('twitch-message', s.twitchStreamAlsoLive);
  setTxt('modal-title', s.modalTitle);
  setTxt('modal-description', s.modalDescription);
  setTxt('modal-close', s.gotItButton);
  setTxt('dev-title', s.devPageTitle);
  setTxt('dev-last-updated-label', s.devLastUpdatedLabel);
  setTxt('dev-data-json-content-label', s.devDataJsonContentLabel);
  setTxt('dev-debug-info-content-label', s.devDebugInfoContentLabel);
  setTxt('back-to-main-text', s.backToMainText);
  const pn = $('profile-name'); if (pn) pn.textContent = s[profileConfig.name_key];
  const pd = $('profile-description'); if (pd) pd.textContent = s[profileConfig.description_key];
  const av = $('avatar'); if (av) av.alt = s.avatarAlt;
  document.documentElement.lang = state.lang;
  renderLinks();
  renderTotal();
}
function setTxt(id, v) { const e = $(id); if (e && v !== undefined) e.textContent = v; }

function renderProfile() {
  setVisibility($('profile-section'), appConfig.showProfileSection);
  const av = $('avatar');
  if (appConfig.showProfileSection && av) av.src = profileConfig.avatar;
}

function renderTotal() {
  const s = strings[state.lang];
  let total = 0;
  for (const l of state.links) {
    if (l.showCount) {
      const c = state.data.followerCounts?.[l.platform];
      if (typeof c === 'number') total += c;
    }
  }
  setTxt('total-followers', `${s.totalFollowers} ${fmtCount(total, s.loading)}`);
}

function renderLinks() {
  const box = $('links-section');
  setVisibility(box, appConfig.showLinksSection);
  if (!appConfig.showLinksSection || !box) return;
  box.innerHTML = '';
  const sorted = [...state.links].sort((a, b) => a.order - b.order);
  for (const link of sorted) {
    const a = document.createElement('a');
    a.href = link.url;
    a.target = '_blank';
    a.rel = 'noopener noreferrer';
    a.draggable = false;
    a.className = 'card relative flex items-center justify-between p-4 rounded-2xl m3-shadow-md swipe-target cursor-pointer';
    a.setAttribute('data-link-url', link.url);
    const count = state.data.followerCounts?.[link.platform];
    const label = state.lang === 'en' ? (link.label_en || link.label) : link.label;
    a.innerHTML = `<div class="flex items-center select-none"><span class="material-symbols-outlined icon-large">${esc(link.icon || 'link')}</span><div><span class="block text-lg font-medium">${esc(label)}</span>${link.showCount ? `<span class="text-sm text-gray-400 mr-2 follower-count-display">${esc(fmtCount(count, strings[state.lang].loading))}</span>` : ''}</div></div>`;
    box.appendChild(a);
  }
  initSwipeGestures();
}

function renderVideos() {
  const videos = state.data.youtubeVideos || [];
  setVisibility($('youtube-videos-section'), appConfig.showYouTubeVideosSection && videos.length > 0);
  const car = $('video-carousel');
  if (!appConfig.showYouTubeVideosSection || !videos.length || !car) return;
  car.innerHTML = '';
  for (const v of videos) {
    const card = document.createElement('a');
    card.href = `https://www.youtube.com/watch?v=${encodeURIComponent(v.id)}`;
    card.target = '_blank';
    card.rel = 'noopener';
    card.className = 'flex-shrink-0 w-64 rounded-2xl overflow-hidden m3-shadow-md card';
    card.innerHTML = `<img loading="lazy" decoding="async" src="${esc(v.thumbnailUrl)}" alt="${esc(v.title)}" class="w-full h-36 object-cover"><div class="p-3"><p class="text-sm font-medium leading-tight">${esc(v.title)}</p></div>`;
    car.appendChild(card);
  }
}

function renderLive() {
  const info = state.data.liveStream;
  const has = appConfig.showLiveStreamSection && info && info.type !== 'none';
  setVisibility($('live-stream-section'), has);
  const grid = $('content-grid');
  grid?.classList.toggle('grid-has-live', has);
  grid?.classList.toggle('grid-no-live', !has);
  if (!has) return;
  const embed = $('live-embed');
  if (info.type === 'youtube' && info.id) {
    embed.src = `https://www.youtube.com/embed/${encodeURIComponent(info.id)}?autoplay=1&mute=1`;
    setVisibility($('twitch-notification'), !!info.twitchLive);
    if (info.twitchLive && $('twitch-link')) $('twitch-link').href = `https://www.twitch.tv/${encodeURIComponent(info.twitchLive.twitchChannelName)}`;
  } else if (info.type === 'twitch' && info.twitchChannelName) {
    const parent = location.hostname || 'localhost';
    embed.src = `https://player.twitch.tv/?channel=${encodeURIComponent(info.twitchChannelName)}&parent=${encodeURIComponent(parent)}&autoplay=true&mute=1`;
    setVisibility($('twitch-notification'), false);
  }
}

function initSwipeGestures() {
  document.querySelectorAll('.swipe-target').forEach((card) => {
    let sx = 0, sy = 0, cx = 0, cy = 0, down = false, active = false, suppress = false;
    const data = state.links.find((l) => l.url === card.getAttribute('data-link-url'));
    if (!data) return;
    const start = (e) => {
      down = true; active = false;
      sx = e.touches ? e.touches[0].clientX : e.clientX;
      sy = e.touches ? e.touches[0].clientY : e.clientY;
      card.style.transition = 'none';
    };
    const move = (e) => {
      if (!down) return;
      cx = e.touches ? e.touches[0].clientX : e.clientX;
      cy = e.touches ? e.touches[0].clientY : e.clientY;
      const dx = cx - sx, dy = cy - sy;
      if (!active && Math.abs(dx) > 20 && Math.abs(dx) > Math.abs(dy)) { active = true; e.preventDefault(); }
      if (active) {
        e.preventDefault();
        card.style.transform = `translateX(${dx}px)`;
        card.classList.toggle('swiping-right', dx > 0);
        card.classList.toggle('swiping-left', dx < 0);
      }
    };
    const end = () => {
      if (!down) return;
      down = false;
      card.style.transition = 'transform .2s ease, background-color .3s ease, box-shadow .2s ease';
      const dx = cx - sx;
      if (active && Math.abs(dx) > card.offsetWidth * 0.25) {
        if (dx > 0) window.open(data.subscribeUrl || data.url, '_blank', 'noopener');
        else if (data.platform === 'youtube') {
          const live = state.data.liveStream;
          if (live?.type === 'youtube' && live.id) window.open(`https://www.youtube.com/watch?v=${encodeURIComponent(live.id)}`, '_blank', 'noopener');
          else if (state.data.youtubeVideos?.length) window.open(`https://www.youtube.com/watch?v=${encodeURIComponent(state.data.youtubeVideos[0].id)}`, '_blank', 'noopener');
          else window.open(data.url, '_blank', 'noopener');
        } else window.open(data.url, '_blank', 'noopener');
      }
      card.style.transform = 'translateX(0)';
      card.classList.remove('swiping-left', 'swiping-right');
      if (active) { suppress = true; setTimeout(() => { suppress = false; }, 0); }
      active = false;
    };
    card.addEventListener('mousedown', start);
    card.addEventListener('mousemove', move);
    card.addEventListener('mouseup', end);
    card.addEventListener('mouseleave', end);
    card.addEventListener('touchstart', start, { passive: true });
    card.addEventListener('touchmove', move, { passive: false });
    card.addEventListener('touchend', end);
    card.addEventListener('click', (e) => { if (suppress) { e.preventDefault(); e.stopPropagation(); } }, true);
  });
}

function renderDev() {
  setTxt('dev-last-updated', state.data.lastUpdated || '—');
  const dj = $('dev-data-json-content');
  if (dj) dj.textContent = JSON.stringify(state.data, null, 2);
  const db = $('dev-debug-info-content');
  if (db) db.textContent = JSON.stringify(state.data.debugInfo || {}, null, 2);
}

function setDev(open) {
  state.devOpen = open;
  setVisibility($('main-view'), !open);
  setVisibility($('dev-view'), open);
  if (open) renderDev();
}

document.addEventListener('DOMContentLoaded', async () => {
  applyTheme(state.theme, $('theme-icon'));
  setupOffline();

  setDev(state.devOpen);
  $('dev-toggle')?.classList.remove('hidden');
  $('dev-toggle')?.addEventListener('click', () => setDev(!state.devOpen));
  $('back-to-main-button')?.addEventListener('click', (e) => { e.preventDefault(); setDev(false); });

  $('theme-toggle')?.addEventListener('click', () => { state.theme = applyTheme(nextTheme(state.theme), $('theme-icon')); });
  $('language-toggle')?.addEventListener('click', () => {
    state.lang = state.lang === 'en' ? 'ru' : 'en';
    store.lang = state.lang;
    updateLanguage();
  });
  $('video-carousel')?.addEventListener('wheel', (e) => {
    const car = $('video-carousel');
    if (e.deltaY !== 0) { e.preventDefault(); car.scrollLeft += e.deltaY; }
  }, { passive: false });

  const modal = $('first-visit-modal');
  if (modal && !localStorage.getItem('visited_modal')) {
    modal.classList.add('active');
    $('modal-close') && ($('modal-close').onclick = () => {
      modal.classList.remove('active');
      localStorage.setItem('visited_modal', 'true');
    });
  }

  await loadLinks();
  state.data = await fetchData();
  state.data.liveStream = applyMockFromQuery(state.data.liveStream);

  renderProfile();
  updateLanguage();
  renderVideos();
  renderLive();
  if (appConfig.showSupportButton && $('support-button')) $('support-button').href = appConfig.supportUrl;
  setVisibility($('support-section'), appConfig.showSupportButton);
  renderDev();

  // Swift inserted animation controls above the download button; keep that.
  let controlsEl = null;
  if ($('minecraft-block') && $('download-skin-button')) {
    controlsEl = document.createElement('div');
    controlsEl.id = 'skin-animation-controls';
    controlsEl.className = 'skin-controls';
    controlsEl.setAttribute('role', 'group');
    controlsEl.setAttribute('aria-label', 'Skin animation');
    $('minecraft-block').insertBefore(controlsEl, $('download-skin-button').parentElement);
  }
  await initSkinViewer({
    viewerEl: $('skin-viewer-container'),
    canvas: $('skin-canvas'),
    controlsEl,
    skinUrl: profileConfig.minecraftSkinUrl,
    downloadBtn: $('download-skin-button'),
  });

  registerSW();
});
