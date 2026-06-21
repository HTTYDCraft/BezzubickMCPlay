// Финал: CSS Grid управляет порядком. JS только переключает состояние сетки (есть лайв/нет лайва).
// Профиль всегда сверху. Мобильный: live → links → skin. Десктоп: links | live / links | skin.
// Скин: Idle по умолчанию. Иконки в карточках — gap, в кнопках — gap.

import * as skinview3d from 'https://cdn.jsdelivr.net/npm/skinview3d@3.4.1/+esm';
import { appConfig, profileConfig, linksConfig } from '../config.js';
import { strings } from '../strings.js';

/** @typedef {{type:'none'|'youtube'|'twitch', id?:string, title?:string, youtubeChannelId?:string, twitchChannelName?:string, twitchLive?:any}} LiveStreamInfo */
/** @typedef {{id:string, title:string, thumbnailUrl:string}} YouTubeVideo */
/** @typedef {{followerCounts:Record<string,number>, youtubeVideos:YouTubeVideo[], liveStream:LiveStreamInfo, lastUpdated?:string, debugInfo?:any}} AppData */

const DOM = {
    contentGrid: document.getElementById('content-grid'),

    offlineWarning: document.getElementById('offline-warning'),
    offlineMessage: document.getElementById('offline-message'),

    liveStreamSection: document.getElementById('live-stream-section'),
    liveEmbed: document.getElementById('live-embed'),
    twitchNotification: document.getElementById('twitch-notification'),
    twitchMessage: document.getElementById('twitch-message'),
    twitchLink: document.getElementById('twitch-link'),
    twitchLinkText: document.getElementById('twitch-link-text'),

    profileSection: document.getElementById('profile-section'),
    avatar: document.getElementById('avatar'),
    profileName: document.getElementById('profile-name'),
    profileDescription: document.getElementById('profile-description'),
    totalFollowers: document.getElementById('total-followers'),

    linksSection: document.getElementById('links-section'),
    supportSection: document.getElementById('support-section'),
    supportButton: document.getElementById('support-button'),
    supportButtonText: document.getElementById('support-button-text'),

    minecraftBlock: document.getElementById('minecraft-block'),
    minecraftTitle: document.getElementById('minecraft-title'),
    skinViewerContainer: document.getElementById('skin-viewer-container'),
    skinCanvas: document.getElementById('skin-canvas'),
    downloadSkinButton: document.getElementById('download-skin-button'),
    downloadSkinText: document.getElementById('download-skin-text'),

    youtubeVideosSection: document.getElementById('youtube-videos-section'),
    recentVideosTitle: document.getElementById('recent-videos-title'),
    videoCarousel: document.getElementById('video-carousel'),

    themeToggle: document.getElementById('theme-toggle'),
    themeIcon: document.getElementById('theme-icon'),
    languageToggle: document.getElementById('language-toggle'),
    devToggle: document.getElementById('dev-toggle'),
    backToMainButton: document.getElementById('back-to-main-button'),
    devTitle: document.getElementById('dev-title'),
    devLastUpdatedLabel: document.getElementById('dev-last-updated-label'),
    devLastUpdated: document.getElementById('dev-last-updated'),
    devDataJsonContentLabel: document.getElementById('dev-data-json-content-label'),
    devDataJsonContent: document.getElementById('dev-data-json-content'),
    devDebugInfoContentLabel: document.getElementById('dev-debug-info-content-label'),
    devDebugInfoContent: document.getElementById('dev-debug-info-content'),
    backToMainText: document.getElementById('back-to-main-text'),

    firstVisitModal: document.getElementById('first-visit-modal'),
    modalTitle: document.getElementById('modal-title'),
    modalDescription: document.getElementById('modal-description'),
    modalCloseBtn: document.getElementById('modal-close'),
};

const state = {
    theme: localStorage.getItem('theme') || 'dark',
    lang: localStorage.getItem('lang') || (navigator.language.startsWith('ru') ? 'ru' : 'en'),
    data /** @type {AppData} */: { followerCounts: {}, youtubeVideos: [], liveStream: { type: 'none' } },
    skinViewerInstance /** @type {skinview3d.SkinViewer|null} */: null,
    skinControlsEl: /** @type {HTMLElement|null} */ (null),
    currentAnimKey: /** @type {'idle'|'walk'|'run'|'rotate'|'stop'} */ ('idle')
};

