import { homeConfigRu } from './config_ru.js';
import { homeConfigEn } from './config_en.js';
import { marked } from 'https://cdn.jsdelivr.net/npm/marked@12.0.2/lib/marked.esm.js';
import DOMPurify from 'https://cdn.jsdelivr.net/npm/dompurify@3.1.6/dist/purify.es.mjs';
import * as skinview3d from 'https://cdn.jsdelivr.net/npm/skinview3d@3.4.1/+esm';

const SKIN_URL = './links/assets/skin.png';

const DOM = {
    // hero
    heroTagline: document.getElementById('hero-tagline'),
    totals: document.getElementById('totals'),
    goLinks1: document.getElementById('go-links-btn'),
    goLinksText: document.getElementById('go-links-text'),
    ctaYT: document.getElementById('cta-ytsub'),
    ctaYTText: document.getElementById('cta-ytsub-text'),
    ctaTG: document.getElementById('cta-telegram'),
    ctaTGText: document.getElementById('cta-telegram-text'),
    ctaSupport: document.getElementById('cta-support'),
    ctaSupportText: document.getElementById('cta-support-text'),

    // about + timeline
    aboutIntro: document.getElementById('about-intro'),
    timelineWrap: document.getElementById('timeline'),
    aboutOutro: document.getElementById('about-outro'),
    timelineTitle: document.getElementById('timeline-title'),
    tlExpand: document.getElementById('tl-expand'),
    tlCollapse: document.getElementById('tl-collapse'),
    tlExpandText: document.getElementById('tl-expand-text'),
    tlCollapseText: document.getElementById('tl-collapse-text'),

    // layout root
    contentGrid: document.getElementById('content-grid'),

    // left card
    linksTitle: document.getElementById('nav-title'),
    linksDesc: document.getElementById('nav-desc'),
    linksCtaText: document.getElementById('nav-cta-text'),
    goLinks2: document.getElementById('go-links-btn-2'),

    // live / calendar
    liveWrap: document.getElementById('live'),
    liveBadge: document.getElementById('live-badge'),
    liveEmbed: document.getElementById('live-embed'),
    liveEmbedWrap: document.getElementById('live-embed-wrap'),
    twitchNotice: document.getElementById('twitch-notice'),
    twitchLink: document.getElementById('twitch-link'),
    twitchText: document.getElementById('twitch-text'),
    twitchCta: document.getElementById('twitch-cta'),

    calendarSection: document.getElementById('calendar'),
    calPrev: document.getElementById('cal-prev'),
    calNext: document.getElementById('cal-next'),
    calLabel: document.getElementById('cal-label'),
    calHead: document.getElementById('cal-weekdays'),
    calGrid: document.getElementById('cal-grid'),
    legendYt: document.getElementById('legend-yt'),
    legendTw: document.getElementById('legend-tw'),
    legendBoth: document.getElementById('legend-both'),
    legendPlanned: document.getElementById('legend-planned'),
    legendMissed: document.getElementById('legend-missed'),
    liveEmptyTitle: document.getElementById('live-empty-title'),
    liveEmptySub: document.getElementById('live-empty-sub'),

    // skin
    skinSection: document.getElementById('skin'),
    skinTitle: document.getElementById('skin-title'),
    skinViewer: document.getElementById('skin-viewer'),
    skinCanvas: document.getElementById('skin-canvas'),
    skinControls: document.getElementById('skin-controls'),
    skinDownload: document.getElementById('download-skin'),
    skinDownloadText: document.getElementById('skin-download-text'),

    // videos
    videosTitle: document.getElementById('videos-title'),
    carousel: document.getElementById('carousel'),

    // toggles
    themeToggleBottom: document.getElementById('theme-toggle-bottom'),
    langToggleBottom: document.getElementById('lang-toggle-bottom'),
    themeIconBottom: document.getElementById('theme-icon-bottom'),
    themeToggleTop: document.getElementById('theme-toggle'),
    langToggleTop: document.getElementById('lang-toggle'),
    themeIconTop: document.getElementById('theme-icon'),

    offlineWarning: document.getElementById('offline-warning')
};

