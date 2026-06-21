import Publish
import Plot
import Foundation

// MARK: - Site

struct BezzubickSite: Website {
    enum SectionID: String, WebsiteSectionID { case index }
    struct ItemMetadata: WebsiteItemMetadata {}
    var url = URL(string: "https://httydcraft.github.io/BezzubickMCPlay")!
    var name = "Bezzubick MCPlay"
    var description = "Ютубер и стример по Minecraft."
    var language: Language { .russian }
    var imagePath: Path? { Path("assets/avatar.png") }
}

// MARK: - File helpers

func readFile(_ path: String) -> String {
    (try? String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)) ?? ""
}

func readMarkdownBody(_ path: String) -> String {
    let raw = readFile(path)
    let lines = raw.components(separatedBy: "\n")
    guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else { return raw }
    if let end = lines.dropFirst().firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "---" }) {
        return Array(lines[(end + 1)...]).joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return raw
}

func readMarkdownFrontmatter(_ path: String) -> [String: String] {
    let raw = readFile(path)
    let lines = raw.components(separatedBy: "\n")
    guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else { return [:] }
    var meta: [String: String] = [:]
    if let end = lines.dropFirst().firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "---" }) {
        for line in lines[1..<end] {
            let p = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if p.count == 2 { meta[p[0]] = p[1].trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
        }
    }
    return meta
}

func splitLang(_ body: String) -> (ru: String, en: String) {
    let lines = body.components(separatedBy: "\n")
    var ru: [String] = []
    var en: [String] = []
    var currentLang = "ru"
    for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed == "<!-- lang:ru -->" { currentLang = "ru"; continue }
        if trimmed == "<!-- lang:en -->" { currentLang = "en"; continue }
        if currentLang == "ru" { ru.append(line) }
        else { en.append(line) }
    }
    let ruText = ru.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    let enText = en.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    return (ruText, enText)
}

struct BilingualContent {
    let ru: String
    let en: String
    var htmlRu: String { md2html(ru) }
    var htmlEn: String { md2html(en) }
    var rawRu: String { "<div data-lang=\"ru\">\(htmlRu)</div><div data-lang=\"en\" style=\"display:none\">\(htmlEn)</div>" }
    var rawEn: String { "<div data-lang=\"en\">\(htmlEn)</div><div data-lang=\"ru\" style=\"display:none\">\(htmlRu)</div>" }
}

func readBilingualMarkdown(_ path: String) -> BilingualContent {
    let body = readMarkdownBody(path)
    let (ru, en) = splitLang(body)
    return BilingualContent(ru: ru, en: en)
}

func readBilingualTimelineMarkdown(_ path: String) -> (titleRu: String, titleEn: String, body: BilingualContent) {
    let meta = readMarkdownFrontmatter(path)
    let body = readMarkdownBody(path)
    let (ru, en) = splitLang(body)
    return (meta["title"] ?? "", meta["title_en"] ?? meta["title"] ?? "", BilingualContent(ru: ru, en: en))
}

// MARK: - Simple Markdown → HTML

func md2html(_ md: String) -> String {
    var html = md
    html = html.replacingOccurrences(of: "^#### (.+)$", with: "<h4>$1</h4>", options: .regularExpression)
    html = html.replacingOccurrences(of: "^### (.+)$", with: "<h3>$1</h3>", options: .regularExpression)
    html = html.replacingOccurrences(of: "^## (.+)$", with: "<h2>$1</h2>", options: .regularExpression)
    html = html.replacingOccurrences(of: "^# (.+)$", with: "<h1>$1</h1>", options: .regularExpression)
    html = html.replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "<strong>$1</strong>", options: .regularExpression)
    html = html.replacingOccurrences(of: "^- (.+)$", with: "<li>$1</li>", options: .regularExpression)
    html = html.replacingOccurrences(of: "((?:<li>.*?</li>\n?)+)", with: "<ul>$1</ul>", options: .regularExpression)
    let lines = html.components(separatedBy: "\n")
    var result: [String] = []
    for line in lines {
        let t = line.trimmingCharacters(in: .whitespaces)
        if t.isEmpty { result.append("") }
        else if t.hasPrefix("<h") || t.hasPrefix("<ul") || t.hasPrefix("<li") || t.hasPrefix("</ul>") || t.hasPrefix("</li>") { result.append(t) }
        else { result.append("<p>\(t)</p>") }
    }
    return result.joined(separator: "\n")
}

// MARK: - Timeline reader

struct TimelineEntry: Comparable {
    let year, titleRu, titleEn, bodyRu, bodyEn: String
    let order: Int
    static func < (lhs: TimelineEntry, rhs: TimelineEntry) -> Bool { lhs.order < rhs.order }
}

func readTimeline() -> [TimelineEntry] {
    let dir = URL(fileURLWithPath: "Content/timeline")
    guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return [] }
    return files.filter { $0.pathExtension == "md" }.compactMap { file -> TimelineEntry? in
        let meta = readMarkdownFrontmatter(file.path)
        let (titleRu, titleEn, body) = readBilingualTimelineMarkdown(file.path)
        guard let year = meta["year"] else { return nil }
        return TimelineEntry(year: year, titleRu: titleRu, titleEn: titleEn, bodyRu: body.ru, bodyEn: body.en, order: Int(meta["order"] ?? "99") ?? 99)
    }.sorted()
}

// MARK: - Links config reader (simple YAML)

struct LinkItem { let label, url, icon, platform: String; let order, showCount: Bool; let count: Int }
struct HeroBtn { let label, url, icon, style: String }