/* Utils */
function setVisibility(el, visible) { if (!el) return; el.classList.toggle('hidden', !visible); }
function applyTheme(theme) {
    document.body.classList.remove('dark-theme', 'light-theme');
    document.body.classList.add(`${theme}-theme`);
    localStorage.setItem('theme', theme);
    if (DOM.themeIcon) DOM.themeIcon.textContent = theme === 'dark' ? 'light_mode' : 'dark_mode';
}
function formatCount(num) {
    if (num === null || num === undefined || isNaN(num)) return strings[state.lang].loading;
    if (num >= 1_000_000) return (num / 1_000_000).toFixed(1).replace(/\.0$/, '') + 'M';
    if (num >= 1_000) return (num / 1_000).toFixed(1).replace(/\.0$/, '') + 'K';
    return num.toString();
}
async function fetchAppData() {
    const url = `${appConfig.dataUrl || '../data.json'}?t=${Date.now()}`;
    try {
        const res = await fetch(url, { cache: 'no-store' });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return await res.json();
    } catch (e) {
        console.warn('[Data Fetch] Fallback -> ../data.json', e);
        try {
            const res2 = await fetch(`../data.json?t=${Date.now()}`, { cache: 'no-store' });
            if (res2.ok) return await res2.json();
        } catch {}
        return { followerCounts: {}, youtubeVideos: [], liveStream: { type: 'none' }, debugInfo: { fetch_error: String(e) } };
    }
}

/* Сетка: переключаем классы по наличию live */
function updateGridLiveState() {
    const hasLive = appConfig.showLiveStreamSection && state.data.liveStream && state.data.liveStream.type !== 'none';
    if (!DOM.contentGrid) return;
    DOM.contentGrid.classList.toggle('grid-has-live', hasLive);
    DOM.contentGrid.classList.toggle('grid-no-live', !hasLive);
}