const MONTHS = {
    ru: ["Январь","Февраль","Март","Апрель","Май","Июнь","Июль","Август","Сентябрь","Октябрь","Ноябрь","Декабрь"],
    en: ["January","February","March","April","May","June","July","August","September","October","November","December"]
};
const WEEKDAYS = {
    ru: ["Пн","Вт","Ср","Чт","Пт","Сб","Вс"],
    en: ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
};

const state = {
    lang: localStorage.getItem('home_lang') || 'ru',
    theme: localStorage.getItem('home_theme') || 'dark',
    cfg: null,
    data: { followerCounts:{}, youtubeVideos:[], liveStream:{type:'none'} },
    history: { events: [] },
    cal: { year: new Date().getFullYear(), month: new Date().getMonth() },
    skin: { viewer: /** @type {skinview3d.SkinViewer|null} */(null), active: 'idle', ro: /** @type {ResizeObserver|null} */(null) }
};

/* utils */
function setVisibility(el, v){ if(!el) return; el.classList.toggle('hidden', !v); }
function formatCount(n){ if(n==null||isNaN(n))return '—'; if(n>=1e6)return (n/1e6).toFixed(1).replace(/\.0$/,'')+'M'; if(n>=1e3)return (n/1e3).toFixed(1).replace(/\.0$/,'')+'K'; return String(n); }
function md(text){ return DOMPurify.sanitize(marked.parse(text || '')); }
function ymd(d){ return d.toISOString().slice(0,10); }
async function fetchJson(url){ const r=await fetch(url,{cache:'no-store'}); if(!r.ok) throw 0; return await r.json(); }
async function fetchData(){ try{ return await fetchJson(`./data.json?t=${Date.now()}`);}catch{ return { followerCounts:{}, youtubeVideos:[], liveStream:{type:'none'} }; } }
async function fetchHistory(){ try{ return await fetchJson(`./streams_history.json?t=${Date.now()}`);}catch{ return { events: [] }; } }

/* theme/lang */
function setTheme(theme){
    document.body.classList.remove('dark-theme','light-theme');
    document.body.classList.add(`${theme}-theme`);
    localStorage.setItem('home_theme', theme);
    const icon = DOM.themeIconBottom || DOM.themeIconTop;
    if (icon) icon.textContent = theme === 'dark' ? 'light_mode' : 'dark_mode';
}
function toggleTheme(){ setTheme(state.theme = state.theme==='dark'?'light':'dark'); }
function setLang(lang){
    state.lang = lang; localStorage.setItem('home_lang', lang);
    state.cfg = (lang==='en') ? homeConfigEn : homeConfigRu;
    renderAllStatic(); renderHero(); renderLiveTexts(); renderCalendar();
}
function toggleLang(){ setLang(state.lang==='ru'?'en':'ru'); }

function setupOfflineBanner(){
    const upd=()=>setVisibility(DOM.offlineWarning, !navigator.onLine);
    window.addEventListener('online',upd); window.addEventListener('offline',upd); upd();
}