func parseLinks() -> ([LinkItem], [HeroBtn]) {
    let raw = readFile("Config/links.yml")
    var links: [LinkItem] = []
    var heroes: [HeroBtn] = []
    var cur: [String: String] = [:]
    var section = ""
    for line in raw.components(separatedBy: "\n") {
        let t = line.trimmingCharacters(in: .whitespaces)
        if t == "links:" { section = "links"; continue }
        if t == "heroButtons:" { section = "hero"; continue }
        if section == "links" && t.hasPrefix("- ") {
            if !cur.isEmpty, let l = cur["label"] {
                links.append(LinkItem(label: l, url: cur["url"] ?? "", icon: cur["icon"] ?? "link",
                                      platform: cur["platform"] ?? "", order: true, showCount: cur["showCount"] == "true", count: 0))
            }
            cur = [:]
        }
        if section == "hero" && t.hasPrefix("- ") {
            if !cur.isEmpty, let l = cur["label"] {
                heroes.append(HeroBtn(label: l, url: cur["url"] ?? "", icon: cur["icon"] ?? "link", style: cur["style"] ?? "support"))
            }
            cur = [:]
        }
        if t.contains(":") {
            let p = t.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if p.count == 2 { cur[p[0]] = p[1].trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
        }
    }
    if !cur.isEmpty, let l = cur["label"] {
        if section == "links" {
            links.append(LinkItem(label: l, url: cur["url"] ?? "", icon: cur["icon"] ?? "link",
                                  platform: cur["platform"] ?? "", order: true, showCount: cur["showCount"] == "true", count: 0))
        } else if section == "hero" {
            heroes.append(HeroBtn(label: l, url: cur["url"] ?? "", icon: cur["icon"] ?? "link", style: cur["style"] ?? "support"))
        }
    }
    return (links, heroes)
}

// MARK: - JavaScript (generated by Swift)

let siteJS = """
(function(){
'use strict';
var C={dark:{bg:'#000',onBg:'#FFF',surfaceLow:'#1F1F1F',surface:'#2D2D2D',primary:'#BB86FC',onPrimary:'#000',primaryContainer:'#4A148C',outline:'#8C8C8C'},
light:{bg:'#FFF',onBg:'#000',surfaceLow:'#F0F0F0',surface:'#E0E0E0',primary:'#6200EE',onPrimary:'#FFF',primaryContainer:'#BB86FC',outline:'#BDBDBD'}};
var S={theme:localStorage.getItem('theme')||'dark',lang:localStorage.getItem('lang')||(navigator.language.startsWith('ru')?'ru':'en')};

function setTheme(t){S.theme=t;localStorage.setItem('theme',t);
document.body.className=t+'-theme';
var icon=document.getElementById('theme-icon-bottom');if(icon)icon.textContent=t==='dark'?'light_mode':'dark_mode';}
function toggleTheme(){setTheme(S.theme==='dark'?'light':'dark');}

var STR={ru:{followers:'\\u0412\\u0441\\u0435\\u0433\\u043e \\u043f\\u043e\\u0434\\u043f\\u0438\\u0441\\u0447\\u0438\\u043a\\u043e\\u0432: ',
navTitle:'\\u041d\\u0430\\u0432\\u0438\\u0433\\u0430\\u0446\\u0438\\u044f',navDesc:'\\u041f\\u0435\\u0440\\u0435\\u0439\\u0434\\u0438\\u0442\\u0435 \\u043d\\u0430 \\u0441\\u0442\\u0440\\u0430\\u043d\\u0438\\u0446\\u0443 \\u0441\\u043e \\u0432\\u0441\\u0435\\u043c\\u0438 \\u043c\\u043e\\u0438\\u043c\\u0438 \\u0441\\u0441\\u044b\\u043b\\u043a\\u0430\\u043c\\u0438.',
navCta:'\\u041f\\u0435\\u0440\\u0435\\u0439\\u0442\\u0438 \\u043a \\u0441\\u0441\\u044b\\u043b\\u043a\\u0430\\u043c',
skinTitle:'\\u041c\\u043e\\u0439 \\u0441\\u043a\\u0438\\u043d Minecraft',skinDl:'\\u0421\\u043a\\u0430\\u0447\\u0430\\u0442\\u044c \\u0441\\u043a\\u0438\\u043d',
videosTitle:'\\u041f\\u043e\\u0441\\u043b\\u0435\\u0434\\u043d\\u0438\\u0435 \\u0432\\u0438\\u0434\\u0435\\u043e',
tlTitle:'\\u041b\\u0435\\u043d\\u0442\\u0430 \\u043a\\u0430\\u043d\\u0430\\u043b\\u0430',
expand:'\\u0420\\u0430\\u0437\\u0432\\u0435\\u0440\\u043d\\u0443\\u0442\\u044c',collapse:'\\u0421\\u0432\\u0435\\u0440\\u043d\\u0443\\u0442\\u044c',
liveEmpty:'\\u0421\\u0435\\u0439\\u0447\\u0430\\u0441 \\u0441\\u0442\\u0440\\u0438\\u043c\\u0430 \\u043d\\u0435\\u0442',
liveSub:'\\u041e\\u0431\\u044b\\u0447\\u043d\\u043e \\u0441\\u0442\\u0440\\u0438\\u043c\\u044b \\u043f\\u043e \\u043f\\u044f\\u0442\\u043d\\u0438\\u0446\\u0430\\u043c, 17:00\\u201319:00 \\u041c\\u0421\\u041a.',
legendYt:'YouTube',legendTw:'Twitch',legendBoth:'\\u041e\\u0431\\u0430',legendPlanned:'\\u041f\\u043e\\u0442\\u0435\\u043d\\u0446\\u0438\\u0430\\u043b\\u044c\\u043d\\u044b\\u0439',
legendMissed:'\\u0417\\u0430\\u0447\\u0451\\u0440\\u043a\\u043d\\u0443\\u0442\\u044b\\u0435 \\u2014 \\u0441\\u0442\\u0440\\u0438\\u043c\\u0430 \\u043d\\u0435 \\u0431\\u044b\\u043b\\u043e',
twitchAlso:'\\u0421\\u0442\\u0440\\u0438\\u043c \\u0442\\u0430\\u043a\\u0436\\u0435 \\u0438\\u0434\\u0451\\u0442 \\u043d\\u0430 Twitch!',
twitchCta:'\\u0421\\u043c\\u043e\\u0442\\u0440\\u0435\\u0442\\u044c \\u043d\\u0430 Twitch'},
en:{followers:'Total Subscribers: ',
navTitle:'Navigation',navDesc:'Go to the page with all my links, socials, skin, and dev info.',
navCta:'Go to Links',
skinTitle:'My Minecraft Skin',skinDl:'Download Skin',
videosTitle:'Latest Videos',
tlTitle:'Channel Timeline',
expand:'Expand',collapse:'Collapse',
liveEmpty:'No stream right now',
liveSub:'Streams are usually on Fridays, 17:00\\u201319:00 MSK.',
legendYt:'YouTube',legendTw:'Twitch',legendBoth:'Both',legendPlanned:'Planned',
legendMissed:'Struck-out \\u2014 there was no stream',
twitchAlso:'Stream is also live on Twitch!',
twitchCta:'Watch on Twitch'}};

function fmtCount(n){if(n==null||isNaN(n))return'\\u2014';if(n>=1e6)return(n/1e6).toFixed(1).replace(/\\.0$/,'')+'M';if(n>=1e3)return(n/1e3).toFixed(1).replace(/\\.0$/,'')+'K';return String(n);}

function t(k){return(STR[S.lang]||STR.ru)[k]||'';}

function updateTexts(){
var s=STR[S.lang]||STR.ru;
setTxt('hero-tagline','');setTxt('totals',s.followers+'\\u2014');
setTxt('nav-title',s.navTitle);setTxt('nav-desc',s.navDesc);setTxt('go-links-text',s.navCta||'\\u041c\\u043e\\u0438 \\u0441\\u0441\\u044b\\u043b\\u043a\\u0438');
setTxt('skin-title',s.skinTitle);setTxt('skin-download-text',s.skinDl);
setTxt('videos-title',s.videosTitle);setTxt('timeline-title',s.tlTitle);
setTxt('tl-expand-text',s.expand);setTxt('tl-collapse-text',s.collapse);
setTxt('live-empty-title',s.liveEmpty);setTxt('live-empty-sub',s.liveSub);
setTxt('legend-yt',s.legendYt);setTxt('legend-tw',s.legendTw);
setTxt('legend-both',s.legendBoth);setTxt('legend-planned',s.legendPlanned);
setTxt('legend-missed',s.legendMissed);
setTxt('twitch-text',s.twitchAlso);setTxt('twitch-cta',s.twitchCta);
setTxt('go-links-text',s.navCta);
setTxt('go-links-btn-text-2',s.navCta);
var ytBtn=document.getElementById('cta-ytsub');if(ytBtn)ytBtn.style.display='';
var tgBtn=document.getElementById('cta-telegram');if(tgBtn)tgBtn.style.display='';
var spBtn=document.getElementById('cta-support');if(spBtn)spBtn.style.display='';
updateLangContent();
}
function setTxt(id,val){var e=document.getElementById(id);if(e&&val)e.textContent=val;}

function updateLangContent(){
document.querySelectorAll('[data-lang]').forEach(function(el){
el.style.display=el.getAttribute('data-lang')===S.lang?'':'none';
});
}

function setupOffline(){var w=document.getElementById('offline-warning');
function u(){if(w)w.classList.toggle('hidden',navigator.onLine);}
window.addEventListener('online',u);window.addEventListener('offline',u);u();}

function setupTimeline(){
document.querySelectorAll('#timeline details').forEach(function(d){
var icon=d.querySelector('.material-symbols-outlined');
d.addEventListener('toggle',function(){if(icon)icon.style.transform=d.open?'rotate(180deg)':'rotate(0deg)';});
});
var exp=document.getElementById('tl-expand');
var col=document.getElementById('tl-collapse');
if(exp)exp.onclick=function(){document.querySelectorAll('#timeline details').forEach(function(d){d.open=true;});};
if(col)col.onclick=function(){document.querySelectorAll('#timeline details').forEach(function(d){d.open=false;});};
}

function setupToggles(){
var tb=document.getElementById('theme-toggle-bottom');
var lb=document.getElementById('lang-toggle-bottom');
if(tb)tb.onclick=toggleTheme;
if(lb)lb.onclick=function(){S.lang=S.lang==='ru'?'en':'ru';localStorage.setItem('lang',S.lang);updateTexts();};
}

var MONTHS={ru:['\\u042f\\u043d\\u0432\\u0430\\u0440\\u044c','\\u0424\\u0435\\u0432\\u0440\\u0430\\u043b\\u044c','\\u041c\\u0430\\u0440\\u0442','\\u0410\\u043f\\u0440\\u0435\\u043b\\u044c','\\u041c\\u0430\\u0439','\\u0418\\u044e\\u043d\\u044c','\\u0418\\u044e\\u043b\\u044c','\\u0410\\u0432\\u0433\\u0443\\u0441\\u0442','\\u0421\\u0435\\u043d\\u0442\\u044f\\u0431\\u0440\\u044c','\\u041e\\u043a\\u0442\\u044f\\u0431\\u0440\\u044c','\\u041d\\u043e\\u044f\\u0431\\u0440\\u044c','\\u0414\\u0435\\u043a\\u0430\\u0431\\u0440\\u044c'],
en:['January','February','March','April','May','June','July','August','September','October','November','December']};
var WDAYS={ru:['\\u041f\\u043d','\\u0412\\u0442','\\u0421\\u0440','\\u0427\\u0442','\\u041f\\u0442','\\u0421\\u0431','\\u0412\\u0441'],
en:['Mon','Tue','Wed','Thu','Fri','Sat','Sun']};
var calState={year:new Date().getFullYear(),month:new Date().getMonth()};

function setupCalendar(){
document.getElementById('cal-prev').onclick=function(){calState.month--;if(calState.month<0){calState.month=11;calState.year--;}renderCal();};
document.getElementById('cal-next').onclick=function(){calState.month++;if(calState.month>11){calState.month=0;calState.year++;}renderCal();};
renderCal();
}
function renderCal(){
var m=MONTHS[S.lang]||MONTHS.ru,w=WDAYS[S.lang]||WDAYS.ru;
document.getElementById('cal-label').textContent=m[calState.month]+' '+calState.year;
var head=document.getElementById('cal-weekdays');
head.innerHTML=w.map(function(d){return'<div>'+d+'</div>';}).join('');
var first=new Date(calState.year,calState.month,1);
var startDow=(first.getDay()+6)%7;
var days=new Date(calState.year,calState.month+1,0).getDate();
var today=new Date();today.setHours(0,0,0,0);
var html='';
for(var i=0;i<startDow;i++)html+='<div></div>';
for(var d=1;d<=days;d++){
var dt=new Date(calState.year,calState.month,d);
var isToday=dt.getTime()===today.getTime();
var isPast=dt.getTime()<today.getTime();
var dow=(dt.getDay()+6)%7;
var cls=['cell'];
if(dow===4)cls.push('fri');
if(isToday)cls.push('today');
if(dow===4&&isPast)cls.push('passed','no-stream');
html+='<div class="'+cls.join(' ')+'"><div>'+d+'</div></div>';
}
document.getElementById('cal-grid').innerHTML=html;
}

var MONTHS={ru:['Январь','Февраль','Март','Апрель','Май','Июнь','Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'],en:['January','February','March','April','May','June','July','August','September','October','November','December']};
var WDAYS={ru:['Пн','Вт','Ср','Чт','Пт','Сб','Вс'],en:['Mon','Tue','Wed','Thu','Fri','Sat','Sun']};

function setupVideos(){
fetch('./data.json?t='+Date.now()).then(function(r){return r.json();}).then(function(data){
var vids=data.youtubeVideos||[];
var el=document.getElementById('carousel');
if(!el||!vids.length)return;
el.innerHTML='';
vids.forEach(function(v){
var a=document.createElement('a');
a.href='https://www.youtube.com/watch?v='+v.id;a.target='_blank';
a.className='flex-shrink-0 w-64 rounded-2xl overflow-hidden m3-shadow-md card';
a.innerHTML='<img src="'+v.thumbnailUrl+'" alt="'+v.title+'" class="w-full h-36 object-cover"><div class="p-3"><p class="text-sm font-medium leading-tight">'+v.title+'</p></div>';
el.appendChild(a);
});
var total=0;var fc=data.followerCounts||{};
Object.keys(fc).forEach(function(k){if(typeof fc[k]==='number')total+=fc[k];});
var ft=document.getElementById('totals');
if(ft)ft.textContent=(STR[S.lang]||STR.ru).followers+fmtCount(total);
}).catch(function(){});
}

function setupSkin(){
fetch('./streams_history.json?t='+Date.now()).then(function(r){return r.json();}).then(function(data){
if(!data.events||!data.events.length)return;
var byDate={};
data.events.forEach(function(e){
if(!byDate[e.date])byDate[e.date]={yt:false,tw:false,items:[]};
if(e.platform==='youtube')byDate[e.date].yt=true;
if(e.platform==='twitch')byDate[e.date].tw=true;
byDate[e.date].items.push(e);
});
renderCalWithEvents(byDate);
}).catch(function(){});
}
function renderCalWithEvents(byDate){
var m=MONTHS[S.lang]||MONTHS.ru,w=WDAYS[S.lang]||WDAYS.ru;
document.getElementById('cal-label').textContent=m[calState.month]+' '+calState.year;
document.getElementById('cal-weekdays').innerHTML=w.map(function(d){return'<div>'+d+'</div>';}).join('');
var first=new Date(calState.year,calState.month,1);
var startDow=(first.getDay()+6)%7;
var days=new Date(calState.year,calState.month+1,0).getDate();
var today=new Date();today.setHours(0,0,0,0);
var html='';
for(var i=0;i<startDow;i++)html+='<div></div>';
for(var d=1;d<=days;d++){
var dt=new Date(calState.year,calState.month,d);
var ds=dt.toISOString().slice(0,10);
var isToday=dt.getTime()===today.getTime();
var isPast=dt.getTime()<today.getTime();
var dow=(dt.getDay()+6)%7;
var cls=['cell'];
if(dow===4)cls.push('fri');
if(isToday)cls.push('today');
var dot='',chips='';
var info=byDate[ds];
if(info){
if(info.yt&&info.tw)dot='<span class="dot both"></span>';
else if(info.yt)dot='<span class="dot yt"></span>';
else if(info.tw)dot='<span class="dot tw"></span>';
var yt=info.items.find(function(x){return x.platform==='youtube';});
var tw=info.items.find(function(x){return x.platform==='twitch';});
if(yt)chips+='<a href="'+yt.url+'" target="_blank">YT</a>';
if(tw)chips+=(chips?' · ':'')+'<a href="'+tw.url+'" target="_blank">TW</a>';
}else if(dow===4){
if(isPast){cls.push('passed','no-stream');}else dot='<span class="dot planned"></span>';
}
html+='<div class="'+cls.join(' ')+'"><div>'+d+'</div>'+dot+(chips?'<div>'+chips+'</div>':'')+'</div>';
}
document.getElementById('cal-grid').innerHTML=html;
}

document.addEventListener('DOMContentLoaded',function(){
setTheme(S.theme);
updateTexts();
updateLangContent();
setupOffline();
setupTimeline();
setupToggles();
setupCalendar();
setupVideos();
setupSkin();
});
})();
"""

// MARK: - CSS (generated by Swift)

let siteCSS = """
:root{--primary:#BB86FC;--on-primary:#000;--primary-container:#4A148C;--surface-low:#1F1F1F;--surface:#2D2D2D;--outline:#8C8C8C;--primary-l:#6200EE;--on-primary-l:#FFF;--primary-container-l:#BB86FC;--surface-low-l:#F0F0F0;--surface-l:#E0E0E0;--outline-l:#BDBDBD;--bg:#000;--on-bg:#FFF;--bg-l:#FFF;--on-bg-l:#000;--live-red:#F00}
body{font-family:'Roboto',sans-serif;transition:background-color .3s,color .3s;display:flex;justify-content:center;align-items:flex-start;min-height:100vh;padding:20px;box-sizing:border-box;line-height:1.6}
.m3-shadow-md{box-shadow:0 3px 5px rgba(0,0,0,.2),0 1px 18px rgba(0,0,0,.12),0 6px 10px rgba(0,0,0,.14)}
body.dark-theme{background:var(--bg);color:var(--on-bg)}body.dark-theme .card{background:var(--surface-low);color:var(--on-bg)}
body.dark-theme .control-button{background:var(--surface-low);color:var(--on-bg)}
body.dark-theme .primary-button{background:var(--primary);color:var(--on-primary)}
body.dark-theme .primary-button:hover{background:var(--primary-container)}
body.dark-theme .support-button{background:#4CAF50;color:#FFF}
body.dark-theme .offline-warning{background:#FFB300;color:#212121}
body.light-theme{background:var(--bg-l);color:var(--on-bg-l)}body.light-theme .card{background:var(--surface-low-l);color:var(--on-bg-l)}
body.light-theme .control-button{background:var(--surface-low-l);color:var(--on-bg-l)}
body.light-theme .primary-button{background:var(--primary-l);color:var(--on-primary-l)}
body.light-theme .primary-button:hover{background:var(--primary-container-l)}
body.light-theme .support-button{background:#66BB6A;color:#FFF}
.card{border-radius:16px;transition:background-color .3s,transform .2s,box-shadow .2s;user-select:none}
.card:hover{transform:translateY(-3px);box-shadow:var(--primary) 0 4px 12px}
body.light-theme .card:hover{box-shadow:var(--primary-l) 0 4px 12px}
.live-indicator{background:var(--live-red)}
.yt-container{position:relative;width:100%;padding-bottom:56.25%;border-radius:16px;overflow:hidden}
.yt-container iframe{position:absolute;inset:0;width:100%;height:100%;border:0}
.md h2{font-size:1.6rem;font-weight:700;margin:1rem 0 .5rem}.md h3{font-size:1.25rem;font-weight:700;margin:1rem 0 .5rem}
.md p{margin:.5rem 0;line-height:1.7}.md ul{margin:.5rem 0 .75rem 1.15rem;list-style:disc}.md li{margin:.25rem 0}.md strong{font-weight:700}
.timeline-controls{display:flex;gap:10px;align-items:center;justify-content:space-between;margin:14px 0 8px}
.tl-buttons{display:flex;gap:8px}.tl-buttons .tl-btn{display:inline-flex;align-items:center;gap:.5rem;min-height:44px}
@media(max-width:640px){.tl-buttons .tl-btn{padding:8px;min-width:44px;justify-content:center}.tl-buttons .btn-text{display:none}}
#timeline{display:flex;flex-direction:column;gap:12px}
#timeline details.card{padding:14px 18px;border-radius:16px}
#timeline details.card summary{display:flex;align-items:center;justify-content:space-between;gap:12px;cursor:pointer;list-style:none}
#timeline details.card summary::-webkit-details-marker{display:none}
#timeline details.card summary .material-symbols-outlined{transition:transform .2s}
#timeline details[open] summary .material-symbols-outlined{transform:rotate(180deg)}
@media(min-width:992px){#timeline{max-width:980px;margin:8px auto 0}}
.home-grid{display:grid;gap:24px}.home-grid>*{min-width:0}
#links-cta{grid-area:links}#live{grid-area:cal;position:relative}#calendar{grid-area:cal2;background:transparent;box-shadow:none}#skin{grid-area:skin}
.home-grid.no-live{grid-template-columns:1fr;grid-template-areas:"links" "cal2" "skin"}
@media(min-width:992px){.home-grid.no-live{grid-template-columns:minmax(320px,420px) 1fr;grid-template-areas:"links cal2" "skin cal2"}}
.home-grid.has-live{grid-template-columns:1fr;grid-template-areas:"links" "cal" "cal2" "skin"}
@media(min-width:992px){.home-grid.has-live{grid-template-columns:minmax(320px,420px) 1fr;grid-template-areas:"links cal" "skin cal2"}}
.cal-nav{display:flex;align-items:center;justify-content:space-between;gap:8px;margin:10px 0}
.stream-cal-head,.stream-cal-grid{display:grid;grid-template-columns:repeat(7,minmax(0,1fr));gap:6px}
.stream-cal-head div{text-align:center;font-weight:600;opacity:.8}
.stream-cal-grid .cell{text-align:center;padding:8px 6px;border-radius:10px;border:1px solid var(--outline);min-height:46px;display:flex;flex-direction:column;justify-content:center;gap:3px}
body.light-theme .stream-cal-grid .cell{border-color:var(--outline-l)}
.stream-cal-grid .cell a{color:var(--primary);text-decoration:underline;font-size:.9rem}
.stream-cal-grid .cell.today{outline:2px solid var(--primary)}
.stream-cal-grid .cell.fri{background:rgba(187,134,252,.08)}
.stream-cal-grid .cell.passed.no-stream{opacity:.5;text-decoration:line-through}
.legend{display:flex;align-items:center;gap:10px;flex-wrap:wrap;justify-content:center;margin-top:10px;font-size:.95rem}
.dot{width:10px;height:10px;border-radius:50%;display:inline-block}
.dot.yt{background:#F44}.dot.tw{background:#9146FF}.dot.both{background:linear-gradient(90deg,#F44 0 50%,#9146FF 50% 100%)}.dot.planned{background:#2ECC71}
.legend .muted{opacity:.75}
#skin{position:relative}.skin-viewer{width:100%;aspect-ratio:1/1;background:transparent;border-radius:16px;display:grid;place-items:center}
.skin-controls{display:flex;justify-content:center;align-items:center;gap:10px;flex-wrap:wrap;margin:14px 0 10px}
.hero{text-align:center}.hero .avatar{width:112px;height:112px;border-radius:9999px;object-fit:cover;border:4px solid var(--primary);display:block;margin:0 auto 16px}
.hero h1{font-size:2.25rem;margin:0 0 6px}.hero p{margin:0 0 8px;opacity:.9}
.hero .followers{color:rgba(255,255,255,.72)!important}body.light-theme .hero .followers{color:rgba(0,0,0,.64)!important}
.hero .cta{display:flex;flex-wrap:wrap;justify-content:center;gap:12px;margin-top:12px}
.primary-button,.support-button{display:inline-flex;align-items:center;gap:.75rem}
@media(max-width:767px){#page-wrap{padding:0 16px}#page-wrap>.hero,#page-wrap>.about-card,#page-wrap>.home-grid{width:100%!important}#timeline{max-width:none}}
@media(max-width:452px){#links-cta .primary-button{width:100%;justify-content:center}}
@media(prefers-reduced-motion:reduce){#timeline details.card summary .material-symbols-outlined{transition:none}}
"""

// MARK: - Links Page CSS

let linksCSS = """
:root{--md-sys-color-primary-dark:#BB86FC;--md-sys-color-on-primary-dark:#000;--md-sys-color-primary-container-dark:#4A148C;--md-sys-color-on-primary-container-dark:#FFF;--md-sys-color-secondary-dark:#03DAC6;--md-sys-color-on-secondary-dark:#000;--md-sys-color-surface-dark:#000;--md-sys-color-on-surface-dark:#FFF;--md-sys-color-background-dark:#000;--md-sys-color-on-background-dark:#FFF;--md-sys-color-surface-container-low-dark:#1F1F1F;--md-sys-color-surface-container-dark:#2D2D2D;--md-sys-color-outline-dark:#8C8C8C;--md-sys-color-error-dark:#CF6679;--md-sys-color-primary-light:#6200EE;--md-sys-color-on-primary-light:#FFF;--md-sys-color-primary-container-light:#BB86FC;--md-sys-color-on-primary-container-light:#000;--md-sys-color-secondary-light:#03DAC6;--md-sys-color-on-secondary-light:#000;--md-sys-color-surface-light:#FFF;--md-sys-color-on-surface-light:#000;--md-sys-color-background-light:#FFF;--md-sys-color-on-background-light:#000;--md-sys-color-surface-container-low-light:#F0F0F0;--md-sys-color-surface-container-light:#E0E0E0;--md-sys-color-outline-light:#BDBDBD;--md-sys-color-error-light:#B00020;--live-indicator-red:#F00}
body{font-family:'Roboto',sans-serif;transition:background-color .3s,color .3s;display:flex;justify-content:center;align-items:flex-start;min-height:100vh;padding:20px;box-sizing:border-box;line-height:1.6;font-weight:400}
.m3-shadow-md{box-shadow:0 3px 5px rgba(0,0,0,.2),0 1px 18px rgba(0,0,0,.12),0 6px 10px rgba(0,0,0,.14)}
.m3-shadow-lg{box-shadow:0 6px 10px rgba(0,0,0,.2),0 3px 18px rgba(0,0,0,.12),0 9px 30px rgba(0,0,0,.14)}
body.dark-theme{background:var(--md-sys-color-background-dark);color:var(--md-sys-color-on-background-dark)}body.dark-theme .card{background:var(--md-sys-color-surface-container-low-dark);color:var(--md-sys-color-on-surface-dark)}
body.dark-theme .modal-content,body.dark-theme .dev-page-content{background:var(--md-sys-color-surface-container-dark);color:var(--md-sys-color-on-surface-dark)}
body.dark-theme .control-button{background:var(--md-sys-color-surface-container-low-dark);color:var(--md-sys-color-on-surface-dark)}
body.dark-theme .control-button:hover{background:var(--md-sys-color-surface-container-dark)}
body.dark-theme .primary-button{background:var(--md-sys-color-primary-dark);color:var(--md-sys-color-on-primary-dark)}
body.dark-theme .primary-button:hover{background:var(--md-sys-color-primary-container-dark);color:var(--md-sys-color-on-primary-container-dark)}
body.dark-theme .support-button{background:#4CAF50;color:var(--md-sys-color-on-primary-dark)}
body.dark-theme .support-button:hover{background:#388E3C}
body.dark-theme .offline-warning{background:#FFB300;color:#212121}
body.light-theme{background:var(--md-sys-color-background-light);color:var(--md-sys-color-on-background-light)}body.light-theme .card{background:var(--md-sys-color-surface-container-low-light);color:var(--md-sys-color-on-surface-light)}
body.light-theme .modal-content,body.light-theme .dev-page-content{background:var(--md-sys-color-surface-container-light);color:var(--md-sys-color-on-surface-light)}
body.light-theme .control-button{background:var(--md-sys-color-surface-container-low-light);color:var(--md-sys-color-on-surface-light)}
body.light-theme .control-button:hover{background:var(--md-sys-color-surface-container-light)}
body.light-theme .primary-button{background:var(--md-sys-color-primary-light);color:var(--md-sys-color-on-primary-light)}
body.light-theme .primary-button:hover{background:var(--md-sys-color-primary-container-light);color:var(--md-sys-color-on-primary-container-light)}
body.light-theme .support-button{background:#66BB6A;color:var(--md-sys-color-on-primary-light)}
body.light-theme .support-button:hover{background:#43A047}
.card{border-radius:16px;transition:background-color .3s,transform .2s,box-shadow .2s;user-select:none;-webkit-user-select:none}
.card:hover{transform:translateY(-3px);box-shadow:var(--md-sys-color-primary-dark) 0 4px 12px}
body.light-theme .card:hover{box-shadow:var(--md-sys-color-primary-light) 0 4px 12px}
.live-indicator{background:var(--live-indicator-red)}
.modal{display:none;position:fixed;z-index:100;left:0;top:0;width:100%;height:100%;background-color:rgba(0,0,0,.7);align-items:center;justify-content:center;backdrop-filter:blur(5px);animation:fadeInBackground .3s ease-out}
.modal.active{display:flex}
@keyframes fadeInBackground{from{background-color:rgba(0,0,0,0);backdrop-filter:blur(0)}to{background-color:rgba(0,0,0,.7);backdrop-filter:blur(5px)}}
.modal-content,.dev-page-content{padding:24px;border-radius:28px;max-width:90%;animation:fadeIn .3s ease-out;text-align:center;box-shadow:var(--md-sys-color-outline-dark) 0 8px 16px}
body.light-theme .modal-content,body.light-theme .dev-page-content{box-shadow:var(--md-sys-color-outline-light) 0 8px 16px}
@keyframes fadeIn{from{opacity:0;transform:scale(.9)}to{opacity:1;transform:scale(1)}}
.card.swiping-right{transform:translateX(60px) scale(.98);box-shadow:0 0 20px var(--md-sys-color-primary-dark);background:linear-gradient(to right,var(--md-sys-color-primary-dark) 0%,transparent 100%)}
body.light-theme .card.swiping-right{box-shadow:0 0 20px var(--md-sys-color-primary-light);background:linear-gradient(to right,var(--md-sys-color-primary-light) 0%,transparent 100%)}
.card.swiping-left{transform:translateX(-60px) scale(.98);box-shadow:0 0 20px var(--live-indicator-red);background:linear-gradient(to left,var(--live-indicator-red) 0%,transparent 100%)}
.content-container.grid-layout{display:grid;gap:24px}
#live-stream-section{grid-area:live}.main-links-block{grid-area:links}#minecraft-block{grid-area:skin}
.content-container.grid-layout.grid-has-live{grid-template-columns:1fr;grid-template-areas:"live" "links" "skin"}
.content-container.grid-layout.grid-no-live{grid-template-columns:1fr;grid-template-areas:"links" "skin"}
@media(min-width:768px){.content-container.grid-layout.grid-has-live{grid-template-columns:1fr 350px;grid-template-areas:"links live" "links skin"}.content-container.grid-layout.grid-no-live{grid-template-columns:1fr 350px;grid-template-areas:"links skin"}}
.youtube-video-container{position:relative;width:100%;padding-bottom:56.25%;height:0;overflow:hidden;border-radius:16px;box-shadow:var(--md-sys-color-outline-dark) 0 4px 8px}
body.light-theme .youtube-video-container{box-shadow:var(--md-sys-color-outline-light) 0 4px 8px}
.youtube-video-container iframe{position:absolute;inset:0;width:100%;height:100%}
#minecraft-block{display:flex;flex-direction:column;align-items:center;text-align:center}
#skin-viewer-container{display:grid;place-items:center;margin-left:auto;margin-right:auto;width:100%;height:20rem;box-shadow:none;background:transparent}
#skin-viewer-container>canvas{display:block;margin:0 auto}
@media(max-width:767px){#skin-viewer-container{width:clamp(240px,80vw,320px);height:clamp(240px,80vw,320px)}}
.skin-controls{display:flex;justify-content:center;align-items:center;gap:10px;flex-wrap:wrap;max-width:100%;margin-top:16px;margin-bottom:12px}
.mini-button{display:inline-flex;align-items:center;justify-content:center;height:34px;min-width:36px;padding:0 10px;border-radius:9999px;font-size:12px;line-height:1;cursor:pointer;border:1px solid transparent;transition:background-color .2s,color .2s,box-shadow .2s,border-color .2s;flex:0 0 auto}
.mini-button .mini-icon.material-symbols-outlined{font-size:18px;line-height:1}
.primary-button,.support-button,#twitch-link,#back-to-main-button{display:inline-flex;align-items:center;gap:.75rem}
.card .flex.items-center.select-none{gap:.75rem}
.icon-large{font-size:28px;line-height:1;margin:0}
.custom-icon-image{width:28px;height:28px;margin:0;object-fit:contain;flex-shrink:0}
.video-carousel::-webkit-scrollbar{height:8px}
.video-carousel::-webkit-scrollbar-track{background:rgba(255,255,255,.1);border-radius:10px}
body.light-theme .video-carousel::-webkit-scrollbar-track{background:rgba(0,0,0,.1)}
.video-carousel::-webkit-scrollbar-thumb{background:var(--md-sys-color-outline-dark);border-radius:10px}
body.light-theme .video-carousel::-webkit-scrollbar-thumb{background:var(--md-sys-color-outline-light)}
body.light-theme #skin-viewer-container,body.light-theme #skin-viewer-container img{box-shadow:none;background:transparent}
body.dark-theme .mini-button.active{background:var(--md-sys-color-primary-dark);color:var(--md-sys-color-on-primary-dark);border-color:transparent}
body.light-theme .mini-button.active{background:var(--md-sys-color-primary-light);color:var(--md-sys-color-on-primary-light);border-color:transparent}
.mini-button .material-symbols-outlined{color:currentColor}
"""

// MARK: - Links Page JS (ES module with inlined config + strings)

let linksJS = """
import * as skinview3d from 'https://cdn.jsdelivr.net/npm/skinview3d@3.4.1/+esm';

var appConfig={dataUrl:'/data.json',showLiveStreamSection:true,showProfileSection:true,showMinecraftSkinSection:true,showLinksSection:true,showYouTubeVideosSection:true,showSupportButton:true,developmentMode:true,showDevToggle:true,showLanguageToggle:true,showThemeToggle:true,supportUrl:'https://www.donationalerts.com/r/bezzubickmcplay'};
var profileConfig={name_key:'profileName',description_key:'profileDescription',avatar:'/assets/avatar.png',minecraftSkinUrl:'/assets/skin.png'};
var linksConfig=[
{label_key:'youtubeChannelLabel',url:'https://www.youtube.com/channel/UCm6mheCT60mZ5qlxG5r2GeA',icon:'play_arrow',order:1,isSocial:true,showSubscriberCount:true,platformId:'youtube',subscribeUrl:'https://www.youtube.com/channel/UCm6mheCT60mZ5qlxG5r2GeA?sub_confirmation=1',active:true},
{label_key:'telegramChannelLabel',url:'https://t.me/bezzubickmcplay',icon:'send',order:2,isSocial:true,showSubscriberCount:true,platformId:'telegram',active:true},
{label_key:'twitchChannelLabel',url:'https://www.twitch.tv/bezzubickmcplay',icon:'live_tv',order:3,isSocial:true,showSubscriberCount:true,platformId:'twitch',active:true},
{label_key:'tiktokProfileLabel',url:'https://www.tiktok.com/@bezzubickmcplay',icon:'music_note',order:4,isSocial:true,showSubscriberCount:false,platformId:'tiktok',active:true},
{label_key:'instagramProfileLabel',url:'https://www.instagram.com/bezzubickmcplay/',icon:'photo_camera',order:5,isSocial:true,showSubscriberCount:false,platformId:'instagram',active:true},
{label_key:'xTwitterProfileLabel',url:'https://x.com/bezzubickmcplay',icon:'public',order:6,isSocial:true,showSubscriberCount:false,platformId:'x',active:true},
{label_key:'vkGroupLabel',url:'https://vk.com/bezzubickmcplay',icon:'group',order:7,isSocial:true,showSubscriberCount:true,platformId:'vk_group',active:true},
{label_key:'vkPersonalPageLabel',url:'https://vk.com/bezzubickmcplay_official',icon:'person',order:8,isSocial:true,showSubscriberCount:true,platformId:'vk_personal',active:true}
];

var strings={en:{recentVideosTitle:'Recent Videos',modalTitle:'Welcome!',modalDescription:'Swipe right on a link card to subscribe, swipe left on YouTube links to open the latest video or a live stream.',gotItButton:'Got it!',themeLight:'Light Theme',themeDark:'Dark Theme',watchOnTwitch:'Watch on Twitch',totalFollowers:'Total Followers: ',minecraftTitle:'My Minecraft Skin',downloadSkin:'Download Skin',loading:'Loading...',supportButton:'Support Me',offlineMessage:'You are offline. Data might be outdated.',devPageTitle:'Developer Info',devLastUpdatedLabel:'Last Data Update:',devDataJsonContentLabel:'data.json Content:',devDebugInfoContentLabel:'API Debug Info:',backToMainText:'Back to Main Site',openLinkButton:'Open Link',closeButton:'Close',profileName:'BezzubickMCPlay',profileDescription:'Minecraft adventures | Streams | Creativity',avatarAlt:'BezzubickMCPlay profile avatar',twitchStreamAlsoLive:'Stream also live on Twitch!',youtubeChannelLabel:'YouTube Channel',telegramChannelLabel:'Telegram Channel',instagramProfileLabel:'Instagram Profile',xTwitterProfileLabel:'X (Twitter) Profile',twitchChannelLabel:'Twitch Channel',tiktokProfileLabel:'TikTok Profile',vkGroupLabel:'VK Group',vkPersonalPageLabel:'VK Personal Page'},
ru:{recentVideosTitle:'\\u041f\\u043e\\u0441\\u043b\\u0435\\u0434\\u043d\\u0438\\u0435 \\u0432\\u0438\\u0434\\u0435\\u043e',modalTitle:'\\u0414\\u043e\\u0431\\u0440\\u043e \\u043f\\u043e\\u0436\\u0430\\u043b\\u043e\\u0432\\u0430\\u0442\\u044c!',modalDescription:'\\u041f\\u0440\\u043e\\u0432\\u0435\\u0434\\u0438\\u0442\\u0435 \\u0432\\u043f\\u0440\\u0430\\u0432\\u043e \\u043f\\u043e \\u043a\\u0430\\u0440\\u0442\\u043e\\u0447\\u043a\\u0435 \\u0441\\u0441\\u044b\\u043b\\u043a\\u0438, \\u0447\\u0442\\u043e\\u0431\\u044b \\u043f\\u043e\\u0434\\u043f\\u0438\\u0441\\u0430\\u0442\\u044c\\u0441\\u044f. \\u041f\\u0440\\u043e\\u0432\\u0435\\u0434\\u0438\\u0442\\u0435 \\u0432\\u043b\\u0435\\u0432\\u043e \\u043f\\u043e YouTube-\\u0441\\u0441\\u044b\\u043b\\u043a\\u0430\\u043c, \\u0447\\u0442\\u043e\\u0431\\u044b \\u043e\\u0442\\u043a\\u0440\\u044b\\u0442\\u044c \\u043f\\u043e\\u0441\\u043b\\u0435\\u0434\\u043d\\u0435\\u0435 \\u0432\\u0438\\u0434\\u0435\\u043e \\u0438\\u043b\\u0438 \\u043f\\u0440\\u044f\\u043c\\u043e\\u0439 \\u044d\\u0444\\u0438\\u0440.',gotItButton:'\\u041f\\u043e\\u043d\\u044f\\u0442\\u043d\\u043e!',themeLight:'\\u0421\\u0432\\u0435\\u0442\\u043b\\u0430\\u044f \\u0442\\u0435\\u043c\\u0430',themeDark:'\\u0422\\u0451\\u043c\\u043d\\u0430\\u044f \\u0442\\u0435\\u043c\\u0430',watchOnTwitch:'\\u0421\\u043c\\u043e\\u0442\\u0440\\u0435\\u0442\\u044c \\u043d\\u0430 Twitch',totalFollowers:'\\u0412\\u0441\\u0435\\u0433\\u043e \\u043f\\u043e\\u0434\\u043f\\u0438\\u0441\\u0447\\u0438\\u043a\\u043e\\u0432: ',minecraftTitle:'\\u041c\\u043e\\u0439 \\u0441\\u043a\\u0438\\u043d Minecraft',downloadSkin:'\\u0421\\u043a\\u0430\\u0447\\u0430\\u0442\\u044c \\u0441\\u043a\\u0438\\u043d',loading:'\\u0417\\u0430\\u0433\\u0440\\u0443\\u0437\\u043a\\u0430...',supportButton:'\\u041f\\u043e\\u0434\\u0434\\u0435\\u0440\\u0436\\u0430\\u0442\\u044c \\u043c\\u0435\\u043d\\u044f',offlineMessage:'\\u0412\\u044b \\u043d\\u0435 \\u0432 \\u0441\\u0435\\u0442\\u0438. \\u0414\\u0430\\u043d\\u043d\\u044b\\u0435 \\u043c\\u043e\\u0433\\u0443\\u0442 \\u0431\\u044b\\u0442\\u044c \\u0443\\u0441\\u0442\\u0430\\u0440\\u0435\\u0432\\u0448\\u0438\\u043c\\u0438.',devPageTitle:'\\u0418\\u043d\\u0444\\u043e\\u0440\\u043c\\u0430\\u0446\\u0438\\u044f \\u0434\\u043b\\u044f \\u0440\\u0430\\u0437\\u0440\\u0430\\u0431\\u043e\\u0442\\u0447\\u0438\\u043a\\u043e\\u0432',devLastUpdatedLabel:'\\u041f\\u043e\\u0441\\u043b\\u0435\\u0434\\u043d\\u0435\\u0435 \\u043e\\u0431\\u043d\\u043e\\u0432\\u043b\\u0435\\u043d\\u0438\\u0435 \\u0434\\u0430\\u043d\\u043d\\u044b\\u0445:',devDataJsonContentLabel:'\\u0421\\u043e\\u0434\\u0435\\u0440\\u0436\\u0438\\u043c\\u043e\\u0435 data.json:',devDebugInfoContentLabel:'\\u041e\\u0442\\u043b\\u0430\\u0434\\u043e\\u0447\\u043d\\u0430\\u044f \\u0438\\u043d\\u0444\\u043e\\u0440\\u043c\\u0430\\u0446\\u0438\\u044f API:',backToMainText:'\\u041d\\u0430\\u0437\\u0430\\u0434 \\u043a \\u0441\\u0430\\u0439\\u0442\\u0443',openLinkButton:'\\u041e\\u0442\\u043a\\u0440\\u044b\\u0442\\u044c \\u0441\\u0441\\u044b\\u043b\\u043a\\u0443',closeButton:'\\u0417\\u0430\\u043a\\u0440\\u044b\\u0442\\u044c',profileName:'BezzubickMCPlay',profileDescription:'\\u041f\\u0440\\u0438\\u043a\\u043b\\u044e\\u0447\\u0435\\u043d\\u0438\\u044f \\u0432 Minecraft | \\u0421\\u0442\\u0440\\u0438\\u043c\\u044b | \\u0422\\u0432\\u043e\\u0440\\u0447\\u0435\\u0441\\u0442\\u0432\\u043e',avatarAlt:'\\u0410\\u0432\\u0430\\u0442\\u0430\\u0440 \\u043f\\u0440\\u043e\\u0444\\u0438\\u043b\\u044f BezzubickMCPlay',twitchStreamAlsoLive:'\\u0421\\u0442\\u0440\\u0438\\u043c \\u0442\\u0430\\u043a\\u0436\\u0435 \\u0438\\u0434\\u0451\\u0442 \\u043d\\u0430 Twitch!',youtubeChannelLabel:'YouTube \\u041a\\u0430\\u043d\\u0430\\u043b',telegramChannelLabel:'Telegram \\u041a\\u0430\\u043d\\u0430\\u043b',instagramProfileLabel:'\\u041f\\u0440\\u043e\\u0444\\u0438\\u043b\\u044c Instagram',xTwitterProfileLabel:'\\u041f\\u0440\\u043e\\u0444\\u0438\\u043b\\u044c X (Twitter)',twitchChannelLabel:'Twitch \\u041a\\u0430\\u043d\\u0430\\u043b',tiktokProfileLabel:'\\u041f\\u0440\\u043e\\u0444\\u0438\\u043b\\u044c TikTok',vkGroupLabel:'\\u0413\\u0440\\u0443\\u043f\\u043f\\u0430 VK',vkPersonalPageLabel:'\\u041b\\u0438\\u0447\\u043d\\u0430\\u044f \\u0441\\u0442\\u0440\\u0430\\u043d\\u0438\\u0446\\u0430 VK'}};

var DOM={};var state={theme:localStorage.getItem('theme')||'dark',lang:localStorage.getItem('lang')||(navigator.language.startsWith('ru')?'ru':'en'),data:{followerCounts:{},youtubeVideos:[],liveStream:{type:'none'}},skinViewerInstance:null,skinControlsEl:null,currentAnimKey:'idle'};

function setVisibility(el,visible){if(!el)return;el.classList.toggle('hidden',!visible);}
function applyTheme(theme){document.body.classList.remove('dark-theme','light-theme');document.body.classList.add(theme+'-theme');localStorage.setItem('theme',theme);if(DOM.themeIcon)DOM.themeIcon.textContent=theme==='dark'?'light_mode':'dark_dark';}
function formatCount(num){if(num==null||isNaN(num))return strings[state.lang].loading;if(num>=1e6)return(num/1e6).toFixed(1).replace(/\\.0$/,'')+'M';if(num>=1e3)return(num/1e3).toFixed(1).replace(/\\.0$/,'')+'K';return String(num);}
async function fetchAppData(){var url=(appConfig.dataUrl||'/data.json')+'?t='+Date.now();try{var res=await fetch(url,{cache:'no-store'});if(!res.ok)throw new Error('HTTP '+res.status);return await res.json();}catch(e){console.warn('[Data Fetch] Fallback -> /data.json',e);try{var res2=await fetch('/data.json?t='+Date.now(),{cache:'no-store'});if(res2.ok)return await res2.json();}catch(x){}return{followerCounts:{},youtubeVideos:[],liveStream:{type:'none'},debugInfo:{fetch_error:String(e)}};}}
function updateGridLiveState(){var has=appConfig.showLiveStreamSection&&state.data.liveStream&&state.data.liveStream.type!=='none';if(!DOM.contentGrid)return;DOM.contentGrid.classList.toggle('grid-has-live',has);DOM.contentGrid.classList.toggle('grid-no-live',!has);}
function updateLanguage(){var t=strings[state.lang];if(DOM.recentVideosTitle)DOM.recentVideosTitle.textContent=t.recentVideosTitle;if(DOM.minecraftTitle)DOM.minecraftTitle.textContent=t.minecraftTitle;if(DOM.downloadSkinText)DOM.downloadSkinText.textContent=t.downloadSkin;if(DOM.supportButtonText)DOM.supportButtonText.textContent=t.supportButton;if(DOM.offlineMessage)DOM.offlineMessage.textContent=t.offlineMessage;if(DOM.twitchLinkText)DOM.twitchLinkText.textContent=t.watchOnTwitch;if(DOM.twitchMessage)DOM.twitchMessage.textContent=t.twitchStreamAlsoLive;if(DOM.modalTitle)DOM.modalTitle.textContent=t.modalTitle;if(DOM.modalDescription)DOM.modalDescription.textContent=t.modalDescription;if(DOM.modalCloseBtn)DOM.modalCloseBtn.textContent=t.gotItButton;if(DOM.devTitle)DOM.devTitle.textContent=t.devPageTitle;if(DOM.devLastUpdatedLabel)DOM.devLastUpdatedLabel.textContent=t.devLastUpdatedLabel;if(DOM.devDataJsonContentLabel)DOM.devDataJsonContentLabel.textContent=t.devDataJsonContentLabel;if(DOM.devDebugInfoContentLabel)DOM.devDebugInfoContentLabel.textContent=t.devDebugInfoContentLabel;if(DOM.backToMainText)DOM.backToMainText.textContent=t.backToMainText;if(DOM.profileName)DOM.profileName.textContent=t[profileConfig.name_key];if(DOM.profileDescription)DOM.profileDescription.textContent=t[profileConfig.description_key];if(DOM.avatar)DOM.avatar.alt=t.avatarAlt;renderLinksSection(linksConfig);calculateAndDisplayTotalFollowers();}
function renderProfileSection(){setVisibility(DOM.profileSection,appConfig.showProfileSection);if(appConfig.showProfileSection&&DOM.avatar)DOM.avatar.src=profileConfig.avatar;}
function calculateAndDisplayTotalFollowers(){var t=strings[state.lang];var total=0;for(var i=0;i<linksConfig.length;i++){var link=linksConfig[i];if(link.isSocial&&link.showSubscriberCount&&link.active){var c=state.data.followerCounts?state.data.followerCounts[link.platformId]:0;if(typeof c==='number')total+=c;}}if(DOM.totalFollowers)DOM.totalFollowers.textContent=t.totalFollowers+' '+formatCount(total);}
function renderLinksSection(links){setVisibility(DOM.linksSection,appConfig.showLinksSection);if(!appConfig.showLinksSection||!DOM.linksSection)return;DOM.linksSection.innerHTML='';var sorted=links.filter(function(l){return l.active;}).sort(function(a,b){return a.order-b.order;});for(var i=0;i<sorted.length;i++){var link=sorted[i];var a=document.createElement('a');a.href=link.url;a.target='_blank';a.rel='noopener noreferrer';a.draggable=false;a.className='card relative flex items-center justify-between p-4 rounded-2xl m3-shadow-md '+(link.isSocial?'swipe-target':'')+' cursor-pointer';a.setAttribute('data-link-id',link.label_key);var count=state.data.followerCounts?state.data.followerCounts[link.platformId]:undefined;var showCount=link.isSocial&&link.showSubscriberCount;var iconHtml='<span class="material-symbols-outlined icon-large">'+(link.icon||'link')+'</span>';a.innerHTML='<div class="flex items-center select-none">'+iconHtml+'<div><span class="block text-lg font-medium">'+(strings[state.lang][link.label_key]||link.label_key)+'</span>'+(showCount?'<span class="text-sm text-gray-400 mr-2 follower-count-display">'+formatCount(count)+'</span>':'')+'</div></div>';DOM.linksSection.appendChild(a);}initSwipeGestures();}
function renderYouTubeVideosSection(){var videos=state.data.youtubeVideos||[];setVisibility(DOM.youtubeVideosSection,appConfig.showYouTubeVideosSection&&videos.length>0);if(!appConfig.showYouTubeVideosSection||videos.length===0||!DOM.videoCarousel)return;DOM.videoCarousel.innerHTML='';for(var i=0;i<videos.length;i++){var v=videos[i];var card=document.createElement('a');card.href='https://www.youtube.com/watch?v='+v.id;card.target='_blank';card.className='flex-shrink-0 w-64 rounded-2xl overflow-hidden m3-shadow-md card';card.innerHTML='<img src="'+v.thumbnailUrl+'" alt="'+v.title+'" class="w-full h-36 object-cover"><div class="p-3"><p class="text-sm font-medium leading-tight">'+v.title+'</p></div>';DOM.videoCarousel.appendChild(card);}DOM.videoCarousel.addEventListener('wheel',function(event){if(event.deltaY!==0){event.preventDefault();DOM.videoCarousel.scrollLeft+=event.deltaY;}},{passive:false});}
function renderLiveStream(){var info=state.data.liveStream;var has=appConfig.showLiveStreamSection&&info&&info.type!=='none';setVisibility(DOM.liveStreamSection,has);if(!has||!DOM.liveEmbed){updateGridLiveState();return;}if(info.type==='youtube'&&info.id){DOM.liveEmbed.src='https://www.youtube.com/embed/'+info.id+'?autoplay=1&mute=1';setVisibility(DOM.twitchNotification,!!info.twitchLive);if(info.twitchLive&&DOM.twitchLink)DOM.twitchLink.href='https://www.twitch.tv/'+info.twitchLive.twitchChannelName;}else if(info.type==='twitch'&&info.twitchChannelName){var parent=window.location.hostname||'localhost';DOM.liveEmbed.src='https://player.twitch.tv/?channel='+info.twitchChannelName+'&parent='+parent+'&autoplay=true&mute=1';setVisibility(DOM.twitchNotification,false);}updateGridLiveState();}
function disposeSkinViewer(){if(state.skinViewerInstance){state.skinViewerInstance.dispose();state.skinViewerInstance=null;}}
function showSkinFallbackImage(){setVisibility(DOM.minecraftBlock,true);disposeSkinViewer();if(!DOM.skinViewerContainer)return;DOM.skinViewerContainer.innerHTML='<img src="'+profileConfig.minecraftSkinUrl+'" alt="Minecraft skin" class="w-full h-full object-contain" />';}
function buildSkinControls(){if(state.skinControlsEl&&state.skinControlsEl.parentElement)state.skinControlsEl.parentElement.removeChild(state.skinControlsEl);var controls=document.createElement('div');controls.id='skin-animation-controls';controls.className='skin-controls';var options=[{key:'idle',icon:'accessibility',available:!!skinview3d.IdleAnimation},{key:'walk',icon:'directions_walk',available:!!skinview3d.WalkingAnimation},{key:'run',icon:'directions_run',available:!!skinview3d.RunningAnimation},{key:'rotate',icon:'autorenew',available:!!skinview3d.RotatingAnimation},{key:'stop',icon:'stop_circle',available:true}];for(var i=0;i<options.length;i++){var opt=options[i];if(!opt.available)continue;var btn=document.createElement('button');btn.type='button';btn.className='mini-button';btn.setAttribute('data-anim',opt.key);btn.innerHTML='<span class="material-symbols-outlined mini-icon" aria-hidden="true">'+opt.icon+'</span>';btn.addEventListener('click',(function(k){return function(){setSkinAnimation(k);};})(opt.key));controls.appendChild(btn);}var downloadWrapper=DOM.downloadSkinButton?DOM.downloadSkinButton.parentElement:null;if(downloadWrapper&&downloadWrapper.parentElement===DOM.minecraftBlock)DOM.minecraftBlock.insertBefore(controls,downloadWrapper);else DOM.skinViewerContainer.after(controls);state.skinControlsEl=controls;updateActiveAnimationButtons();}
function setSkinAnimation(key){if(!state.skinViewerInstance)return;var anim=null;try{if(key==='idle'&&skinview3d.IdleAnimation)anim=new skinview3d.IdleAnimation();else if(key==='walk'&&skinview3d.WalkingAnimation)anim=new skinview3d.WalkingAnimation();else if(key==='run'&&skinview3d.RunningAnimation)anim=new skinview3d.RunningAnimation();else if(key==='rotate'&&skinview3d.RotatingAnimation)anim=new skinview3d.RotatingAnimation();else if(key==='stop')anim=null;state.skinViewerInstance.animation=anim;state.currentAnimKey=key;updateActiveAnimationButtons();}catch(e){console.warn('[SkinViewer] Failed to set animation:',key,e);}}
function updateActiveAnimationButtons(){if(!state.skinControlsEl)return;var btns=state.skinControlsEl.querySelectorAll('.mini-button');btns.forEach(function(btn){btn.classList.toggle('active',btn.getAttribute('data-anim')===state.currentAnimKey);});}
async function initMinecraftSkinViewer(){if(!appConfig.showMinecraftSkinSection){setVisibility(DOM.minecraftBlock,false);disposeSkinViewer();return;}if(!DOM.skinCanvas||!DOM.skinViewerContainer){console.error('[SkinViewer] Missing elements');setVisibility(DOM.minecraftBlock,false);return;}try{await new Promise(function(r){requestAnimationFrame(function(){requestAnimationFrame(r);});});setVisibility(DOM.minecraftBlock,true);var width=Math.max(1,DOM.skinViewerContainer.offsetWidth||320);var height=Math.max(1,DOM.skinViewerContainer.offsetHeight||320);disposeSkinViewer();var viewer=new skinview3d.SkinViewer({canvas:DOM.skinCanvas,width:width,height:height});await viewer.loadSkin(profileConfig.minecraftSkinUrl);try{if(skinview3d.IdleAnimation){viewer.animation=new skinview3d.IdleAnimation();state.currentAnimKey='idle';}else if(skinview3d.WalkingAnimation){viewer.animation=new skinview3d.WalkingAnimation();state.currentAnimKey='walk';}else{state.currentAnimKey='stop';}}catch(e){}try{var controls=skinview3d.createOrbitControls(viewer);if(controls){controls.enablePan=false;controls.enableZoom=true;if(controls.target)controls.target.set(0,17,0);controls.update();}}catch(e){}state.skinViewerInstance=viewer;buildSkinControls();new ResizeObserver(function(){if(!state.skinViewerInstance)return;var w=Math.max(1,DOM.skinViewerContainer.offsetWidth||320);var h=Math.max(1,DOM.skinViewerContainer.offsetHeight||320);state.skinViewerInstance.setSize(w,h);}).observe(DOM.skinViewerContainer);}catch(e){console.error('[SkinViewer] init error, fallback PNG',e);showSkinFallbackImage();}}
function initSwipeGestures(){var cards=document.querySelectorAll('.swipe-target');for(var ci=0;ci<cards.length;ci++){(function(card){var startX=0,startY=0,currentX=0,currentY=0,pointerDown=false,swipeActive=false,suppressClick=false;var linkData=null;for(var li=0;li<linksConfig.length;li++){if(linksConfig[li].label_key===card.getAttribute('data-link-id')){linkData=linksConfig[li];break;}}if(!linkData)return;var onStart=function(e){pointerDown=true;swipeActive=false;startX=e.touches?e.touches[0].clientX:e.clientX;startY=e.touches?e.touches[0].clientY:e.clientY;card.style.transition='none';};var onMove=function(e){if(!pointerDown)return;currentX=e.touches?e.touches[0].clientX:e.clientX;currentY=e.touches?e.touches[0].clientY:e.clientY;var dx=currentX-startX,dy=currentY-startY;if(!swipeActive&&Math.abs(dx)>20&&Math.abs(dx)>Math.abs(dy)){swipeActive=true;e.preventDefault();}if(swipeActive){e.preventDefault();card.style.transform='translateX('+dx+'px)';card.classList.toggle('swiping-right',dx>0);card.classList.toggle('swiping-left',dx<0);}};var onEnd=function(){if(!pointerDown)return;pointerDown=false;card.style.transition='transform .2s ease, background-color .3s ease, box-shadow .2s ease';var dx=currentX-startX;if(swipeActive){var thr=card.offsetWidth*0.25;if(Math.abs(dx)>thr){if(dx>0){window.open(linkData.subscribeUrl||linkData.url,'_blank');}else{if(linkData.platformId==='youtube'){var live=state.data.liveStream;if(live&&live.type==='youtube'&&live.id)window.open('https://www.youtube.com/watch?v='+live.id,'_blank');else if(state.data.youtubeVideos&&state.data.youtubeVideos.length>0)window.open('https://www.youtube.com/watch?v='+state.data.youtubeVideos[0].id,'_blank');else window.open(linkData.url,'_blank');}else{window.open(linkData.url,'_blank');}}}}card.style.transform='translateX(0)';card.classList.remove('swiping-left','swiping-right');if(swipeActive){suppressClick=true;setTimeout(function(){suppressClick=false;},0);}swipeActive=false;};var onClick=function(e){if(suppressClick){e.preventDefault();e.stopPropagation();}};card.addEventListener('mousedown',onStart);card.addEventListener('mousemove',onMove);card.addEventListener('mouseup',onEnd);card.addEventListener('mouseleave',onEnd);card.addEventListener('touchstart',onStart,{passive:false});card.addEventListener('touchmove',onMove,{passive:false});card.addEventListener('touchend',onEnd);card.addEventListener('click',onClick);})(cards[ci]);}}
function setupSupportButton(){setVisibility(DOM.supportSection,appConfig.showSupportButton);if(appConfig.showSupportButton&&DOM.supportButton)DOM.supportButton.href=appConfig.supportUrl||'#';}
function setupOfflineBanner(){var upd=function(){setVisibility(DOM.offlineWarning,!navigator.onLine);};window.addEventListener('online',upd);window.addEventListener('offline',upd);upd();}
function manageFirstVisitModal(){if(!DOM.firstVisitModal||!DOM.modalCloseBtn)return;var seen=localStorage.getItem('visited_modal');if(!seen){DOM.firstVisitModal.classList.add('active');DOM.modalCloseBtn.onclick=function(){DOM.firstVisitModal.classList.remove('active');localStorage.setItem('visited_modal','true');};}}
async function downloadMinecraftSkin(ev){try{ev&&ev.preventDefault&&ev.preventDefault();ev&&ev.stopPropagation&&ev.stopPropagation();var url=new URL(profileConfig.minecraftSkinUrl,location.href).toString();var res=await fetch(url,{cache:'no-store'});if(!res.ok)throw new Error('HTTP '+res.status);var blob=await res.blob();var blobUrl=URL.createObjectURL(blob);var a=document.createElement('a');a.href=blobUrl;a.download='minecraft_skin.png';document.body.appendChild(a);a.click();a.remove();setTimeout(function(){URL.revokeObjectURL(blobUrl);},1000);}catch(e){var fallback=new URL(profileConfig.minecraftSkinUrl,location.href).toString();var a2=document.createElement('a');a2.href=fallback;a2.target='_blank';document.body.appendChild(a2);a2.click();a2.remove();}}
function applyMockFromQuery(){var p=new URLSearchParams(location.search);var s=p.get('mockLive');if(!s)return;if(s==='none'){state.data.liveStream={type:'none'};return;}var parts=s.split(':');var kind=parts[0],a=parts[1],b=parts[2];if(kind==='both'){state.data.liveStream={type:'youtube',id:a||'e7K5ijK2VOo',title:'Mock YT',youtubeChannelId:'mock',twitchLive:{type:'twitch',id:'mock',title:'Mock TW',twitchChannelName:b||'monstercat'}};}else if(kind==='youtube'){state.data.liveStream={type:'youtube',id:a||'e7K5ijK2VOo',title:'Mock YT',youtubeChannelId:'mock'};}else if(kind==='twitch'){state.data.liveStream={type:'twitch',id:'mock',title:'Mock TW',twitchChannelName:a||'monstercat'};}}

document.addEventListener('DOMContentLoaded',async function(){
DOM.contentGrid=document.getElementById('content-grid');DOM.offlineWarning=document.getElementById('offline-warning');DOM.offlineMessage=document.getElementById('offline-message');DOM.liveStreamSection=document.getElementById('live-stream-section');DOM.liveEmbed=document.getElementById('live-embed');DOM.twitchNotification=document.getElementById('twitch-notification');DOM.twitchMessage=document.getElementById('twitch-message');DOM.twitchLink=document.getElementById('twitch-link');DOM.twitchLinkText=document.getElementById('twitch-link-text');DOM.profileSection=document.getElementById('profile-section');DOM.avatar=document.getElementById('avatar');DOM.profileName=document.getElementById('profile-name');DOM.profileDescription=document.getElementById('profile-description');DOM.totalFollowers=document.getElementById('total-followers');DOM.linksSection=document.getElementById('links-section');DOM.supportSection=document.getElementById('support-section');DOM.supportButton=document.getElementById('support-button');DOM.supportButtonText=document.getElementById('support-button-text');DOM.minecraftBlock=document.getElementById('minecraft-block');DOM.minecraftTitle=document.getElementById('minecraft-title');DOM.skinViewerContainer=document.getElementById('skin-viewer-container');DOM.skinCanvas=document.getElementById('skin-canvas');DOM.downloadSkinButton=document.getElementById('download-skin-button');DOM.downloadSkinText=document.getElementById('download-skin-text');DOM.youtubeVideosSection=document.getElementById('youtube-videos-section');DOM.recentVideosTitle=document.getElementById('recent-videos-title');DOM.videoCarousel=document.getElementById('video-carousel');DOM.themeToggle=document.getElementById('theme-toggle');DOM.themeIcon=document.getElementById('theme-icon');DOM.languageToggle=document.getElementById('language-toggle');DOM.devToggle=document.getElementById('dev-toggle');DOM.backToMainButton=document.getElementById('back-to-main-button');DOM.devTitle=document.getElementById('dev-title');DOM.devLastUpdatedLabel=document.getElementById('dev-last-updated-label');DOM.devLastUpdated=document.getElementById('dev-last-updated');DOM.devDataJsonContentLabel=document.getElementById('dev-data-json-content-label');DOM.devDataJsonContent=document.getElementById('dev-data-json-content');DOM.devDebugInfoContentLabel=document.getElementById('dev-debug-info-content-label');DOM.devDebugInfoContent=document.getElementById('dev-debug-info-content');DOM.backToMainText=document.getElementById('back-to-main-text');DOM.firstVisitModal=document.getElementById('first-visit-modal');DOM.modalTitle=document.getElementById('modal-title');DOM.modalDescription=document.getElementById('modal-description');DOM.modalCloseBtn=document.getElementById('modal-close');

state.data=await fetchAppData();applyMockFromQuery();renderProfileSection();applyTheme(state.theme);updateLanguage();renderYouTubeVideosSection();renderLiveStream();updateGridLiveState();await initMinecraftSkinViewer();setupSupportButton();setupOfflineBanner();manageFirstVisitModal();
if(DOM.themeToggle)DOM.themeToggle.addEventListener('click',function(){state.theme=state.theme==='dark'?'light':'dark';applyTheme(state.theme);});
if(DOM.languageToggle)DOM.languageToggle.addEventListener('click',function(){state.lang=state.lang==='en'?'ru':'en';localStorage.setItem('lang',state.lang);updateLanguage();});
if(DOM.downloadSkinButton)DOM.downloadSkinButton.addEventListener('click',downloadMinecraftSkin);
});
"""

// MARK: - Theme

extension Theme where Site == BezzubickSite {
    static var custom: Theme {
        Theme(htmlFactory: BezzubickHTMLFactory(), resourcePaths: ["Resources/"])
    }
}

// MARK: - HTML Factory

struct BezzubickHTMLFactory: HTMLFactory {
    typealias Site = BezzubickSite

    func makeIndexHTML(for index: Index, context: PublishingContext<BezzubickSite>) throws -> HTML {
        let (_, heroes) = parseLinks()
        let aboutIntro = readBilingualMarkdown("Content/about-intro.md")
        let aboutOutro = readBilingualMarkdown("Content/about-outro.md")
        let timeline = readTimeline()

        let timelineNodes: [Node<HTML.BodyContext>] = timeline.enumerated().map { idx, entry -> Node<HTML.BodyContext> in
            .details(.class("timeline card m3-shadow-md"),
                idx == 0 ? .open(true) : .empty,
                .summary(
                    .span(.class("text-lg font-medium"), .raw("<span data-lang=\"ru\">\(entry.year) — \(entry.titleRu)</span><span data-lang=\"en\" style=\"display:none\">\(entry.year) — \(entry.titleEn)</span>")),
                    .span(.class("material-symbols-outlined"), .text("expand_more"))
                ),
                .div(.class("md"), .raw("<div data-lang=\"ru\">\(md2html(entry.bodyRu))</div><div data-lang=\"en\" style=\"display:none\">\(md2html(entry.bodyEn))</div>"))
            )
        }

        let heroBtns: [Node<HTML.BodyContext>] = heroes.map { btn in
            .a(.id("cta-\(btn.label.hashValue)"), .href(btn.url),
               .class("rounded-full px-6 py-3 font-medium m3-shadow-md \(btn.style == "support" ? "support-button" : "primary-button")"),
               .span(.class("material-symbols-outlined"), .text(btn.icon)),
               .span(.text(btn.label)))
        }

        return HTML(
            .lang(.russian),
            .head(for: index, on: context.site),
            .body(.class("dark-theme"),
                .raw("""
                <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,1,0&display=swap" rel="stylesheet" />
                <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet" />
                <script src="https://cdn.tailwindcss.com"></script>
                <style>\(siteCSS)</style>
                """),
                .div(.id("page-wrap"), .class("w-full max-w-5xl mx-auto p-4 sm:p-6 lg:p-8"),
                    .div(.id("offline-warning"), .class("hidden fixed top-0 left-0 w-full p-3 text-center font-medium z-50 offline-warning rounded-b-lg shadow-lg"),
                         .span(.text("Вы не в сети. Данные могут быть устаревшими."))),
                    .section(.class("hero card m3-shadow-md p-6"),
                        .img(.src("/assets/avatar.png"), .alt("Avatar"), .class("avatar m3-shadow-md")),
                        .h1(.text("Bezzubick MCPlay")),
                        .p(.id("hero-tagline")),
                        .div(.id("totals"), .class("followers"), .text("Всего подписчиков: —")),
                        .div(.class("cta hero-cta"), .group(heroBtns))
                    ),
                    .section(.class("about-card card m3-shadow-md p-6 mt-6"),
                        .div(.id("about-intro"), .class("md"), .raw(aboutIntro.rawRu)),
                        .div(.class("timeline-controls"),
                            .h3(.id("timeline-title"), .class("text-xl font-bold"), .text("Лента канала")),
                            .div(.class("tl-buttons"),
                                .button(.id("tl-expand"), .class("primary-button rounded-full px-4 py-2 font-medium m3-shadow-md tl-btn"),
                                        .attribute(named: "aria-label", value: "Expand"),
                                        .span(.class("material-symbols-outlined"), .text("unfold_more")),
                                        .span(.id("tl-expand-text"), .class("btn-text"), .text("Развернуть"))),
                                .button(.id("tl-collapse"), .class("control-button rounded-full px-4 py-2 font-medium m3-shadow-md tl-btn"),
                                        .attribute(named: "aria-label", value: "Collapse"),
                                        .span(.class("material-symbols-outlined"), .text("unfold_less")),
                                        .span(.id("tl-collapse-text"), .class("btn-text"), .text("Свернуть")))
                            )
                        ),
                        .div(.id("timeline"), .group(timelineNodes)),
                        .div(.id("about-outro"), .class("md mt-4"), .raw(aboutOutro.rawRu))
                    ),
                    .div(.id("content-grid"), .class("home-grid mt-6 no-live"),
                        .section(.class("card m3-shadow-md p-6"), .id("links-cta"),
                            .h2(.id("nav-title"), .class("text-xl font-bold mb-2"), .text("Навигация")),
                            .p(.id("nav-desc"), .class("text-gray-400 mb-4"), .text("Перейдите на страницу со всеми моими ссылками, соцсетями, скином и dev‑инфо.")),
                            .a(.id("go-links-btn-2"), .href("/links/"), .class("rounded-full px-6 py-3 font-medium m3-shadow-md primary-button"),
                               .span(.class("material-symbols-outlined"), .text("link")),
                               .span(.text("Перейти к ссылкам")))
                        ),
                        .section(.id("live"), .class("relative overflow-hidden p-0 hidden"),
                            .div(.class("yt-container"), .id("live-embed-wrap"),
                                 .iframe(.id("live-embed"),
                                         .attribute(named: "allow", value: "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"),
                                         .attribute(named: "allowfullscreen", value: ""))),
                            .div(.id("live-badge"), .class("absolute top-3 left-3 px-3 py-1 rounded-full text-white text-xs font-bold live-indicator m3-shadow-md"), .text("LIVE")),
                            .div(.id("twitch-notice"), .class("hidden mt-4 p-4 rounded-2xl text-sm text-center card m3-shadow-md"),
                                 .p(.id("twitch-text"), .class("mb-2"), .text("Стрим также идёт на Twitch!")),
                                 .a(.id("twitch-link"), .href("#"), .target(.blank), .class("primary-button inline-flex items-center px-4 py-2 rounded-full font-medium"),
                                    .span(.class("material-symbols-outlined text-base"), .text("videocam")),
                                    .span(.id("twitch-cta"), .text("Смотреть на Twitch"))))
                        ),
                        .section(.id("calendar"), .class("p-6"),
                            .div(.class("md text-center mb-2"),
                                 .h3(.id("live-empty-title"), .text("Сейчас стрима нет")),
                                 .p(.id("live-empty-sub"), .text("Обычно стримы по пятницам, 17:00–19:00 МСК."))),
                            .div(.class("cal-nav"),
                                 .button(.id("cal-prev"), .class("control-button p-2 rounded-full m3-shadow-md"),
                                         .attribute(named: "aria-label", value: "Previous month"),
                                         .span(.class("material-symbols-outlined"), .text("chevron_left"))),
                                 .div(.id("cal-label"), .class("font-medium")),
                                 .button(.id("cal-next"), .class("control-button p-2 rounded-full m3-shadow-md"),
                                         .attribute(named: "aria-label", value: "Next month"),
                                         .span(.class("material-symbols-outlined"), .text("chevron_right")))),
                            .div(.id("cal-weekdays"), .class("stream-cal-head")),
                            .div(.id("cal-grid"), .class("stream-cal-grid")),
                            .div(.class("legend"),
                                 .span(.class("dot yt")), .span(.id("legend-yt"), .text("YouTube")),
                                 .span(.class("dot tw")), .span(.id("legend-tw"), .text("Twitch")),
                                 .span(.class("dot both")), .span(.id("legend-both"), .text("Оба")),
                                 .span(.class("dot planned")), .span(.id("legend-planned"), .text("Потенциальный")),
                                 .span(.class("muted"), .id("legend-missed"), .text("Зачёркнутые — стрима не было")))
                        ),
                        .section(.id("skin"), .class("card m3-shadow-md p-6"),
                            .h2(.id("skin-title"), .class("text-xl font-bold text-center mb-4"), .text("Мой скин Minecraft")),
                            .div(.id("skin-viewer"), .class("skin-viewer")),
                            .div(.id("skin-controls"), .class("skin-controls")),
                            .div(.class("flex justify-center mt-2"),
                                 .a(.id("download-skin"), .href("/assets/skin.png"),
                                    .class("primary-button rounded-full px-6 py-3 font-medium m3-shadow-md"),
                                    .attribute(named: "download", value: "minecraft_skin.png"),
                                    .attribute(named: "rel", value: "noopener"),
                                    .span(.class("material-symbols-outlined"), .text("download")),
                                    .span(.id("skin-download-text"), .text("Скачать скин"))))
                        )
                    ),
                    .section(.class("mb-8 mt-6"),
                        .h2(.id("videos-title"), .class("text-xl font-bold mb-3"), .text("Последние видео")),
                        .div(.id("carousel"), .class("flex overflow-x-auto space-x-4 pb-4 video-carousel scroll-smooth"))
                    ),
                    .div(.class("flex justify-center items-center space-x-4 mt-8 mb-8"),
                        .button(.id("theme-toggle-bottom"), .class("control-button p-3 rounded-full m3-shadow-md"),
                                .attribute(named: "aria-label", value: "Toggle theme"),
                                .span(.id("theme-icon-bottom"), .class("material-symbols-outlined"), .text("light_mode"))),
                        .button(.id("lang-toggle-bottom"), .class("control-button p-3 rounded-full m3-shadow-md"),
                                .attribute(named: "aria-label", value: "Toggle language"),
                                .span(.id("lang-icon-bottom"), .class("material-symbols-outlined"), .text("translate")))
                    )
                ),
                .raw("<script>\(siteJS)</script>")
            )
        )
    }

    func makeSectionHTML(for section: Section<BezzubickSite>, context: PublishingContext<BezzubickSite>) throws -> HTML { try makeIndexHTML(for: context.index, context: context) }
    func makeItemHTML(for item: Item<BezzubickSite>, context: PublishingContext<BezzubickSite>) throws -> HTML { try makeIndexHTML(for: context.index, context: context) }
    func makePageHTML(for page: Page, context: PublishingContext<BezzubickSite>) throws -> HTML {
        if page.path == "links" { return try makeLinksPage(for: page, context: context) }
        return try makeIndexHTML(for: context.index, context: context)
    }
    func makeTagListHTML(for page: TagListPage, context: PublishingContext<BezzubickSite>) throws -> HTML? { try makeIndexHTML(for: context.index, context: context) }
    func makeTagDetailsHTML(for page: TagDetailsPage, context: PublishingContext<BezzubickSite>) throws -> HTML? { try makeIndexHTML(for: context.index, context: context) }

    func makeLinksPage(for page: Page, context: PublishingContext<BezzubickSite>) throws -> HTML {
        HTML(
            .lang(.russian),
            .head(
                .meta(.charset(.utf8)),
                .meta(.name("viewport"), .content("width=device-width, initial-scale=1")),
                .link(.rel(.icon), .href("https://httydcraft.github.io/BezzubickMCPlay/assets/avatar.png"), .type("image/png")),
                .title("BezzubickMCPlay | Links"),
                .meta(.name("description"), .content("BezzubickMCPlay: Minecraft adventures, streams, latest videos, social links, and my skin.")),
                .link(.href("https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,1,0"), .rel(.stylesheet)),
                .link(.href("https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700"), .rel(.stylesheet)),
                .script(.src("https://cdn.tailwindcss.com")),
                .raw("<style>\(linksCSS)</style>")
            ),
            .body(.class("dark-theme"),
                .div(.id("app"), .class("w-full max-w-4xl mx-auto p-4 sm:p-6 lg:p-8"),
                    .div(.id("offline-warning"), .class("hidden fixed top-0 left-0 w-full p-3 text-center font-medium z-50 offline-warning rounded-b-lg shadow-lg"),
                        .span(.id("offline-message"))),
                    .div(.id("main-view"),
                        .section(.id("profile-section"), .class("text-center mb-8 hidden"),
                            .img(.id("avatar"), .class("w-28 h-28 rounded-full mx-auto mb-4 border-4 border-purple-500 object-cover m3-shadow-md"), .src("/assets/avatar.png"), .alt("Avatar")),
                            .h1(.id("profile-name"), .class("text-4xl font-bold mb-2")),
                            .p(.id("profile-description"), .class("text-lg text-gray-400 mb-4")),
                            .div(.id("total-followers"), .class("text-xl font-medium text-purple-400"))),
                        .div(.id("content-grid"), .class("content-container grid-layout grid-no-live"),
                            .section(.id("live-stream-section"), .class("relative rounded-2xl overflow-hidden m3-shadow-md hidden"),
                                .div(.class("youtube-video-container"),
                                    .iframe(.id("live-embed"), .attribute(named: "frameborder", value: "0"),
                                        .attribute(named: "allow", value: "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"),
                                        .attribute(named: "allowfullscreen", value: ""))),
                                .div(.class("absolute top-3 left-3 px-3 py-1 rounded-full text-white text-xs font-bold live-indicator m3-shadow-md"), .text("LIVE")),
                                .div(.id("twitch-notification"), .class("hidden mt-4 p-4 rounded-2xl text-sm text-center card m3-shadow-md"),
                                    .p(.id("twitch-message"), .class("mb-2")),
                                    .a(.id("twitch-link"), .href("#"), .target(.blank), .class("primary-button px-4 py-2 rounded-full font-medium"), .rel(.noopener),
                                        .span(.class("material-symbols-outlined text-base"), .text("videocam")),
                                        .span(.id("twitch-link-text"))))),
                            .div(.class("main-links-block"),
                                .section(.id("links-section"), .class("space-y-4 hidden")),
                                .section(.id("support-section"), .class("flex justify-center hidden mt-6"),
                                    .a(.id("support-button"), .href("#"), .target(.blank), .class("support-button px-6 py-3 rounded-full font-medium m3-shadow-md"),
                                        .span(.class("material-symbols-outlined"), .text("favorite")),
                                        .span(.id("support-button-text"))))),
                            .section(.id("minecraft-block"), .class("hidden"),
                                .h2(.id("minecraft-title"), .class("text-xl font-bold text-center mb-4")),
                                .div(.id("skin-viewer-container"),
                                    .element(named: "canvas", nodes: [.id("skin-canvas")])),
                                .div(.class("flex justify-center mt-3 mb-1"),
                                    .button(.id("download-skin-button"), .class("primary-button px-6 py-3 rounded-full font-medium m3-shadow-md"),
                                        .span(.class("material-symbols-outlined"), .text("download")),
                                        .span(.id("download-skin-text")))))),
                        .section(.id("youtube-videos-section"), .class("mb-8 hidden"),
                            .h2(.id("recent-videos-title"), .class("text-xl font-bold mb-4")),
                            .div(.id("video-carousel"), .class("flex overflow-x-auto space-x-4 pb-4 video-carousel scroll-smooth")))),
                    .div(.id("dev-view"), .class("hidden w-full max-w-4xl mx-auto py-8"),
                        .h2(.id("dev-title"), .class("text-3xl font-bold text-center mb-6")),
                        .div(.class("dev-page-content p-6 rounded-2xl m3-shadow-md"),
                            .p(.class("mb-4"),
                                .span(.id("dev-last-updated-label"), .class("font-medium")),
                                .text(" "),
                                .span(.id("dev-last-updated"), .class("text-purple-400"))),
                            .h3(.id("dev-data-json-content-label"), .class("text-xl font-bold text-left mb-3")),
                            .element(named: "pre", nodes: [
                                .attribute(named: "class", value: "text-left bg-gray-900 p-4 rounded-lg overflow-x-auto text-sm"),
                                .attribute(named: "style", value: "max-height:500px;white-space:pre-wrap;word-wrap:break-word"),
                                .element(named: "code", nodes: [.id("dev-data-json-content")])]),
                            .h3(.id("dev-debug-info-content-label"), .class("text-xl font-bold text-left mt-6 mb-3")),
                            .element(named: "pre", nodes: [
                                .attribute(named: "class", value: "text-left bg-gray-900 p-4 rounded-lg overflow-x-auto text-sm"),
                                .attribute(named: "style", value: "max-height:300px;white-space:pre-wrap;word-wrap:break-word"),
                                .element(named: "code", nodes: [.id("dev-debug-info-content")])])),
                        .div(.class("flex justify-center mt-8"),
                            .button(.id("back-to-main-button"), .class("primary-button px-6 py-3 rounded-full font-medium m3-shadow-md"),
                                .span(.class("material-symbols-outlined"), .text("arrow_back")),
                                .span(.id("back-to-main-text"))))),
                    .div(.class("flex justify-center items-center space-x-4 mt-8 mb-8"),
                        .button(.id("theme-toggle"), .class("control-button p-3 rounded-full m3-shadow-md flex items-center justify-center"),
                            .attribute(named: "aria-label", value: "Toggle theme"),
                            .span(.id("theme-icon"), .class("material-symbols-outlined"), .text("light_mode"))),
                        .button(.id("language-toggle"), .class("control-button p-3 rounded-full m3-shadow-md flex items-center justify-center"),
                            .attribute(named: "aria-label", value: "Toggle language"),
                            .span(.class("material-symbols-outlined"), .text("language"))),
                        .button(.id("dev-toggle"), .class("control-button p-3 rounded-full m3-shadow-md flex items-center justify-center hidden"),
                            .attribute(named: "aria-label", value: "Toggle developer view"),
                            .span(.class("material-symbols-outlined"), .text("code")))),
                    .div(.id("first-visit-modal"), .class("modal"),
                        .attribute(named: "role", value: "dialog"),
                        .attribute(named: "aria-modal", value: "true"),
                        .attribute(named: "aria-labelledby", value: "modal-title"),
                        .div(.class("modal-content"),
                            .h3(.id("modal-title"), .class("text-2xl font-bold mb-4")),
                            .p(.id("modal-description"), .class("text-base mb-6")),
                            .button(.id("modal-close"), .class("primary-button px-6 py-3 rounded-full font-medium"))))),
                .element(named: "script", nodes: [
                    .attribute(named: "type", value: "module"),
                    .raw(linksJS)])
            )
        )
    }
}

// MARK: - Publish

try BezzubickSite().publish(withTheme: .custom)