/* i18n + renders */
function updateLanguage() {
    const t = strings[state.lang];
    if (DOM.recentVideosTitle) DOM.recentVideosTitle.textContent = t.recentVideosTitle;
    if (DOM.minecraftTitle) DOM.minecraftTitle.textContent = t.minecraftTitle;
    if (DOM.downloadSkinText) DOM.downloadSkinText.textContent = t.downloadSkin;
    if (DOM.supportButtonText) DOM.supportButtonText.textContent = t.supportButton;
    if (DOM.offlineMessage) DOM.offlineMessage.textContent = t.offlineMessage;
    if (DOM.twitchLinkText) DOM.twitchLinkText.textContent = t.watchOnTwitch;
    if (DOM.twitchMessage) DOM.twitchMessage.textContent = t.twitchStreamAlsoLive;
    if (DOM.modalTitle) DOM.modalTitle.textContent = t.modalTitle;
    if (DOM.modalDescription) DOM.modalDescription.textContent = t.modalDescription;
    if (DOM.modalCloseBtn) DOM.modalCloseBtn.textContent = t.gotItButton;
    if (DOM.devTitle) DOM.devTitle.textContent = t.devPageTitle;
    if (DOM.devLastUpdatedLabel) DOM.devLastUpdatedLabel.textContent = t.devLastUpdatedLabel;
    if (DOM.devDataJsonContentLabel) DOM.devDataJsonContentLabel.textContent = t.devDataJsonContentLabel;
    if (DOM.devDebugInfoContentLabel) DOM.devDebugInfoContentLabel.textContent = t.devDebugInfoContentLabel;
    if (DOM.backToMainText) DOM.backToMainText.textContent = t.backToMainText;
    if (DOM.profileName) DOM.profileName.textContent = t[profileConfig.name_key];
    if (DOM.profileDescription) DOM.profileDescription.textContent = t[profileConfig.description_key];
    if (DOM.avatar) DOM.avatar.alt = t.avatarAlt;

    renderLinksSection(linksConfig);
    calculateAndDisplayTotalFollowers();
}
function renderProfileSection() {
    setVisibility(DOM.profileSection, appConfig.showProfileSection);
    if (appConfig.showProfileSection && DOM.avatar) DOM.avatar.src = profileConfig.avatar;
}
function calculateAndDisplayTotalFollowers() {
    const t = strings[state.lang];
    let total = 0;
    for (const link of linksConfig) {
        if (link.isSocial && link.showSubscriberCount && link.active) {
            const c = state.data.followerCounts ? state.data.followerCounts[link.platformId] : 0;
            if (typeof c === 'number') total += c;
        }
    }
    if (DOM.totalFollowers) DOM.totalFollowers.textContent = `${t.totalFollowers} ${formatCount(total)}`;
}
function renderLinksSection(links) {
    setVisibility(DOM.linksSection, appConfig.showLinksSection);
    if (!appConfig.showLinksSection || !DOM.linksSection) return;
    DOM.linksSection.innerHTML = '';
    const sortedLinks = links.filter(l => l.active).sort((a, b) => a.order - b.order);
    for (const link of sortedLinks) {
        const a = document.createElement('a');
        a.href = link.url;
        a.target = '_blank';
        a.rel = 'noopener noreferrer';
        a.draggable = false;
        a.className = `card relative flex items-center justify-between p-4 rounded-2xl m3-shadow-md ${link.isSocial ? 'swipe-target' : ''} cursor-pointer`;
        a.setAttribute('data-link-id', link.label_key);

        const count = state.data.followerCounts ? state.data.followerCounts[link.platformId] : undefined;
        const showCount = link.isSocial && link.showSubscriberCount;
        const iconHtml = link.customIconUrl
            ? `<img src="${link.customIconUrl}" alt="" class="custom-icon-image">`
            : `<span class="material-symbols-outlined icon-large">${link.icon || 'link'}</span>`;

        a.innerHTML = `
      <div class="flex items-center select-none">
        ${iconHtml}
        <div>
          <span class="block text-lg font-medium">${strings[state.lang][link.label_key] || link.label_key}</span>
          ${showCount ? `<span class="text-sm text-gray-400 mr-2 follower-count-display">${formatCount(count)}</span>` : ''}
        </div>
      </div>
    `;
        DOM.linksSection.appendChild(a);
    }
    initSwipeGestures();
}
function renderYouTubeVideosSection() {
    const videos = state.data.youtubeVideos || [];
    setVisibility(DOM.youtubeVideosSection, appConfig.showYouTubeVideosSection && videos.length > 0);
    if (!appConfig.showYouTubeVideosSection || videos.length === 0 || !DOM.videoCarousel) return;
    DOM.videoCarousel.innerHTML = '';
    for (const v of videos) {
        const card = document.createElement('a');
        card.href = `https://www.youtube.com/watch?v=${v.id}`;
        card.target = '_blank';
        card.className = 'flex-shrink-0 w-64 rounded-2xl overflow-hidden m3-shadow-md card';
        card.innerHTML = `
      <img src="${v.thumbnailUrl}" alt="${v.title}" class="w-full h-36 object-cover">
      <div class="p-3"><p class="text-sm font-medium leading-tight">${v.title}</p></div>
    `;
        DOM.videoCarousel.appendChild(card);
    }
    DOM.videoCarousel.addEventListener('wheel', (event) => {
        if (event.deltaY !== 0) { event.preventDefault(); DOM.videoCarousel.scrollLeft += event.deltaY; }
    }, { passive: false });
}
function renderLiveStream() {
    const info = state.data.liveStream;
    const has = appConfig.showLiveStreamSection && info && info.type !== 'none';
    setVisibility(DOM.liveStreamSection, has);
    if (!has || !DOM.liveEmbed) { updateGridLiveState(); return; }

    if (info.type === 'youtube' && info.id) {
        DOM.liveEmbed.src = `https://www.youtube.com/embed/${info.id}?autoplay=1&mute=1`;
        setVisibility(DOM.twitchNotification, !!info.twitchLive);
        if (info.twitchLive && DOM.twitchLink) DOM.twitchLink.href = `https://www.twitch.tv/${info.twitchLive.twitchChannelName}`;
    } else if (info.type === 'twitch' && info.twitchChannelName) {
        const parent = window.location.hostname || 'localhost';
        DOM.liveEmbed.src = `https://player.twitch.tv/?channel=${info.twitchChannelName}&parent=${parent}&autoplay=true&mute=1`;
        setVisibility(DOM.twitchNotification, false);
    }
    updateGridLiveState();
}