/* STATIC */
function renderAllStatic(){
    const ui = state.cfg.ui, L = state.cfg.links, T = state.cfg.texts;

    // hero
    DOM.heroTagline && (DOM.heroTagline.textContent = T.heroTagline || '');
    DOM.goLinksText && (DOM.goLinksText.textContent = state.lang==='ru' ? 'Мои ссылки' : 'My links');
    DOM.ctaYTText && (DOM.ctaYTText.textContent = state.lang==='ru' ? 'Подписаться на YouTube' : 'Subscribe on YouTube');
    DOM.ctaTGText && (DOM.ctaTGText.textContent = 'Telegram');
    DOM.ctaSupportText && (DOM.ctaSupportText.textContent = state.lang==='ru' ? 'Поддержать' : 'Support');

    // links
    if (DOM.goLinks1) DOM.goLinks1.href = L.linksPageUrl || './links/';
    if (DOM.ctaYT)      { if(L.youtubeSubscribeUrl){ DOM.ctaYT.href=L.youtubeSubscribeUrl; setVisibility(DOM.ctaYT,true);} else setVisibility(DOM.ctaYT,false); }
    if (DOM.ctaTG)      { if(L.telegramUrl){ DOM.ctaTG.href=L.telegramUrl; setVisibility(DOM.ctaTG,true);} else setVisibility(DOM.ctaTG,false); }
    if (DOM.ctaSupport) { if(L.supportUrl){ DOM.ctaSupport.href=L.supportUrl; setVisibility(DOM.ctaSupport,true);} else setVisibility(DOM.ctaSupport,false); }

    DOM.linksTitle && (DOM.linksTitle.textContent = ui.navTitle || '');
    DOM.linksDesc && (DOM.linksDesc.textContent = ui.navDesc || '');
    DOM.linksCtaText && (DOM.linksCtaText.textContent = ui.navCta || '');
    if (DOM.goLinks2) DOM.goLinks2.href = L.linksPageUrl || './links/';

    // about/timeline
    DOM.aboutIntro && (DOM.aboutIntro.innerHTML = md(T.aboutIntroMd || ''));
    DOM.aboutOutro && (DOM.aboutOutro.innerHTML = md(T.aboutOutroMd || ''));
    DOM.timelineTitle && (DOM.timelineTitle.textContent = ui.timelineTitle || 'Timeline');
    DOM.tlExpandText && (DOM.tlExpandText.textContent = state.lang==='ru' ? 'Развернуть' : 'Expand');
    DOM.tlCollapseText && (DOM.tlCollapseText.textContent = state.lang==='ru' ? 'Свернуть' : 'Collapse');

    const tl = T.timeline || [];
    const html = tl.map((it, idx)=>`
    <details class="timeline card m3-shadow-md" ${idx===0?'open':''}>
      <summary><span class="text-lg font-medium">${it.year} — ${it.title || ''}</span><span class="material-symbols-outlined">expand_more</span></summary>
      <div class="md">${md(it.bodyMd || '')}</div>
    </details>
  `).join('');
    if (DOM.timelineWrap) DOM.timelineWrap.innerHTML = html;
    DOM.timelineWrap?.querySelectorAll('details').forEach(d=>{
        const icon = d.querySelector('.material-symbols-outlined');
        const sync = ()=>{ if(icon) icon.style.transform = d.open ? 'rotate(180deg)' : 'rotate(0deg)'; };
        d.addEventListener('toggle', sync); sync();
    });

    // skin / videos
    DOM.skinTitle && (DOM.skinTitle.textContent = ui.skinTitle || '');
    DOM.skinDownloadText && (DOM.skinDownloadText.textContent = ui.skinDownload || '');
    DOM.videosTitle && (DOM.videosTitle.textContent = ui.videosTitle || '');

    wireTimelineControls();
    enableUnifiedHover(); // одинаковый hover/tap на всех устройствах
}

function wireTimelineControls(){
    if (DOM.tlExpand) DOM.tlExpand.onclick = () => DOM.timelineWrap?.querySelectorAll('details').forEach(d => d.open = true);
    if (DOM.tlCollapse) DOM.tlCollapse.onclick = () => DOM.timelineWrap?.querySelectorAll('details').forEach(d => d.open = false);
}

