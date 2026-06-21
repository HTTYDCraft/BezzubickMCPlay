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
    func makePageHTML(for page: Page, context: PublishingContext<BezzubickSite>) throws -> HTML { try makeIndexHTML(for: context.index, context: context) }
    func makeTagListHTML(for page: TagListPage, context: PublishingContext<BezzubickSite>) throws -> HTML? { try makeIndexHTML(for: context.index, context: context) }
    func makeTagDetailsHTML(for page: TagDetailsPage, context: PublishingContext<BezzubickSite>) throws -> HTML? { try makeIndexHTML(for: context.index, context: context) }
}

// MARK: - Publish

try BezzubickSite().publish(withTheme: .custom)