/* Skin */
function disposeSkinViewer() { if (state.skinViewerInstance) { state.skinViewerInstance.dispose(); state.skinViewerInstance = null; } }
function showSkinFallbackImage() {
    setVisibility(DOM.minecraftBlock, true);
    disposeSkinViewer();
    if (!DOM.skinViewerContainer) return;
    DOM.skinViewerContainer.innerHTML = `<img src="${profileConfig.minecraftSkinUrl}" alt="Minecraft skin" class="w-full h-full object-contain" />`;
}
function buildSkinControls() {
    if (state.skinControlsEl && state.skinControlsEl.parentElement) state.skinControlsEl.parentElement.removeChild(state.skinControlsEl);
    const controls = document.createElement('div');
    controls.id = 'skin-animation-controls';
    controls.className = 'skin-controls';
    const options = [
        { key: 'idle',   icon: 'accessibility',    available: !!skinview3d.IdleAnimation },
        { key: 'walk',   icon: 'directions_walk',  available: !!skinview3d.WalkingAnimation },
        { key: 'run',    icon: 'directions_run',   available: !!skinview3d.RunningAnimation },
        { key: 'rotate', icon: 'autorenew',        available: !!skinview3d.RotatingAnimation },
        { key: 'stop',   icon: 'stop_circle',      available: true }
    ];
    for (const opt of options) {
        if (!opt.available) continue;
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'mini-button';
        btn.setAttribute('data-anim', opt.key);
        btn.innerHTML = `<span class="material-symbols-outlined mini-icon" aria-hidden="true">${opt.icon}</span>`;
        btn.addEventListener('click', () => setSkinAnimation(opt.key));
        controls.appendChild(btn);
    }
    const downloadWrapper = DOM.downloadSkinButton?.parentElement;
    if (downloadWrapper && downloadWrapper.parentElement === DOM.minecraftBlock) DOM.minecraftBlock.insertBefore(controls, downloadWrapper);
    else DOM.skinViewerContainer.after(controls);
    state.skinControlsEl = controls;
    updateActiveAnimationButtons();
}
function setSkinAnimation(key) {
    if (!state.skinViewerInstance) return;
    let anim = null;
    try {
        if (key === 'idle'   && skinview3d.IdleAnimation)        anim = new skinview3d.IdleAnimation();
        else if (key === 'walk'  && skinview3d.WalkingAnimation) anim = new skinview3d.WalkingAnimation();
        else if (key === 'run'   && skinview3d.RunningAnimation) anim = new skinview3d.RunningAnimation();
        else if (key === 'rotate'&& skinview3d.RotatingAnimation)anim = new skinview3d.RotatingAnimation();
        else if (key === 'stop') anim = null;
        state.skinViewerInstance.animation = anim;
        state.currentAnimKey = key;
        updateActiveAnimationButtons();
    } catch (e) { console.warn('[SkinViewer] Failed to set animation:', key, e); }
}
function updateActiveAnimationButtons() {
    if (!state.skinControlsEl) return;
    const btns = state.skinControlsEl.querySelectorAll('.mini-button');
    btns.forEach(btn => btn.classList.toggle('active', btn.getAttribute('data-anim') === state.currentAnimKey));
}
async function initMinecraftSkinViewer() {
    if (!appConfig.showMinecraftSkinSection) { setVisibility(DOM.minecraftBlock, false); disposeSkinViewer(); return; }
    if (!DOM.skinCanvas || !DOM.skinViewerContainer) { console.error('[SkinViewer] Missing elements'); setVisibility(DOM.minecraftBlock, false); return; }
    try {
        await new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r)));
        setVisibility(DOM.minecraftBlock, true);
        const width = Math.max(1, DOM.skinViewerContainer.offsetWidth || 320);
        const height = Math.max(1, DOM.skinViewerContainer.offsetHeight || 320);
        disposeSkinViewer();
        const viewer = new skinview3d.SkinViewer({ canvas: DOM.skinCanvas, width, height });
        await viewer.loadSkin(profileConfig.minecraftSkinUrl); // { model:"slim" } если Alex
        try {
            if (skinview3d.IdleAnimation) { viewer.animation = new skinview3d.IdleAnimation(); state.currentAnimKey = 'idle'; }
            else if (skinview3d.WalkingAnimation) { viewer.animation = new skinview3d.WalkingAnimation(); state.currentAnimKey = 'walk'; }
            else { state.currentAnimKey = 'stop'; }
        } catch {}
        try {
            const controls = skinview3d.createOrbitControls(viewer);
            if (controls) { controls.enablePan = false; controls.enableZoom = true; controls.target?.set?.(0, 17, 0); controls.update?.(); }
        } catch {}
        state.skinViewerInstance = viewer;
        buildSkinControls();
        new ResizeObserver(() => {
            if (!state.skinViewerInstance) return;
            const w = Math.max(1, DOM.skinViewerContainer.offsetWidth || 320);
            const h = Math.max(1, DOM.skinViewerContainer.offsetHeight || 320);
            state.skinViewerInstance.setSize(w, h);
        }).observe(DOM.skinViewerContainer);
    } catch (e) { console.error('[SkinViewer] init error, fallback PNG', e); showSkinFallbackImage(); }
}