/* Унифицированный hover на всех устройствах: тонко повторяет :hover */
function enableUnifiedHover(){
    const cards = document.querySelectorAll('.card');
    cards.forEach(el=>{
        if (el.dataset.hoverBound) return;
        el.dataset.hoverBound = '1';

        let touchMoved = false;
        let clearTimer = null;

        const add = ()=> {
            el.classList.add('is-hover');
            if (clearTimer) { clearTimeout(clearTimer); clearTimer = null; }
        };
        const removeDelayed = ()=> {
            if (clearTimer) clearTimeout(clearTimer);
            clearTimer = setTimeout(()=> el.classList.remove('is-hover'), 120);
        };
        const removeNow = ()=> {
            if (clearTimer) clearTimeout(clearTimer);
            el.classList.remove('is-hover');
        };

        // Мышь / перо
        el.addEventListener('pointerenter', (e)=>{ if(e.pointerType!=='touch') add(); }, { passive:true });
        el.addEventListener('pointerleave', (e)=>{ if(e.pointerType!=='touch') removeNow(); }, { passive:true });

        // Тач
        el.addEventListener('touchstart', ()=>{ touchMoved=false; add(); }, { passive:true });
        el.addEventListener('touchmove', ()=>{ touchMoved=true; removeNow(); }, { passive:true });
        el.addEventListener('touchend', ()=>{ if(!touchMoved) removeDelayed(); else removeNow(); }, { passive:true });
        el.addEventListener('touchcancel', removeNow, { passive:true });

        // Фолбэки
        el.addEventListener('mousedown', add, { passive:true });
        el.addEventListener('mouseup', removeDelayed, { passive:true });
        document.addEventListener('scroll', removeNow, { passive:true });
        el.addEventListener('blur', removeNow, { passive:true });
        el.addEventListener('keydown', (e)=>{ if(e.key==='Enter'||e.key===' '){ add(); } }, { passive:true });
    });
}

/* HERO totals */
function renderHero(){
    const counts = state.data.followerCounts || {};
    const total = Object.values(counts).filter(v=>typeof v==='number').reduce((a,b)=>a+b,0);
    DOM.totals && (DOM.totals.textContent = (state.cfg.ui.followersLabel || '') + formatCount(total));
}

/* live + calendar */
function renderLiveTexts(){
    if (state.lang==='ru'){
        DOM.liveEmptyTitle && (DOM.liveEmptyTitle.textContent = 'Сейчас стрима нет');
        DOM.liveEmptySub && (DOM.liveEmptySub.textContent   = 'Обычно стримы по пятницам, 17:00–19:00 МСК.');
        DOM.twitchText && (DOM.twitchText.textContent     = 'Стрим также идёт на Twitch!');
        DOM.twitchCta && (DOM.twitchCta.textContent      = 'Смотреть на Twitch');
        DOM.legendYt && (DOM.legendYt.textContent       = 'YouTube');
        DOM.legendTw && (DOM.legendTw.textContent       = 'Twitch');
        DOM.legendBoth && (DOM.legendBoth.textContent     = 'Оба');
        DOM.legendPlanned && (DOM.legendPlanned.textContent  = 'Потенциальный');
        DOM.legendMissed && (DOM.legendMissed.textContent   = 'Зачёркнутые — стрима не было');
    } else {
        DOM.liveEmptyTitle && (DOM.liveEmptyTitle.textContent = 'No stream right now');
        DOM.liveEmptySub && (DOM.liveEmptySub.textContent   = 'Streams are usually on Fridays, 17:00–19:00 MSK.');
        DOM.twitchText && (DOM.twitchText.textContent     = 'Stream is also live on Twitch!');
        DOM.twitchCta && (DOM.twitchCta.textContent      = 'Watch on Twitch');
        DOM.legendYt && (DOM.legendYt.textContent       = 'YouTube');
        DOM.legendTw && (DOM.legendTw.textContent       = 'Twitch');
        DOM.legendBoth && (DOM.legendBoth.textContent     = 'Both');
        DOM.legendPlanned && (DOM.legendPlanned.textContent  = 'Planned');
        DOM.legendMissed && (DOM.legendMissed.textContent   = 'Struck-out — there was no stream');
    }
}

