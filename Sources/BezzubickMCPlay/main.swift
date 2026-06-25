import Publish
import Plot
import Foundation

let baseURL = "/BezzubickMCPlay"

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
    let lines = md.components(separatedBy: "\n")
    var result: [String] = []
    var inList = false
    for line in lines {
        let t = line.trimmingCharacters(in: .whitespaces)
        if t.isEmpty {
            if inList { result.append("</ul>"); inList = false }
            result.append(""); continue
        }
        let inline: (String) -> String = { s in
            s.replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "<strong>$1</strong>", options: .regularExpression)
        }
        if t.hasPrefix("#### ") { result.append("<h4>\(inline(String(t.dropFirst(5))))</h4>"); continue }
        if t.hasPrefix("### ") { result.append("<h3>\(inline(String(t.dropFirst(4))))</h3>"); continue }
        if t.hasPrefix("## ") { result.append("<h2>\(inline(String(t.dropFirst(3))))</h2>"); continue }
        if t.hasPrefix("# ") { result.append("<h1>\(inline(String(t.dropFirst(2))))</h1>"); continue }
        if t.hasPrefix("- ") {
            if !inList { result.append("<ul>"); inList = true }
            result.append("<li>\(inline(String(t.dropFirst(2))))</li>")
            continue
        }
        if inList { result.append("</ul>"); inList = false }
        result.append("<p>\(inline(t))</p>")
    }
    if inList { result.append("</ul>") }
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
        if t == "heroButtons:" {
            if section == "links" && !cur.isEmpty, let l = cur["label"] {
                links.append(LinkItem(label: l, url: cur["url"] ?? "", icon: cur["icon"] ?? "link",
                                      platform: cur["platform"] ?? "", order: true, showCount: cur["showCount"] == "true", count: 0))
                cur = [:]
            }
            section = "hero"; continue
        }
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
            if p.count == 2 {
                var key = p[0]
                if key.hasPrefix("- ") { key = String(key.dropFirst(2)) }
                cur[key] = p[1].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
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
var BASE='\(baseURL)';
var C={dark:{bg:'#000',onBg:'#FFF',surfaceLow:'#1F1F1F',surface:'#2D2D2D',primary:'#BB86FC',onPrimary:'#000',primaryContainer:'#4A148C',outline:'#8C8C8C'},
light:{bg:'#FFF',onBg:'#000',surfaceLow:'#F0F0F0',surface:'#E0E0E0',primary:'#6200EE',onPrimary:'#FFF',primaryContainer:'#BB86FC',outline:'#BDBDBD'}};
var params=new URLSearchParams(location.search);
var urlLang=params.get('lang');
var urlTheme=params.get('theme');
var urlDebugTheme=params.get('debugTheme');
var ua=navigator.userAgent;
var isChrome=ua.includes('Chrome')&&!ua.includes('Edg');
var isAndroid=ua.includes('Android');
var isWindows=ua.includes('Windows');
var preferMaterial=isChrome&&(isAndroid||isWindows);
var storedTheme=localStorage.getItem('theme');
var S={theme:urlDebugTheme||urlTheme||storedTheme||(preferMaterial?'dark':'glass-dark'),lang:urlLang||localStorage.getItem('lang')||(navigator.language.startsWith('ru')?'ru':'en')};

 function setTheme(t){S.theme=t;localStorage.setItem('theme',t);
 var cls=t==='dark'?'dark-theme':t==='light'?'light-theme':t==='glass-dark'?'glass-dark':'glass-light';
 document.body.className=cls;
 document.documentElement.style.background=t.startsWith('glass')?(t==='glass-dark'?'#000000':'#ffffff'):(t.includes('dark')?'#000000':'#f5f0ff');
 var icon=document.getElementById('theme-icon-bottom');
 if(icon)icon.textContent=t==='dark'?'light_mode':t==='light'?'dark_mode':t==='glass-dark'?'light_mode':'dark_mode';}
function toggleTheme(){var order=['dark','light','glass-dark','glass-light'];var idx=order.indexOf(S.theme);setTheme(order[(idx+1)%4]);}

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
fetch(BASE+'/data.json?t='+Date.now()).then(function(r){return r.json();}).then(function(data){
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
fetch(BASE+'/streams_history.json?t='+Date.now()).then(function(r){return r.json();}).then(function(data){
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

let siteCSS = siteStylesheet.render()

// MARK: - Links Page CSS

let linksCSS = linksPageStylesheet.render()

// MARK: - Links Page JS (ES module with inlined config + strings)

let linksJS = """
var BASE='\(baseURL)';
var skinview3d=window.skinview3d||null;

var params = new URLSearchParams(location.search);
var appConfig={dataUrl:BASE+'/data.json',showLiveStreamSection:true,showProfileSection:true,showMinecraftSkinSection:true,showLinksSection:true,showYouTubeVideosSection:true,showSupportButton:true,developmentMode:true,showDevToggle:true,showLanguageToggle:true,showThemeToggle:true,supportUrl:'https://www.donationalerts.com/r/bezzubickmcplay'};
var profileConfig={name_key:'profileName',description_key:'profileDescription',avatar:BASE+'/assets/avatar.png',minecraftSkinUrl:BASE+'/assets/skin.png'};
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

var DOM={};var state={theme:params.get('debugTheme')||params.get('theme')||localStorage.getItem('theme')||((navigator.userAgent.includes('Chrome')&&!navigator.userAgent.includes('Edg')&&(navigator.userAgent.includes('Android')||navigator.userAgent.includes('Windows')))?'dark':'glass-dark'),lang:params.get('lang')||localStorage.getItem('lang')||(navigator.language.startsWith('ru')?'ru':'en'),data:{followerCounts:{},youtubeVideos:[],liveStream:{type:'none'}},skinViewerInstance:null,skinControlsEl:null,currentAnimKey:'idle'};

function setVisibility(el,visible){if(!el)return;el.classList.toggle('hidden',!visible);}
function applyTheme(theme){document.body.classList.remove('dark-theme','light-theme','glass-dark','glass-light');var cls=theme==='dark'?'dark-theme':theme==='light'?'light-theme':theme==='glass-dark'?'glass-dark':'glass-light';document.body.classList.add(cls);localStorage.setItem('theme',theme);document.documentElement.style.background=theme.startsWith('glass')?(theme==='glass-dark'?'#000000':'#ffffff'):(theme.includes('dark')?'#000000':'#f5f0ff');if(DOM.themeIcon)DOM.themeIcon.textContent=theme==='dark'?'light_mode':theme==='light'?'dark_mode':theme==='glass-dark'?'light_mode':'dark_mode';}
function formatCount(num){if(num==null||isNaN(num))return strings[state.lang].loading;if(num>=1e6)return(num/1e6).toFixed(1).replace(/\\.0$/,'')+'M';if(num>=1e3)return(num/1e3).toFixed(1).replace(/\\.0$/,'')+'K';return String(num);}
async function fetchAppData(){var url=(appConfig.dataUrl||BASE+'/data.json')+'?t='+Date.now();try{var res=await fetch(url,{cache:'no-store'});if(!res.ok)throw new Error('HTTP '+res.status);return await res.json();}catch(e){console.warn('[Data Fetch] Fallback -> /data.json',e);try{var res2=await fetch(BASE+'/data.json?t='+Date.now(),{cache:'no-store'});if(res2.ok)return await res2.json();}catch(x){}return{followerCounts:{},youtubeVideos:[],liveStream:{type:'none'},debugInfo:{fetch_error:String(e)}};}}
function updateGridLiveState(){var has=appConfig.showLiveStreamSection&&state.data.liveStream&&state.data.liveStream.type!=='none';if(!DOM.contentGrid)return;DOM.contentGrid.classList.toggle('grid-has-live',has);DOM.contentGrid.classList.toggle('grid-no-live',!has);}
function updateLanguage(){var t=strings[state.lang];if(DOM.recentVideosTitle)DOM.recentVideosTitle.textContent=t.recentVideosTitle;if(DOM.minecraftTitle)DOM.minecraftTitle.textContent=t.minecraftTitle;if(DOM.downloadSkinText)DOM.downloadSkinText.textContent=t.downloadSkin;if(DOM.supportButtonText)DOM.supportButtonText.textContent=t.supportButton;if(DOM.offlineMessage)DOM.offlineMessage.textContent=t.offlineMessage;if(DOM.twitchLinkText)DOM.twitchLinkText.textContent=t.watchOnTwitch;if(DOM.twitchMessage)DOM.twitchMessage.textContent=t.twitchStreamAlsoLive;if(DOM.modalTitle)DOM.modalTitle.textContent=t.modalTitle;if(DOM.modalDescription)DOM.modalDescription.textContent=t.modalDescription;if(DOM.modalCloseBtn)DOM.modalCloseBtn.textContent=t.gotItButton;if(DOM.devTitle)DOM.devTitle.textContent=t.devPageTitle;if(DOM.devLastUpdatedLabel)DOM.devLastUpdatedLabel.textContent=t.devLastUpdatedLabel;if(DOM.devDataJsonContentLabel)DOM.devDataJsonContentLabel.textContent=t.devDataJsonContentLabel;if(DOM.devDebugInfoContentLabel)DOM.devDebugInfoContentLabel.textContent=t.devDebugInfoContentLabel;if(DOM.backToMainText)DOM.backToMainText.textContent=t.backToMainText;if(DOM.profileName)DOM.profileName.textContent=t[profileConfig.name_key];if(DOM.profileDescription)DOM.profileDescription.textContent=t[profileConfig.description_key];if(DOM.avatar)DOM.avatar.alt=t.avatarAlt;renderLinksSection(linksConfig);calculateAndDisplayTotalFollowers();}
function renderProfileSection(){setVisibility(DOM.profileSection,appConfig.showProfileSection);if(appConfig.showProfileSection&&DOM.avatar)DOM.avatar.src=profileConfig.avatar;}
function calculateAndDisplayTotalFollowers(){var t=strings[state.lang];var total=0;for(var i=0;i<linksConfig.length;i++){var link=linksConfig[i];if(link.isSocial&&link.showSubscriberCount&&link.active){var c=state.data.followerCounts?state.data.followerCounts[link.platformId]:0;if(typeof c==='number')total+=c;}}if(DOM.totalFollowers)DOM.totalFollowers.textContent=t.totalFollowers+' '+formatCount(total);}
function renderLinksSection(links){setVisibility(DOM.linksSection,appConfig.showLinksSection);if(!appConfig.showLinksSection||!DOM.linksSection)return;DOM.linksSection.innerHTML='';var sorted=links.filter(function(l){return l.active;}).sort(function(a,b){return a.order-b.order;});for(var i=0;i<sorted.length;i++){var link=sorted[i];var a=document.createElement('a');a.href=link.url;a.target='_blank';a.rel='noopener noreferrer';a.draggable=false;a.className='card relative flex items-center justify-between p-4 rounded-2xl m3-shadow-md '+(link.isSocial?'swipe-target':'')+' cursor-pointer';a.setAttribute('data-link-id',link.label_key);var count=state.data.followerCounts?state.data.followerCounts[link.platformId]:undefined;var showCount=link.isSocial&&link.showSubscriberCount;var iconHtml='<span class="material-symbols-outlined icon-large">'+(link.icon||'link')+'</span>';a.innerHTML='<div class="flex items-center select-none">'+iconHtml+'<div><span class="block text-lg font-medium">'+(strings[state.lang][link.label_key]||link.label_key)+'</span>'+(showCount?'<span class="text-sm text-gray-400 mr-2 follower-count-display">'+formatCount(count)+'</span>':'')+'</div></div>';DOM.linksSection.appendChild(a);}initSwipeGestures();}
function renderYouTubeVideosSection(){var videos=state.data.youtubeVideos||[];setVisibility(DOM.youtubeVideosSection,appConfig.showYouTubeVideosSection&&videos.length>0);if(!appConfig.showYouTubeVideosSection||videos.length===0||!DOM.videoCarousel)return;DOM.videoCarousel.innerHTML='';for(var i=0;i<videos.length;i++){var v=videos[i];var card=document.createElement('a');card.href='https://www.youtube.com/watch?v='+v.id;card.target='_blank';card.className='flex-shrink-0 w-64 rounded-2xl overflow-hidden m3-shadow-md card';card.innerHTML='<img src="'+v.thumbnailUrl+'" alt="'+v.title+'" class="w-full h-36 object-cover"><div class="p-3"><p class="text-sm font-medium leading-tight">'+v.title+'</p></div>';DOM.videoCarousel.appendChild(card);}DOM.videoCarousel.addEventListener('wheel',function(event){if(event.deltaY!==0){event.preventDefault();DOM.videoCarousel.scrollLeft+=event.deltaY;}},{passive:false});}
function renderLiveStream(){var info=state.data.liveStream;var has=appConfig.showLiveStreamSection&&info&&info.type!=='none';setVisibility(DOM.liveStreamSection,has);if(!has||!DOM.liveEmbed){updateGridLiveState();return;}if(info.type==='youtube'&&info.id){DOM.liveEmbed.src='https://www.youtube.com/embed/'+info.id+'?autoplay=1&mute=1';setVisibility(DOM.twitchNotification,!!info.twitchLive);if(info.twitchLive&&DOM.twitchLink)DOM.twitchLink.href='https://www.twitch.tv/'+info.twitchLive.twitchChannelName;}else if(info.type==='twitch'&&info.twitchChannelName){var parent=window.location.hostname||'localhost';DOM.liveEmbed.src='https://player.twitch.tv/?channel='+info.twitchChannelName+'&parent='+parent+'&autoplay=true&mute=1';setVisibility(DOM.twitchNotification,false);}updateGridLiveState();}
function disposeSkinViewer(){if(state.skinViewerInstance){state.skinViewerInstance.dispose();state.skinViewerInstance=null;}}
function updateActiveAnimationButtons(){if(!state.skinControlsEl)return;var btns=state.skinControlsEl.querySelectorAll('.mini-button');btns.forEach(function(btn){btn.classList.toggle('active',btn.getAttribute('data-anim')===state.currentAnimKey);});}
function showSkinFallbackImage(){setVisibility(DOM.minecraftBlock,true);disposeSkinViewer();if(!DOM.skinViewerContainer)return;DOM.skinViewerContainer.innerHTML='<img src="'+profileConfig.minecraftSkinUrl+'" alt="Minecraft skin" class="w-full h-full object-contain" />';}
function buildSkinControls(){if(!skinview3d)return;if(state.skinControlsEl&&state.skinControlsEl.parentElement)state.skinControlsEl.parentElement.removeChild(state.skinControlsEl);var controls=document.createElement('div');controls.id='skin-animation-controls';controls.className='skin-controls';var options=[{key:'idle',icon:'accessibility',available:!!skinview3d.IdleAnimation},{key:'walk',icon:'directions_walk',available:!!skinview3d.WalkingAnimation},{key:'run',icon:'directions_run',available:!!skinview3d.RunningAnimation},{key:'rotate',icon:'autorenew',available:!!skinview3d.RotatingAnimation},{key:'stop',icon:'stop_circle',available:true}];for(var i=0;i<options.length;i++){var opt=options[i];if(!opt.available)continue;var btn=document.createElement('button');btn.type='button';btn.className='mini-button';btn.setAttribute('data-anim',opt.key);btn.innerHTML='<span class="material-symbols-outlined mini-icon" aria-hidden="true">'+opt.icon+'</span>';btn.addEventListener('click',(function(k){return function(){setSkinAnimation(k);};})(opt.key));controls.appendChild(btn);}var downloadWrapper=DOM.downloadSkinButton?DOM.downloadSkinButton.parentElement:null;if(downloadWrapper&&downloadWrapper.parentElement===DOM.minecraftBlock)DOM.minecraftBlock.insertBefore(controls,downloadWrapper);else DOM.skinViewerContainer.after(controls);state.skinControlsEl=controls;updateActiveAnimationButtons();}
function setSkinAnimation(key){if(!state.skinViewerInstance)return;var anim=null;try{if(key==='idle'&&skinview3d&&skinview3d.IdleAnimation)anim=new skinview3d.IdleAnimation();else if(key==='walk'&&skinview3d&&skinview3d.WalkingAnimation)anim=new skinview3d.WalkingAnimation();else if(key==='run'&&skinview3d&&skinview3d.RunningAnimation)anim=new skinview3d.RunningAnimation();else if(key==='rotate'&&skinview3d&&skinview3d.RotatingAnimation)anim=new skinview3d.RotatingAnimation();else if(key==='stop')anim=null;state.skinViewerInstance.animation=anim;state.currentAnimKey=key;updateActiveAnimationButtons();}catch(e){console.warn('[SkinViewer] Failed to set animation:',key,e);}}
async function initMinecraftSkinViewer(){if(!appConfig.showMinecraftSkinSection){setVisibility(DOM.minecraftBlock,false);disposeSkinViewer();return;}if(!DOM.skinCanvas||!DOM.skinViewerContainer){console.error('[SkinViewer] Missing elements');setVisibility(DOM.minecraftBlock,false);return;}try{await new Promise(function(r){requestAnimationFrame(function(){requestAnimationFrame(r);});});if(!skinview3d){showSkinFallbackImage();return;}setVisibility(DOM.minecraftBlock,true);var width=Math.max(1,DOM.skinViewerContainer.offsetWidth||320);var height=Math.max(1,DOM.skinViewerContainer.offsetHeight||320);disposeSkinViewer();var viewer=new skinview3d.SkinViewer({canvas:DOM.skinCanvas,width:width,height:height});await viewer.loadSkin(profileConfig.minecraftSkinUrl);try{if(skinview3d.IdleAnimation){viewer.animation=new skinview3d.IdleAnimation();state.currentAnimKey='idle';}else if(skinview3d.WalkingAnimation){viewer.animation=new skinview3d.WalkingAnimation();state.currentAnimKey='walk';}else{state.currentAnimKey='stop';}}catch(e){}try{var controls=skinview3d.createOrbitControls(viewer);if(controls){controls.enablePan=false;controls.enableZoom=true;if(controls.target)controls.target.set(0,17,0);controls.update();}}catch(e){}state.skinViewerInstance=viewer;buildSkinControls();new ResizeObserver(function(){if(!state.skinViewerInstance)return;var w=Math.max(1,DOM.skinViewerContainer.offsetWidth||320);var h=Math.max(1,DOM.skinViewerContainer.offsetHeight||320);state.skinViewerInstance.setSize(w,h);}).observe(DOM.skinViewerContainer);}catch(e){console.error('[SkinViewer] init error, fallback PNG',e);showSkinFallbackImage();}}
function initSwipeGestures(){var cards=document.querySelectorAll('.swipe-target');for(var ci=0;ci<cards.length;ci++){(function(card){var startX=0,startY=0,currentX=0,currentY=0,pointerDown=false,swipeActive=false,suppressClick=false;var linkData=null;for(var li=0;li<linksConfig.length;li++){if(linksConfig[li].label_key===card.getAttribute('data-link-id')){linkData=linksConfig[li];break;}}if(!linkData)return;var onStart=function(e){pointerDown=true;swipeActive=false;startX=e.touches?e.touches[0].clientX:e.clientX;startY=e.touches?e.touches[0].clientY:e.clientY;card.style.transition='none';};var onMove=function(e){if(!pointerDown)return;currentX=e.touches?e.touches[0].clientX:e.clientX;currentY=e.touches?e.touches[0].clientY:e.clientY;var dx=currentX-startX,dy=currentY-startY;if(!swipeActive&&Math.abs(dx)>20&&Math.abs(dx)>Math.abs(dy)){swipeActive=true;e.preventDefault();}if(swipeActive){e.preventDefault();card.style.transform='translateX('+dx+'px)';card.classList.toggle('swiping-right',dx>0);card.classList.toggle('swiping-left',dx<0);}};var onEnd=function(){if(!pointerDown)return;pointerDown=false;card.style.transition='transform .2s ease, background-color .3s ease, box-shadow .2s ease';var dx=currentX-startX;if(swipeActive){var thr=card.offsetWidth*0.25;if(Math.abs(dx)>thr){if(dx>0){window.open(linkData.subscribeUrl||linkData.url,'_blank');}else{if(linkData.platformId==='youtube'){var live=state.data.liveStream;if(live&&live.type==='youtube'&&live.id)window.open('https://www.youtube.com/watch?v='+live.id,'_blank');else if(state.data.youtubeVideos&&state.data.youtubeVideos.length>0)window.open('https://www.youtube.com/watch?v='+state.data.youtubeVideos[0].id,'_blank');else window.open(linkData.url,'_blank');}else{window.open(linkData.url,'_blank');}}}}card.style.transform='translateX(0)';card.classList.remove('swiping-left','swiping-right');if(swipeActive){suppressClick=true;setTimeout(function(){suppressClick=false;},0);}swipeActive=false;};var onClick=function(e){if(suppressClick){e.preventDefault();e.stopPropagation();}};card.addEventListener('mousedown',onStart);card.addEventListener('mousemove',onMove);card.addEventListener('mouseup',onEnd);card.addEventListener('mouseleave',onEnd);card.addEventListener('touchstart',onStart,{passive:false});card.addEventListener('touchmove',onMove,{passive:false});card.addEventListener('touchend',onEnd);card.addEventListener('click',onClick);})(cards[ci]);}}
function setupSupportButton(){setVisibility(DOM.supportSection,appConfig.showSupportButton);if(appConfig.showSupportButton&&DOM.supportButton)DOM.supportButton.href=appConfig.supportUrl||'#';}
function setupOfflineBanner(){var upd=function(){setVisibility(DOM.offlineWarning,!navigator.onLine);};window.addEventListener('online',upd);window.addEventListener('offline',upd);upd();}
function manageFirstVisitModal(){if(!DOM.firstVisitModal||!DOM.modalCloseBtn)return;var seen=localStorage.getItem('visited_modal');if(!seen){DOM.firstVisitModal.classList.add('active');DOM.modalCloseBtn.onclick=function(){DOM.firstVisitModal.classList.remove('active');localStorage.setItem('visited_modal','true');};}}
async function downloadMinecraftSkin(ev){try{ev&&ev.preventDefault&&ev.preventDefault();ev&&ev.stopPropagation&&ev.stopPropagation();var url=new URL(profileConfig.minecraftSkinUrl,location.href).toString();var res=await fetch(url,{cache:'no-store'});if(!res.ok)throw new Error('HTTP '+res.status);var blob=await res.blob();var blobUrl=URL.createObjectURL(blob);var a=document.createElement('a');a.href=blobUrl;a.download='minecraft_skin.png';document.body.appendChild(a);a.click();a.remove();setTimeout(function(){URL.revokeObjectURL(blobUrl);},1000);}catch(e){var fallback=new URL(profileConfig.minecraftSkinUrl,location.href).toString();var a2=document.createElement('a');a2.href=fallback;a2.target='_blank';document.body.appendChild(a2);a2.click();a2.remove();}}
function applyMockFromQuery(){var p=new URLSearchParams(location.search);var s=p.get('mockLive');if(!s)return;if(s==='none'){state.data.liveStream={type:'none'};return;}var parts=s.split(':');var kind=parts[0],a=parts[1],b=parts[2];if(kind==='both'){state.data.liveStream={type:'youtube',id:a||'e7K5ijK2VOo',title:'Mock YT',youtubeChannelId:'mock',twitchLive:{type:'twitch',id:'mock',title:'Mock TW',twitchChannelName:b||'monstercat'}};}else if(kind==='youtube'){state.data.liveStream={type:'youtube',id:a||'e7K5ijK2VOo',title:'Mock YT',youtubeChannelId:'mock'};}else if(kind==='twitch'){state.data.liveStream={type:'twitch',id:'mock',title:'Mock TW',twitchChannelName:a||'monstercat'};}}

document.addEventListener('DOMContentLoaded',async function(){
DOM.contentGrid=document.getElementById('content-grid');DOM.offlineWarning=document.getElementById('offline-warning');DOM.offlineMessage=document.getElementById('offline-message');DOM.liveStreamSection=document.getElementById('live-stream-section');DOM.liveEmbed=document.getElementById('live-embed');DOM.twitchNotification=document.getElementById('twitch-notification');DOM.twitchMessage=document.getElementById('twitch-message');DOM.twitchLink=document.getElementById('twitch-link');DOM.twitchLinkText=document.getElementById('twitch-link-text');DOM.profileSection=document.getElementById('profile-section');DOM.avatar=document.getElementById('avatar');DOM.profileName=document.getElementById('profile-name');DOM.profileDescription=document.getElementById('profile-description');DOM.totalFollowers=document.getElementById('total-followers');DOM.linksSection=document.getElementById('links-section');DOM.supportSection=document.getElementById('support-section');DOM.supportButton=document.getElementById('support-button');DOM.supportButtonText=document.getElementById('support-button-text');DOM.minecraftBlock=document.getElementById('minecraft-block');DOM.minecraftTitle=document.getElementById('minecraft-title');DOM.skinViewerContainer=document.getElementById('skin-viewer-container');DOM.skinCanvas=document.getElementById('skin-canvas');DOM.downloadSkinButton=document.getElementById('download-skin-button');DOM.downloadSkinText=document.getElementById('download-skin-text');DOM.youtubeVideosSection=document.getElementById('youtube-videos-section');DOM.recentVideosTitle=document.getElementById('recent-videos-title');DOM.videoCarousel=document.getElementById('video-carousel');DOM.themeToggle=document.getElementById('theme-toggle');DOM.themeIcon=document.getElementById('theme-icon');DOM.languageToggle=document.getElementById('language-toggle');DOM.devToggle=document.getElementById('dev-toggle');DOM.backToMainButton=document.getElementById('back-to-main-button');DOM.devTitle=document.getElementById('dev-title');DOM.devLastUpdatedLabel=document.getElementById('dev-last-updated-label');DOM.devLastUpdated=document.getElementById('dev-last-updated');DOM.devDataJsonContentLabel=document.getElementById('dev-data-json-content-label');DOM.devDataJsonContent=document.getElementById('dev-data-json-content');DOM.devDebugInfoContentLabel=document.getElementById('dev-debug-info-content-label');DOM.devDebugInfoContent=document.getElementById('dev-debug-info-content');DOM.backToMainText=document.getElementById('back-to-main-text');DOM.firstVisitModal=document.getElementById('first-visit-modal');DOM.modalTitle=document.getElementById('modal-title');DOM.modalDescription=document.getElementById('modal-description');DOM.modalCloseBtn=document.getElementById('modal-close');

state.data=await fetchAppData();applyMockFromQuery();renderProfileSection();applyTheme(state.theme);updateLanguage();renderYouTubeVideosSection();renderLiveStream();updateGridLiveState();await initMinecraftSkinViewer();setupSupportButton();setupOfflineBanner();manageFirstVisitModal();
if(DOM.themeToggle)DOM.themeToggle.addEventListener('click',function(){var order=['dark','light','glass-dark','glass-light'];var idx=order.indexOf(state.theme);state.theme=order[(idx+1)%4];applyTheme(state.theme);});
if(DOM.languageToggle)DOM.languageToggle.addEventListener('click',function(){state.lang=state.lang==='en'?'ru':'en';localStorage.setItem('lang',state.lang);updateLanguage();});
if(DOM.downloadSkinButton)DOM.downloadSkinButton.addEventListener('click',downloadMinecraftSkin);
if(DOM.devToggle)DOM.devToggle.classList.toggle('hidden',!appConfig.showDevToggle);
(async function(){try{var jk=await import('https://cdn.jsdelivr.net/npm/javascriptkit@0.53.0/dist/javascriptkit.js');var wasmResp=await fetch(BASE+'/scripts/SiteClient.wasm');if(!wasmResp.ok)throw new Error('HTTP '+wasmResp.status);var wasmInst=await jk.instantiate(wasmResp,{});try{wasmInst.exports.main()}catch(e){console.warn('[WASM] main error',e)}}catch(e){console.warn('[WASM] init error (Liquid Glass unavailable)',e)}})();
});
"""

// MARK: - Theme

extension Theme where Site == BezzubickSite {
    static var custom: Theme {
        Theme(htmlFactory: BezzubickHTMLFactory(), resourcePaths: [])
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
            let href = btn.url.hasPrefix("/") ? "\(baseURL)\(btn.url)" : btn.url
            return .a(.id("cta-\(btn.label.hashValue)"), .href(href),
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
                        .img(.src("\(baseURL)/assets/avatar.png"), .alt("Avatar"), .class("avatar m3-shadow-md")),
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
                            .a(.id("go-links-btn-2"), .href("\(baseURL)/links/"), .class("rounded-full px-6 py-3 font-medium m3-shadow-md primary-button"),
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
                            .div(.id("skin-viewer"), .class("skin-viewer"),
                                .element(named: "canvas", nodes: [.id("skin-canvas")])),
                            .div(.id("skin-controls"), .class("skin-controls")),
                            .div(.class("flex justify-center mt-2"),
                                 .a(.id("download-skin"), .href("\(baseURL)/assets/skin.png"),
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
                .raw("<script src=\"\(baseURL)/scripts/skinview3d.bundle.js\"></script>"),
                .raw("<script>\(siteJS)</script>"),
                .element(named: "script", nodes: [
                    .attribute(named: "type", value: "module"),
                    .raw("""
                    var BASE='\(baseURL)';
                    var skinview3d=window.skinview3d||null;
                    var skinState={currentAnimKey:'stop'};
                    function disposeSkinViewer(){if(window.__homeSkinInstance){window.__homeSkinInstance.dispose();window.__homeSkinInstance=null;}}
                    function homeSkinFallback(c){if(!c)return;disposeSkinViewer();c.innerHTML='<img src=\"'+BASE+'/assets/skin.png\" alt=\"Minecraft skin\" class=\"w-full h-full object-contain\" />';}
                    function homeSetSkinAnimation(key){var v=window.__homeSkinInstance;if(!v)return;var anim=null;try{if(key==='idle'&&skinview3d&&skinview3d.IdleAnimation)anim=new skinview3d.IdleAnimation();else if(key==='walk'&&skinview3d&&skinview3d.WalkingAnimation)anim=new skinview3d.WalkingAnimation();else if(key==='run'&&skinview3d&&skinview3d.RunningAnimation)anim=new skinview3d.RunningAnimation();else if(key==='rotate'&&skinview3d&&skinview3d.RotatingAnimation)anim=new skinview3d.RotatingAnimation();else if(key==='stop')anim=null;v.animation=anim;skinState.currentAnimKey=key;homeUpdateActiveButtons()}catch(e){console.warn('[HomeSkin] anim',key,e);}}
                    function homeUpdateActiveButtons(){var el=document.getElementById('skin-controls');if(!el)return;el.querySelectorAll('.mini-button').forEach(function(b){b.classList.toggle('active',b.getAttribute('data-anim')===skinState.currentAnimKey);});}
                    function homeBuildSkinControls(){if(!skinview3d)return;var el=document.getElementById('skin-controls');if(!el)return;el.innerHTML='';var opts=[{key:'idle',icon:'accessibility',av:!!skinview3d.IdleAnimation},{key:'walk',icon:'directions_walk',av:!!skinview3d.WalkingAnimation},{key:'run',icon:'directions_run',av:!!skinview3d.RunningAnimation},{key:'rotate',icon:'autorenew',av:!!skinview3d.RotatingAnimation},{key:'stop',icon:'stop_circle',av:true}];opts.forEach(function(o){if(!o.av)return;var b=document.createElement('button');b.type='button';b.className='mini-button';b.setAttribute('data-anim',o.key);b.innerHTML='<span class="material-symbols-outlined mini-icon" aria-hidden="true">'+o.icon+'</span>';b.addEventListener('click',function(){homeSetSkinAnimation(o.key);});el.appendChild(b);});homeUpdateActiveButtons();}
                    document.addEventListener('DOMContentLoaded',async function(){
                      var c=document.getElementById('skin-viewer');if(!c)return;
                      if(!skinview3d){homeSkinFallback(c);return;}
                      await new Promise(function(r){requestAnimationFrame(function(){requestAnimationFrame(r);});});
                      var cv=document.getElementById('skin-canvas');if(!cv){cv=document.createElement('canvas');cv.id='skin-canvas';c.appendChild(cv)}
                      var w=Math.max(1,c.offsetWidth||320);var h=Math.max(1,c.offsetHeight||400);
                      cv.width=w;cv.height=h;
                      try{
                        disposeSkinViewer();
                        var v=new skinview3d.SkinViewer({canvas:cv,width:w,height:h});
                        await v.loadSkin(BASE+'/assets/skin.png');
                        try{if(skinview3d.IdleAnimation){v.animation=new skinview3d.IdleAnimation();skinState.currentAnimKey='idle';}else if(skinview3d.WalkingAnimation){v.animation=new skinview3d.WalkingAnimation();skinState.currentAnimKey='walk';}}catch(e){}
                        try{var o=skinview3d.createOrbitControls(v);if(o){o.enablePan=false;o.enableZoom=true;if(o.target)o.target.set(0,17,0);o.update()}}catch(e){}
                        window.__homeSkinInstance=v;
                        homeBuildSkinControls();
                        new ResizeObserver(function(){if(!window.__homeSkinInstance)return;var nw=Math.max(1,c.offsetWidth||320);var nh=Math.max(1,c.offsetHeight||400);window.__homeSkinInstance.setSize(nw,nh)}).observe(c);
                      }catch(e){console.error('[HomeSkin]',e);homeSkinFallback(c)}
                    });
                    document.getElementById('download-skin')?.addEventListener('click',function(ev){ev.preventDefault();var u=new URL(BASE+'/assets/skin.png',location.href).toString();fetch(u,{cache:'no-store'}).then(function(r){if(!r.ok)throw Error();return r.blob()}).then(function(b){var a=document.createElement('a');a.href=URL.createObjectURL(b);a.download='minecraft_skin.png';document.body.appendChild(a);a.click();a.remove()}).catch(function(){window.open(u,'_blank')})});
                    (async function(){try{var resp=await fetch(BASE+'/scripts/SiteClient.wasm');if(!resp.ok)throw new Error('HTTP '+resp.status);var bytes=await resp.arrayBuffer();var instance=await WebAssembly.instantiate(bytes,{});try{instance.instance.exports.main()}catch(e){console.warn('[WASM] main error',e)}}catch(e){console.warn('[WASM] init error (Liquid Glass unavailable)',e)}})();
                    """)
                ])
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
                .link(.rel(.icon), .href("https://httydcraft.github.io\(baseURL)/assets/avatar.png"), .type("image/png")),
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
                            .img(.id("avatar"), .class("w-28 h-28 rounded-full mx-auto mb-4 border-4 border-purple-500 object-cover m3-shadow-md"), .src("\(baseURL)/assets/avatar.png"), .alt("Avatar")),
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
                .raw("<script src=\"\(baseURL)/scripts/skinview3d.bundle.js\"></script>"),
                .element(named: "script", nodes: [
                    .attribute(named: "type", value: "module"),
                    .raw(linksJS)])
            )
        )
    }
}

// MARK: - Publish

try BezzubickSite().publish(withTheme: .custom)