/* Свайпы без предпросмотра */
function initSwipeGestures() {
    const cards = document.querySelectorAll('.swipe-target');
    for (const card of cards) {
        let startX=0,startY=0,currentX=0,currentY=0; let pointerDown=false, swipeActive=false, suppressClick=false;
        const linkData = linksConfig.find(l => l.label_key === card.getAttribute('data-link-id')); if (!linkData) continue;
        const onStart = (e)=>{ pointerDown=true; swipeActive=false; startX=e.touches?e.touches[0].clientX:e.clientX; startY=e.touches?e.touches[0].clientY:e.clientY; card.style.transition='none'; };
        const onMove  = (e)=>{ if(!pointerDown)return; currentX=e.touches?e.touches[0].clientX:e.clientX; currentY=e.touches?e.touches[0].clientY:e.clientY;
            const dx=currentX-startX, dy=currentY-startY;
            if(!swipeActive && Math.abs(dx)>20 && Math.abs(dx)>Math.abs(dy)){ swipeActive=true; e.preventDefault(); }
            if(swipeActive){ e.preventDefault(); card.style.transform=`translateX(${dx}px)`; card.classList.toggle('swiping-right',dx>0); card.classList.toggle('swiping-left',dx<0); } };
        const onEnd   = ()=>{ if(!pointerDown)return; pointerDown=false; card.style.transition='transform .2s ease, background-color .3s ease, box-shadow .2s ease';
            const dx=currentX-startX; if(swipeActive){ const thr=card.offsetWidth*0.25;
                if(Math.abs(dx)>thr){ if(dx>0){ window.open(linkData.subscribeUrl || linkData.url,'_blank'); } else {
                    if(linkData.platformId==='youtube'){ const live=state.data.liveStream;
                        if(live && live.type==='youtube' && live.id) window.open(`https://www.youtube.com/watch?v=${live.id}`,'_blank');
                        else if(state.data.youtubeVideos?.length>0) window.open(`https://www.youtube.com/watch?v=${state.data.youtubeVideos[0].id}`,'_blank');
                        else window.open(linkData.url,'_blank');
                    } else { window.open(linkData.url,'_blank'); }
                } } }
            card.style.transform='translateX(0)'; card.classList.remove('swiping-left','swiping-right');
            if(swipeActive){ suppressClick=true; setTimeout(()=>{suppressClick=false;},0); } swipeActive=false; };
        const onClick = (e)=>{ if(suppressClick){ e.preventDefault(); e.stopPropagation(); } };
        card.addEventListener('mousedown',onStart); card.addEventListener('mousemove',onMove); card.addEventListener('mouseup',onEnd); card.addEventListener('mouseleave',onEnd);
        card.addEventListener('touchstart',onStart,{passive:false}); card.addEventListener('touchmove',onMove,{passive:false}); card.addEventListener('touchend',onEnd);
        card.addEventListener('click',onClick);
    }
}