function renderLive(){
    renderLiveTexts();
    const live = state.data.liveStream || { type:'none' };
    const has = live.type !== 'none';

    if (DOM.contentGrid) {
        DOM.contentGrid.classList.toggle('has-live', has);
        DOM.contentGrid.classList.toggle('no-live', !has);
    }

    setVisibility(DOM.liveWrap, has);
    setVisibility(DOM.calendarSection, true);
    setVisibility(DOM.liveEmptyTitle, !has);
    setVisibility(DOM.liveEmptySub, !has);

    if (has && DOM.liveEmbed) {
        if (live.type === 'youtube' && live.id){
            DOM.liveEmbed.src = `https://www.youtube.com/embed/${live.id}?autoplay=1&mute=1`;
            setVisibility(DOM.twitchNotice, !!live.twitchLive);
            if (live.twitchLive && DOM.twitchLink) DOM.twitchLink.href = `https://www.twitch.tv/${live.twitchLive.twitchChannelName}`;
        } else if (live.type === 'twitch' && live.twitchChannelName){
            const parent = location.hostname || 'localhost';
            DOM.liveEmbed.src = `https://player.twitch.tv/?channel=${live.twitchChannelName}&parent=${parent}&autoplay=true&mute=1`;
            setVisibility(DOM.twitchNotice, false);
        }
    } else if (!has) {
        if (DOM.liveEmbed) DOM.liveEmbed.src = 'about:blank';
    }

    renderCalendar();
}

/* history + calendar */
function buildMonth(year, month){
    const first = new Date(year, month, 1);
    const startDow = (first.getDay()+6)%7;
    const daysInMonth = new Date(year, month+1, 0).getDate();
    const cells = [];
    for(let i=0;i<startDow;i++) cells.push(null);
    for(let d=1; d<=daysInMonth; d++){
        const dt = new Date(year, month, d);
        const today = new Date(); today.setHours(0,0,0,0);
        const isToday = dt.getTime() === today.getTime();
        const isPast  = dt.getTime() < today.getTime();
        const dow = (dt.getDay()+6)%7;
        cells.push({ date: dt, day:d, isToday, isPast, dow });
    }
    return cells;
}
function renderCalendar(){
    if (!DOM.calHead || !DOM.calGrid || !DOM.calLabel) return;

    const months = MONTHS[state.lang];
    DOM.calLabel.textContent = `${months[state.cal.month]} ${state.cal.year}`;
    const week = WEEKDAYS[state.lang];
    DOM.calHead.innerHTML = week.map(w=>`<div class="muted">${w}</div>`).join('');

    const events = (state.history.events || []);
    const byDate = new Map();
    for (const e of events){
        const set = byDate.get(e.date) || { yt:false, tw:false, items:[] };
        if (e.platform === 'youtube') set.yt = true;
        if (e.platform === 'twitch')  set.tw = true;
        set.items.push(e);
        byDate.set(e.date, set);
    }

    const cells = buildMonth(state.cal.year, state.cal.month);
    const html = cells.map(c=>{
        if (!c) return `<div></div>`;
        const ds = ymd(c.date);
        const info = byDate.get(ds);
        const isFriday = c.dow === 4;

        const classes = ['cell'];
        if (isFriday) classes.push('fri');
        if (c.isToday) classes.push('today');

        let dot = '';
        let chips = '';

        if (info){
            if (info.yt && info.tw) dot = `<span class="dot both"></span>`;
            else if (info.yt)       dot = `<span class="dot yt"></span>`;
            else if (info.tw)       dot = `<span class="dot tw"></span>`;

            const yt = info.items.find(x=>x.platform==='youtube');
            const tw = info.items.find(x=>x.platform==='twitch');
            if (yt) chips += `<a href="${yt.url}" target="_blank" rel="noopener">YT</a>`;
            if (tw) chips += (chips?' · ':'') + `<a href="${tw.url}" target="_blank" rel="noopener">TW</a>`;
        } else {
            if (isFriday){
                if (c.isPast) classes.push('passed','no-stream');
                else dot = `<span class="dot planned"></span>`;
            }
        }
        return `<div class="${classes.join(' ')}"><div>${c.day}</div>${dot}${chips?`<div>${chips}</div>`:''}</div>`;
    }).join('');

    DOM.calGrid.innerHTML = html;

    if (DOM.calPrev) DOM.calPrev.onclick = ()=>{ state.cal.month--; if(state.cal.month<0){state.cal.month=11; state.cal.year--; } renderCalendar(); };
    if (DOM.calNext) DOM.calNext.onclick = ()=>{ state.cal.month++; if(state.cal.month>11){state.cal.month=0; state.cal.year++; } renderCalendar(); };
}