/* Прочее */
function setupSupportButton() { setVisibility(DOM.supportSection, appConfig.showSupportButton); if (appConfig.showSupportButton && DOM.supportButton) DOM.supportButton.href = appConfig.supportUrl || '#'; }
function setupOfflineBanner() { const upd=()=>setVisibility(DOM.offlineWarning,!navigator.onLine); window.addEventListener('online',upd); window.addEventListener('offline',upd); upd(); }
function manageFirstVisitModal() { if (!DOM.firstVisitModal || !DOM.modalCloseBtn) return; const seen=localStorage.getItem('visited_modal'); if(!seen){ DOM.firstVisitModal.classList.add('active'); DOM.modalCloseBtn.onclick=()=>{ DOM.firstVisitModal.classList.remove('active'); localStorage.setItem('visited_modal','true'); }; } }
function setupAnalytics(){}

/* Моки для тестов live (?mockLive=both:YTID:TWCH | youtube:YTID | twitch:CH | none) */
function applyMockFromQuery() {
    const p=new URLSearchParams(location.search); const s=p.get('mockLive'); if(!s) return;
    if (s==='none'){ state.data.liveStream={type:'none'}; return; }
    const [kind,a,b]=s.split(':');
    if (kind==='both'){ state.data.liveStream={ type:'youtube', id:a||'e7K5ijK2VOo', title:'Mock YT', youtubeChannelId:'mock', twitchLive:{type:'twitch', id:'mock', title:'Mock TW', twitchChannelName:b||'monstercat'} }; }
    else if (kind==='youtube'){ state.data.liveStream={ type:'youtube', id:a||'e7K5ijK2VOo', title:'Mock YT', youtubeChannelId:'mock' }; }
    else if (kind==='twitch'){ state.data.liveStream={ type:'twitch', id:'mock', title:'Mock TW', twitchChannelName:a||'monstercat' }; }
}

/* Скачать скин: blob-надёжно */
async function downloadMinecraftSkin(ev) {
    try {
        ev?.preventDefault?.(); ev?.stopPropagation?.();
        const url=new URL(profileConfig.minecraftSkinUrl, location.href).toString();
        const res=await fetch(url,{cache:'no-store'}); if(!res.ok) throw new Error('HTTP '+res.status);
        const blob=await res.blob(); const blobUrl=URL.createObjectURL(blob);
        const a=document.createElement('a'); a.href=blobUrl; a.download='minecraft_skin.png'; document.body.appendChild(a); a.click(); a.remove();
        setTimeout(()=>URL.revokeObjectURL(blobUrl),1000);
    } catch {
        const fallback=new URL(profileConfig.minecraftSkinUrl, location.href).toString();
        const a=document.createElement('a'); a.href=fallback; a.target='_blank'; document.body.appendChild(a); a.click(); a.remove();
    }
}

/* Boot */
document.addEventListener('DOMContentLoaded', async () => {
    state.data = await fetchAppData();

    applyMockFromQuery();

    renderProfileSection();
    applyTheme(state.theme);
    updateLanguage();
    renderYouTubeVideosSection();
    renderLiveStream();        // покажем/спрячем лайв и переключим сетку
    updateGridLiveState();     // на всякий случай синхронизируем сетку
    await initMinecraftSkinViewer();
    setupSupportButton();
    setupOfflineBanner();
    manageFirstVisitModal();
    setupAnalytics();

    if (DOM.themeToggle) DOM.themeToggle.addEventListener('click', () => { state.theme = state.theme === 'dark' ? 'light' : 'dark'; applyTheme(state.theme); });
    if (DOM.languageToggle) DOM.languageToggle.addEventListener('click', () => { state.lang = state.lang === 'en' ? 'ru' : 'en'; localStorage.setItem('lang', state.lang); updateLanguage(); });
    if (DOM.downloadSkinButton) DOM.downloadSkinButton.addEventListener('click', downloadMinecraftSkin);
});