/* videos */
function renderVideos(){
    const vids = state.data.youtubeVideos || [];
    if (!DOM.carousel) return;
    DOM.carousel.innerHTML = '';
    vids.forEach(v=>{
        const a=document.createElement('a');
        a.href=`https://www.youtube.com/watch?v=${v.id}`; a.target='_blank';
        a.className='flex-shrink-0 w-64 rounded-2xl overflow-hidden m3-shadow-md card';
        a.innerHTML = `<img src="${v.thumbnailUrl}" alt="${v.title}" class="w-full h-36 object-cover"><div class="p-3"><p class="text-sm font-medium leading-tight">${v.title}</p></div>`;
        DOM.carousel.appendChild(a);
    });
    DOM.carousel.addEventListener('wheel', (e)=>{ if(e.deltaY){ e.preventDefault(); DOM.carousel.scrollLeft += e.deltaY; } }, { passive:false });
}

/* skin */
function setActiveMini(key){
    state.skin.active = key;
    if (!DOM.skinControls) return;
    const btns = DOM.skinControls.querySelectorAll('.mini-button');
    btns.forEach(b=>{
        const isActive = b.getAttribute('data-anim') === key;
        b.classList.toggle('active', isActive);
        b.setAttribute('aria-pressed', isActive ? 'true' : 'false');
    });
}
function buildSkinControls(){
    if (!DOM.skinControls) return;
    DOM.skinControls.innerHTML='';
    const opts=[
        {k:'idle',icon:'accessibility',ok:!!skinview3d.IdleAnimation},
        {k:'walk',icon:'directions_walk',ok:!!skinview3d.WalkingAnimation},
        {k:'run',icon:'directions_run',ok:!!skinview3d.RunningAnimation},
        {k:'rotate',icon:'autorenew',ok:!!skinview3d.RotatingAnimation},
        {k:'stop',icon:'stop_circle',ok:true}
    ];
    for (const o of opts){
        if(!o.ok) continue;
        const btn=document.createElement('button');
        btn.type='button';
        btn.className='mini-button';
        btn.setAttribute('data-anim', o.k);
        btn.setAttribute('aria-label', o.k);
        btn.setAttribute('aria-pressed', 'false');
        btn.innerHTML=`<span class="material-symbols-outlined mini-icon">${o.icon}</span>`;
        const act = (e)=>{ e.preventDefault(); applyAnimation(o.k); };
        btn.addEventListener('pointerdown', act);
        btn.addEventListener('click', act);
        btn.addEventListener('keydown', (e)=>{ if(e.key==='Enter'||e.key===' '){ act(e); }});
        DOM.skinControls.appendChild(btn);
    }
    setActiveMini(state.skin.active);
}
function applyAnimation(key){
    if(!state.skin.viewer) return;
    let anim=null;
    try{
        if(key==='idle' && skinview3d.IdleAnimation) anim=new skinview3d.IdleAnimation();
        else if(key==='walk' && skinview3d.WalkingAnimation) anim=new skinview3d.WalkingAnimation();
        else if(key==='run' && skinview3d.RunningAnimation) anim=new skinview3d.RunningAnimation();
        else if(key==='rotate' && skinview3d.RotatingAnimation) anim=new skinview3d.RotatingAnimation();
        else if(key==='stop') anim=null;
        state.skin.viewer.animation=anim; setActiveMini(key);
    }catch(e){ console.warn('[skin] anim error', e); }
}
async function initSkin(){
    if(!DOM.skinViewer || !DOM.skinCanvas || !DOM.skinSection) return;
    setVisibility(DOM.skinSection, true);
    await new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)));

    try { state.skin.ro?.disconnect?.(); } catch {}
    state.skin.viewer?.dispose?.();

    try{
        const rect = DOM.skinViewer.getBoundingClientRect();
        let lastW = Math.max(1, Math.round(rect.width));
        let lastH = Math.max(1, Math.round(rect.height));

        const viewer=new skinview3d.SkinViewer({ canvas: DOM.skinCanvas, width:lastW, height:lastH });
        await viewer.loadSkin(SKIN_URL);
        if (skinview3d.IdleAnimation) { viewer.animation=new skinview3d.IdleAnimation(); state.skin.active='idle'; }
        try {
            const c=skinview3d.createOrbitControls(viewer);
            if(c){ c.enablePan=false; c.enableZoom=true; c.target?.set?.(0,17,0); c.update?.(); }
        } catch {}

        state.skin.viewer=viewer;
        buildSkinControls();

        const ro = new ResizeObserver(entries=>{
            const cr=entries[0]?.contentRect; if(!cr) return;
            const w=Math.max(1, Math.round(cr.width));
            const h=Math.max(1, Math.round(cr.height));
            if (w!==lastW || h!==lastH) { lastW=w; lastH=h; try{ state.skin.viewer?.setSize(w,h); }catch{} }
        });
        ro.observe(DOM.skinViewer);
        state.skin.ro = ro;

        window.addEventListener('orientationchange', ()=>{
            const r=DOM.skinViewer.getBoundingClientRect();
            const w=Math.max(1, Math.round(r.width));
            const h=Math.max(1, Math.round(r.height));
            if(w>0 && h>0){ try{ state.skin.viewer?.setSize(w,h); }catch{} }
        }, { passive:true });

    }catch(e){
        console.error('[skin] init failed', e);
        DOM.skinViewer.innerHTML = `<img src="${SKIN_URL}" alt="Minecraft skin" style="max-width:100%; max-height:100%; object-fit:contain">`;
    }
}

/* download skin */
async function downloadSkin(ev){
    try{
        ev?.preventDefault?.();
        const res = await fetch(SKIN_URL, { cache: 'no-store' });
        if(!res.ok) throw new Error('HTTP '+res.status);
        const blob = await res.blob();
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url; a.download = 'minecraft_skin.png';
        document.body.appendChild(a); a.click(); a.remove();
        setTimeout(()=>URL.revokeObjectURL(url), 1000);
    } catch {
        window.open(SKIN_URL, '_blank', 'noopener');
    }
}

/* boot */
document.addEventListener('DOMContentLoaded', async ()=>{
    setTheme(state.theme);
    setLang(state.lang);
    setupOfflineBanner();

    // данные
    state.data    = await fetchData();
    state.history = await fetchHistory();

    // моки: ?mockLive=youtube:ID | twitch:channel | both:ID:channel | none
    const q=new URLSearchParams(location.search); const s=q.get('mockLive');
    if (s){
        if (s==='none') state.data.liveStream = { type:'none' };
        else {
            const [k,a,b]=s.split(':');
            if (k==='youtube') state.data.liveStream={ type:'youtube', id:a, title:'Mock YT' };
            else if (k==='twitch') state.data.liveStream={ type:'twitch', twitchChannelName:a, id:'mock', title:'Mock TW' };
            else if (k==='both') state.data.liveStream={ type:'youtube', id:a, title:'Mock YT', twitchLive:{ type:'twitch', twitchChannelName:b, id:'mock', title:'Mock TW'} };
        }
    }

    renderHero();
    renderLive();     // переключает классы has-live/no-live и обновляет календарь
    renderVideos();
    await initSkin();

    // кнопка скачивания скина
    DOM.skinDownload?.addEventListener('click', downloadSkin);

    // переключатели
    DOM.themeToggleBottom && (DOM.themeToggleBottom.onclick = toggleTheme);
    DOM.langToggleBottom  && (DOM.langToggleBottom.onclick  = toggleLang);
    DOM.themeToggleTop && (DOM.themeToggleTop.onclick = toggleTheme);
    DOM.langToggleTop  && (DOM.langToggleTop.onclick  = toggleLang);

    // календарь навигация (страховка)
    DOM.calPrev && (DOM.calPrev.onclick = ()=>{ state.cal.month--; if(state.cal.month<0){state.cal.month=11; state.cal.year--; } renderCalendar(); });
    DOM.calNext && (DOM.calNext.onclick = ()=>{ state.cal.month++; if(state.cal.month>11){state.cal.month=0; state.cal.year++; } renderCalendar(); });
});