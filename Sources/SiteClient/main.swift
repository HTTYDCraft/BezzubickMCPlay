import JavaScriptKit

#if os(WASI)

func jsGlobal(_ name: String) -> JSObject { JSObject.global[name].object! }

// MARK: - String helpers

func zeroPad(_ n: Int, _ width: Int) -> String {
    var s = "\(n)"
    while s.count < width { s = "0" + s }
    return s
}

func fmtCount(_ val: Double) -> String {
    if val >= 1_000_000 {
        let m = (val / 1_000_000 * 10).rounded() / 10
        return m.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(m))M" : "\(m)M"
    }
    if val >= 1_000 {
        let k = (val / 1_000 * 10).rounded() / 10
        return k.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(k))K" : "\(k)K"
    }
    return "\(Int(val))"
}

// MARK: - State

var isDark = true
var mouseXFrac = 0.5
var mouseYFrac = 0.5

var stateTheme: String {
    get {
        let v = jsGlobal("localStorage").getItem!("theme")
        return v.isUndefined ? "dark" : (v.string ?? "dark")
    }
    set { _ = jsGlobal("localStorage").setItem!("theme", newValue) }
}

var stateLang: String {
    get {
        let stored = jsGlobal("localStorage").getItem!("lang")
        if !stored.isUndefined, let s = stored.string { return s }
        let navLang = jsGlobal("navigator").language.string ?? "ru"
        return navLang.hasPrefix("ru") ? "ru" : "en"
    }
    set { _ = jsGlobal("localStorage").setItem!("lang", newValue) }
}

// MARK: - Strings (Home Page)

let HOME_STR_RU: [String: String] = [
    "followers": "Все подписчики: ",
    "navTitle": "Навигация",
    "navDesc": "Перейдите на страницу со всеми моими ссылками, ссулками, скином и инфой.",
    "navCta": "Перейти к ссылкам",
    "skinTitle": "Мой скин Minecraft",
    "skinDl": "Скачать скин",
    "videosTitle": "Последние видео",
    "tlTitle": "Лента канала",
    "expand": "Развернуть",
    "collapse": "Свернуть",
    "liveEmpty": "Сейчас стрима нет",
    "liveSub": "Обычно стримы по пятницам, 17:00–19:00 МСК.",
    "legendYt": "YouTube", "legendTw": "Twitch",
    "legendBoth": "Оба", "legendPlanned": "Потенциальный",
    "legendMissed": "Зачёркнутые — стрима не было",
    "twitchAlso": "Стрим также идёт на Twitch!",
    "twitchCta": "Смотреть на Twitch"
]
let HOME_STR_EN: [String: String] = [
    "followers": "Total Subscribers: ",
    "navTitle": "Navigation", "navDesc": "Go to the page with all my links, socials, skin, and dev info.",
    "navCta": "Go to Links", "skinTitle": "My Minecraft Skin", "skinDl": "Download Skin",
    "videosTitle": "Latest Videos", "tlTitle": "Channel Timeline",
    "expand": "Expand", "collapse": "Collapse",
    "liveEmpty": "No stream right now", "liveSub": "Streams are usually on Fridays, 17:00–19:00 MSK.",
    "legendYt": "YouTube", "legendTw": "Twitch", "legendBoth": "Both", "legendPlanned": "Planned",
    "legendMissed": "Struck-out — there was no stream",
    "twitchAlso": "Stream is also live on Twitch!", "twitchCta": "Watch on Twitch"
]

// MARK: - Strings (Links Page)

let LINKS_STR_EN: [String: String] = [
    "recentVideosTitle": "Recent Videos",
    "modalTitle": "Welcome!", "modalDescription": "Swipe right on a link card to subscribe, swipe left on YouTube links to open the latest video or a live stream.",
    "gotItButton": "Got it!", "totalFollowers": "Total Followers: ",
    "minecraftTitle": "My Minecraft Skin", "downloadSkin": "Download Skin",
    "loading": "Loading...", "supportButton": "Support Me",
    "offlineMessage": "You are offline. Data might be outdated.",
    "devPageTitle": "Developer Info", "devLastUpdatedLabel": "Last Data Update:",
    "devDataJsonContentLabel": "data.json Content:", "devDebugInfoContentLabel": "API Debug Info:",
    "backToMainText": "Back to Main Site", "openLinkButton": "Open Link", "closeButton": "Close",
    "profileName": "BezzubickMCPlay", "profileDescription": "Minecraft adventures | Streams | Creativity",
    "avatarAlt": "BezzubickMCPlay profile avatar",
    "twitchStreamAlsoLive": "Stream also live on Twitch!",
    "youtubeChannelLabel": "YouTube Channel", "telegramChannelLabel": "Telegram Channel",
    "instagramProfileLabel": "Instagram Profile", "xTwitterProfileLabel": "X (Twitter) Profile",
    "twitchChannelLabel": "Twitch Channel", "tiktokProfileLabel": "TikTok Profile",
    "vkGroupLabel": "VK Group", "vkPersonalPageLabel": "VK Personal Page",
    "watchOnTwitch": "Watch on Twitch"
]
let LINKS_STR_RU: [String: String] = [
    "recentVideosTitle": "Последние видео",
    "modalTitle": "Добро пожаловать!",
    "modalDescription": "Проведите вправо по карточке ссылки, чтобы подписаться. Проведите влево по YouTube-ссылкам, чтобы открыть последнее видео или прямой эфир.",
    "gotItButton": "Понятно!", "totalFollowers": "Всего подписчиков: ",
    "minecraftTitle": "Мой скин Minecraft", "downloadSkin": "Скачать скин",
    "loading": "Загрузка...", "supportButton": "Поддержать меня",
    "offlineMessage": "Вы не в сети.",
    "devPageTitle": "Инфо для разработчиков", "devLastUpdatedLabel": "Последнее обновление:",
    "devDataJsonContentLabel": "data.json:", "devDebugInfoContentLabel": "API Debug:",
    "backToMainText": "На главную", "openLinkButton": "Открыть", "closeButton": "Закрыть",
    "profileName": "BezzubickMCPlay", "profileDescription": "Майнкрафт | Стримы | Творчество",
    "avatarAlt": "Аватар BezzubickMCPlay",
    "twitchStreamAlsoLive": "Стрим также идёт на Twitch!",
    "youtubeChannelLabel": "Канал YouTube", "telegramChannelLabel": "Канал Telegram",
    "instagramProfileLabel": "Профиль Instagram", "xTwitterProfileLabel": "Профиль X (Twitter)",
    "twitchChannelLabel": "Канал Twitch", "tiktokProfileLabel": "Профиль TikTok",
    "vkGroupLabel": "Группа VK", "vkPersonalPageLabel": "Страница VK",
    "watchOnTwitch": "Смотреть на Twitch"
]

func setById(_ id: String, _ val: String) {
    let el = jsGlobal("document").getElementById!("id)
    if !el.isUndefined { _ = el.textContent.set!(", val) }
}

func t(_ k: String) -> String {
    let doc = jsGlobal("document")
    let hasLinks = !doc.getElementById!("links-section").isUndefined
    let hasProfile = !doc.getElementById!("profile-section").isUndefined
    if hasLinks || hasProfile {
        return (stateLang == "en" ? LINKS_STR_EN : LINKS_STR_RU)[k] ?? k
    }
    return (stateLang == "en" ? HOME_STR_EN : HOME_STR_RU)[k] ?? k
}

// MARK: - Theme

let THEMES = ["dark", "light", "glass-dark", "glass-light"]
let THEME_ICONS: [String: String] = [
    "dark": "light_mode", "light": "dark_mode", "glass-dark": "light_mode", "glass-light": "dark_mode"
]
let THEME_CLASSES: [String: String] = [
    "dark": "dark-theme", "light": "light-theme", "glass-dark": "glass-dark", "glass-light": "glass-light"
]

func applyTheme(_ theme: String) {
    let body = jsGlobal("document").body.object!
    for cls in ["dark-theme", "light-theme", "glass-dark", "glass-light"] {
        _ = body.classList.remove!(", cls)
    }
    _ = body.classList.add!(", THEME_CLASSES[theme] ?? "dark-theme")
    stateTheme = theme
    isDark = theme.contains("dark")
    let iconBottom = jsGlobal("document").getElementById!("theme-icon-bottom")
    if !iconBottom.isUndefined { _ = iconBottom.textContent.set!(", THEME_ICONS[theme] ?? "light_mode") }
    let iconTop = jsGlobal("document").getElementById!("theme-icon")
    if !iconTop.isUndefined { _ = iconTop.textContent.set!(", THEME_ICONS[theme] ?? "light_mode") }
}

func toggleTheme() {
    let idx = THEMES.firstIndex(of: stateTheme) ?? 0
    applyTheme(THEMES[(idx + 1) % THEMES.count])
}

// MARK: - Language

func updateLangContent() {
    let doc = jsGlobal("document")
    let els = doc.querySelectorAll!("[data-lang]")
    let length = els.length.number ?? 0
    for i in 0..<Int(length) {
        let el = els[i]
        let lang = el.getAttribute!("data-lang").string ?? ""
        _ = el.style.setProperty!("display", lang == stateLang ? "" : "none")
    }
}

// MARK: - Home Page Texts

func updateHomeTexts() {
    let s = stateLang == "en" ? HOME_STR_EN : HOME_STR_RU
    setById("totals", (s.followers ?? "") + "\u{2014}")
    setById("nav-title", s.navTitle ?? "")
    setById("nav-desc", s.navDesc ?? "")
    setById("go-links-text", s.navCta ?? "")
    setById("go-links-btn-text-2", s.navCta ?? "")
    setById("skin-title", s.skinTitle ?? "")
    setById("skin-download-text", s.skinDl ?? "")
    setById("videos-title", s.videosTitle ?? "")
    setById("timeline-title", s.tlTitle ?? "")
    setById("tl-expand-text", s.expand ?? "")
    setById("tl-collapse-text", s.collapse ?? "")
    setById("live-empty-title", s.liveEmpty ?? "")
    setById("live-empty-sub", s.liveSub ?? "")
    setById("legend-yt", s.legendYt ?? "")
    setById("legend-tw", s.legendTw ?? "")
    setById("legend-both", s.legendBoth ?? "")
    setById("legend-planned", s.legendPlanned ?? "")
    setById("legend-missed", s.legendMissed ?? "")
    setById("twitch-text", s.twitchAlso ?? "")
    setById("twitch-cta", s.twitchCta ?? "")
    updateLangContent()
}

// MARK: - Links Page Texts

func updateLinksTexts() {
    let s = stateLang == "en" ? LINKS_STR_EN : LINKS_STR_RU
    setById("modal-title", s.modalTitle ?? "")
    setById("modal-description", s.modalDescription ?? "")
    setById("modal-close", s.gotItButton ?? "")
    setById("recent-videos-title", s.recentVideosTitle ?? "")
    setById("minecraft-title", s.minecraftTitle ?? "")
    setById("download-skin-text", s.downloadSkin ?? "")
    setById("support-button-text", s.supportButton ?? "")
    setById("offline-message", s.offlineMessage ?? "")
    setById("dev-title", s.devPageTitle ?? "")
    setById("dev-last-updated-label", s.devLastUpdatedLabel ?? "")
    setById("dev-data-json-content-label", s.devDataJsonContentLabel ?? "")
    setById("dev-debug-info-content-label", s.devDebugInfoContentLabel ?? "")
    setById("back-to-main-text", s.backToMainText ?? "")
    setById("twitch-message", s.twitchStreamAlsoLive ?? "")
    setById("twitch-link-text", s.watchOnTwitch ?? "")
    updateLangContent()
}

// MARK: - Calendar

let MONTHS_RU = ["Январь","Февраль","Март","Апрель","Май","Июнь","Июль","Август","Сентябрь","Октябрь","Ноябрь","Декабрь"]
let MONTHS_EN = ["January","February","March","April","May","June","July","August","September","October","November","December"]
let WDAYS_RU = ["Пн","Вт","Ср","Чт","Пт","Сб","Вс"]
let WDAYS_EN = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]

var calYear = 0
var calMonth = 0
var streamEvents: [String: (yt: Bool, tw: Bool, ytUrl: String, twUrl: String)] = [:]

func setupCalendar() {
    let now = jsGlobal("Date").new()
    calYear = Int(now.getFullYear!(").number ?? 2026)
    calMonth = Int(now.getMonth!(").number ?? 0)

    let doc = jsGlobal("document")
    let prev = doc.getElementById!("cal-prev")
    if !prev.isUndefined {
        _ = prev.addEventListener!("click", JSClosure({ _ in
            calMonth -= 1
            if calMonth < 0 { calMonth = 11; calYear -= 1 }
            renderCal()
            return .undefined
        }))
    }
    let next = doc.getElementById!("cal-next")
    if !next.isUndefined {
        _ = next.addEventListener!("click", JSClosure({ _ in
            calMonth += 1
            if calMonth > 11 { calMonth = 0; calYear += 1 }
            renderCal()
            return .undefined
        }))
    }
    renderCal()
}

func renderCal() {
    let months = stateLang == "en" ? MONTHS_EN : MONTHS_RU
    let wdays = stateLang == "en" ? WDAYS_EN : WDAYS_RU
    let doc = jsGlobal("document")

    let label = doc.getElementById!("cal-label")
    if !label.isUndefined { _ = label.textContent.set!(", "\(months[calMonth]) \(calYear)") }

    let head = doc.getElementById!("cal-weekdays")
    if !head.isUndefined { _ = head.innerHTML!("set", wdays.map { "<div>\($0)</div>" }.joined(separator: "")) }

    let DateObj = jsGlobal("Date")
    let firstDow = DateObj.new(calYear, calMonth, 1)
    let startDow = ((Int(firstDow.getDay!(").number ?? 0)) + 6) % 7
    let daysInMonth = Int(DateObj.new(calYear, calMonth + 1, 0).getDate!(").number ?? 30)
    let today = DateObj.new()
    _ = today.setTime!("0, 0, 0, 0)
    let todayTime = today.getTime.number ?? 0

    var html = ""
    for _ in 0..<startDow { html += "<div></div>" }
    for d in 1...daysInMonth {
        let dt = DateObj.new(calYear, calMonth, d)
        let dtTime = dt.getTime.number ?? 0
        let isToday = dtTime == todayTime
        let isPast = dtTime < todayTime
        let dow = ((Int(dt.getDay!(").number ?? 0)) + 6) % 7
        var cls = .cell
        if dow == 4 { cls.append("fri") }
        if isToday { cls.append("today") }
        let ds = "\(calYear)-\(zeroPad(calMonth + 1, 2))-\(zeroPad(d, 2))"
        var dot = ""
        var chips = ""
        if let info = streamEvents[ds] {
            if info.yt && info.tw { dot = "<span class=\"dot both\"></span>" }
            else if info.yt { dot = "<span class=\"dot yt\"></span>" }
            else if info.tw { dot = "<span class=\"dot tw\"></span>" }
            if !info.ytUrl.isEmpty { chips += "<a href=\"\(info.ytUrl)\" target=\"_blank\">YT</a>" }
            if !info.twUrl.isEmpty { chips += (chips.isEmpty ? "" : " · ") + "<a href=\"\(info.twUrl)\" target=\"_blank\">TW</a>" }
        } else if dow == 4 {
            if isPast { cls.append("passed"); cls.append("no-stream") } else { dot = "<span class=\"dot planned\"></span>" }
        }
        html += "<div class=\"\(cls.joined(separator: " "))\"><div>\(d)</div>\(dot)\(chips.isEmpty ? "" : "<div>\(chips)</div>")</div>"
    }
    let grid = doc.getElementById!("cal-grid")
    if !grid.isUndefined { _ = grid.innerHTML!("set", html) }
}

// MARK: - Data Fetch

func fetchData() async {
    let ts = Int((jsGlobal("Date").new().getTime.number ?? 0))
    let win = jsGlobal("window")
    let respVal = try? await win.fetch!("/data.json?t=\(ts)")
    guard (respVal?.ok.boolean ?? false) else { return }
    guard let json = try? await respVal?.json!(") else { return }

    let doc = jsGlobal("document")

    let vids = json["youtubeVideos"].object!
    let carousel = doc.getElementById!("carousel")
    if !carousel.isUndefined {
        _ = carousel.innerHTML!("set", "")
        let len = vids.length.number ?? 0
        for i in 0..<Int(len) {
            let v = vids[i]
            let id = v["id"].string ?? ""
            let title = v["title"].string ?? ""
            let thumb = v["thumbnailUrl"].string ?? ""
            let a = doc.createElement!("a")
            _ = a.setAttribute!("href", "https://www.youtube.com/watch?v=\(id)")
            _ = a.setAttribute!("target", "_blank")
            _ = a.setAttribute!("class", "flex-shrink-0 w-64 rounded-2xl overflow-hidden m3-shadow-md card")
            _ = a.innerHTML!("set", "<img src=\"\(thumb)\" alt=\"\(title)\" class=\"w-full h-36 object-cover\"><div class=\"p-3\"><p class=\"text-sm font-medium leading-tight\">\(title)</p></div>")
            _ = carousel.appendChild!("a)
        }
    }

    let fc = json["followerCounts"].object!
    var total = 0.0
    for key in ["youtube", "telegram", "twitch", "vk_group", "vk_personal"] {
        total += fc[key].double ?? 0
    }
    let totals = doc.getElementById!("totals")
    if !totals.isUndefined { _ = totals.textContent.set!(", t("followers") + fmtCount(total)) }

    let linksSection = doc.getElementById!("links-section")
    if !linksSection.isUndefined { renderLinksPage(json: json) }

    let ts2 = Int((jsGlobal("Date").new().getTime.number ?? 0))
    let resp2Val = try? await win.fetch!("/streams_history.json?t=\(ts2)")
    if let resp2Val = resp2Val,
       resp2Val.ok.boolean ?? false,
       let hist = try? await resp2Val.json!(") {
        let events = hist["events"].object!
        let len = events.length.number ?? 0
        streamEvents = [:]
        for i in 0..<Int(len) {
            let e = events[i]
            let date = e["date"].string ?? ""
            let platform = e["platform"].string ?? ""
            let url = e["url"].string ?? ""
            if streamEvents[date] == nil { streamEvents[date] = (yt: false, tw: false, ytUrl: "", twUrl: "") }
            if platform == "youtube" { streamEvents[date]?.yt = true; streamEvents[date]?.ytUrl = url }
            if platform == "twitch" { streamEvents[date]?.tw = true; streamEvents[date]?.twUrl = url }
        }
        renderCal()
    }
}

// MARK: - Links Page Rendering

struct LinkDef {
    let labelKey, url, icon, platformId, subscribeUrl: String
    let order, showCount: Int
}

let LINKS_CONFIG: [LinkDef] = [
    LinkDef(labelKey: "youtubeChannelLabel", url: "https://www.youtube.com/channel/UCm6mheCT60mZ5qlxG5r2GeA", icon: "play_arrow", platformId: "youtube", subscribeUrl: "https://www.youtube.com/channel/UCm6mheCT60mZ5qlxG5r2GeA?sub_confirmation=1", order: 1, showCount: 1),
    LinkDef(labelKey: "telegramChannelLabel", url: "https://t.me/bezzubickmcplay", icon: "send", platformId: "telegram", subscribeUrl: "", order: 2, showCount: 1),
    LinkDef(labelKey: "twitchChannelLabel", url: "https://www.twitch.tv/bezzubickmcplay", icon: "live_tv", platformId: "twitch", subscribeUrl: "", order: 3, showCount: 1),
    LinkDef(labelKey: "tiktokProfileLabel", url: "https://www.tiktok.com/@bezzubickmcplay", icon: "music_note", platformId: "tiktok", subscribeUrl: "", order: 4, showCount: 0),
    LinkDef(labelKey: "instagramProfileLabel", url: "https://www.instagram.com/bezzubickmcplay/", icon: "photo_camera", platformId: "instagram", subscribeUrl: "", order: 5, showCount: 0),
    LinkDef(labelKey: "xTwitterProfileLabel", url: "https://x.com/bezzubickmcplay", icon: "public", platformId: "x", subscribeUrl: "", order: 6, showCount: 0),
    LinkDef(labelKey: "vkGroupLabel", url: "https://vk.com/bezzubickmcplay", icon: "group", platformId: "vk_group", subscribeUrl: "", order: 7, showCount: 1),
    LinkDef(labelKey: "vkPersonalPageLabel", url: "https://vk.com/bezzubickmcplay_official", icon: "person", platformId: "vk_personal", subscribeUrl: "", order: 8, showCount: 1)
]

func renderLinksPage(json: JSValue) {
    let s = stateLang == "en" ? LINKS_STR_EN : LINKS_STR_RU
    let doc = jsGlobal("document")

    let nameEl = doc.getElementById!("profile-name")
    if !nameEl.isUndefined { _ = nameEl.textContent.set!(", s["profileName"] ?? "") }
    let descEl = doc.getElementById!("profile-description")
    if !descEl.isUndefined { _ = descEl.textContent.set!(", s.profileDescription ?? "") }

    let fc = json["followerCounts"].object!
    var total = 0.0
    for link in LINKS_CONFIG { total += fc[link.platformId].double ?? 0 }
    let tf = doc.getElementById!("total-followers")
    if !tf.isUndefined { _ = tf.textContent.set!(", (s["totalFollowers"] ?? "") + fmtCount(total)) }

    let section = doc.getElementById!("links-section")
    if !section.isUndefined {
        _ = section.innerHTML!("set", "")
        for link in LINKS_CONFIG {
            let a = doc.createElement!("a")
            _ = a.setAttribute!("href", link.url)
            _ = a.setAttribute!("target", "_blank")
            _ = a.setAttribute!("rel", "noopener noreferrer")
            _ = a.setAttribute!("class", "card relative flex items-center justify-between p-4 rounded-2xl m3-shadow-md swipe-target cursor-pointer")
            _ = a.setAttribute!("data-link-id", link.labelKey)
            _ = a.setAttribute!("data-platform-id", link.platformId)
            _ = a.setAttribute!("data-subscribe-url", link.subscribeUrl)
            _ = a.setAttribute!("data-url", link.url)
            var countText = ""
            if link.showCount != 0 {
                let c = fc[link.platformId].double ?? 0
                countText = "<span class=\"text-sm text-gray-400 mr-2 follower-count-display\">\(fmtCount(c))</span>"
            }
            let label = s[link.labelKey] ?? link.labelKey
            _ = a.innerHTML!("set", "<div class=\"flex items-center select-none\"><span class=\"material-symbols-outlined icon-large\">\(link.icon)</span><div><span class=\"block text-lg font-medium\">\(label)</span>\(countText)</div></div>")
            _ = section.appendChild!("a)
        }
        initSwipeGestures()
    }

    let btn = doc.getElementById!("support-button")
    if !btn.isUndefined { _ = btn.setAttribute!("href", "https://www.donationalerts.com/r/bezzubickmcplay") }
}

// MARK: - Links Page Live Stream

func renderLinksLiveStream(json: JSValue) {
    let info = json["liveStream"].object!
    let has = !(info.isUndefined) && (info["type"].string ?? "none") != "none"
    let doc = jsGlobal("document")
    let section = doc.getElementById!("live-stream-section")
    if !section.isUndefined {
        if has { _ = section.classList.remove!(", "hidden") } else { _ = section.classList.add!(", "hidden") }
    }
    if has {
        let embed = doc.getElementById!("live-embed")
        if !embed.isUndefined {
            if info["type"].string == "youtube", let vid = info["id"].string {
                _ = embed.setAttribute!("src", "https://www.youtube.com/embed/\(vid)?autoplay=1&mute=1")
            } else if info["type"].string == "twitch", let ch = info["twitchChannelName"].string {
                let parent = jsGlobal("window").location.hostname.string ?? "localhost"
                _ = embed.setAttribute!("src", "https://player.twitch.tv/?channel=\(ch)&parent=\(parent)&autoplay=true&mute=1")
            }
        }
    }
}

// MARK: - Swipe Gestures

func initSwipeGestures() {
    let cards = jsGlobal("document").querySelectorAll!(".swipe-target")
    let length = cards.length.number ?? 0
    for i in 0..<Int(length) {
        let card = cards[i]
        let platformId = card.getAttribute!("data-platform-id").string ?? ""
        let url = card.getAttribute!("data-url").string ?? ""
        let subUrl = card.getAttribute!("data-subscribe-url").string ?? ""
        var startX = 0.0
        var currentX = 0.0
        var pointerDown = false
        var swipeActive = false

        let onStart = JSClosure({ args in
            let e = args[0]
            pointerDown = true; swipeActive = false
            startX = e["touches"].isUndefined ? (e["clientX"].number ?? 0) : (e["touches"][0].clientX.number ?? 0)
            _ = card.style.setProperty!("transition", "none")
            return .undefined
        })
        let onMove = JSClosure({ args in
            guard pointerDown else { return .undefined }
            let e = args[0]
            currentX = e["touches"].isUndefined ? (e["clientX"].number ?? 0) : (e["touches"][0].clientX.number ?? 0)
            let dx = currentX - startX
            if !swipeActive && abs(dx) > 20 { swipeActive = true }
            if swipeActive { _ = card.style.setProperty!("transform", "translateX(\(dx)px)") }
            return .undefined
        })
        let onEnd = JSClosure({ _ in
            pointerDown = false
            _ = card.style.setProperty!("transition", "transform .2s ease")
            let dx = currentX - startX
            if swipeActive {
                let threshold = 100.0
                let direction = dx > 0 ? "right" : "left"
                let targetX = direction == "right" ? 200 : -200
                _ = card.style.setProperty!("transform", "translateX(\(targetX)px)")
                if direction == "right" { _ = card.setAttribute!("data-swiped", "true") }
                if direction == "left" { _ = card.setAttribute!("data-swiped", "false") }
                _ = card.classList.add!(", "swiped")
                swipeActive = false
            }
            return .undefined
        })
        _ = card.addEventListener!("touchstart", onStart)
        _ = card.addEventListener!("touchmove", onMove)
        _ = card.addEventListener!("touchend", onEnd)
        _ = card.addEventListener!("mousedown", onStart)
        _ = card.addEventListener!("mousemove", onMove)
        _ = card.addEventListener!("mouseup", onEnd)
    }
}

// MARK: - First Visit Modal

func setupModal() {
    let doc = jsGlobal("document")
    let modal = doc.getElementById!("first-visit-modal")
    let btn = doc.getElementById!("modal-close")
    if modal.isUndefined || btn.isUndefined { return }
    let seen = jsGlobal("localStorage").getItem!("visited_modal")
    if !seen.isUndefined { return }
    _ = modal.classList.add!(", "active")
    _ = btn.addEventListener!("click", JSClosure({ _ in
        _ = modal.classList.remove!(", "active")
        _ = jsGlobal("localStorage").setItem!("visited_modal", "true")
        return .undefined
    }))
}

// MARK: - Dev View

func setupDevView() {
    let doc = jsGlobal("document")
    let devBtn = doc.getElementById!("dev-toggle")
    if devBtn.isUndefined { return }
    _ = devBtn.addEventListener!("click", JSClosure({ _ in
        let mainView = doc.getElementById!("main-view")
        let devView = doc.getElementById!("dev-view")
        if !mainView.isUndefined { _ = mainView.classList.toggle!(", "hidden") }
        if !devView.isUndefined {
            _ = devView.classList.toggle!(", "hidden")
            let content = doc.getElementById!("dev-data-json-content")
            if !content.isUndefined { _ = content.textContent.set!(", "{}") }
            let upd = doc.getElementById!("dev-last-updated")
            if !upd.isUndefined {
                let now = jsGlobal("Date").new()
                let y = Int(now.getFullYear!(").number ?? 0)
                let m = Int(now.getMonth!(").number ?? 0) + 1
                let d = Int(now.getDate!(").number ?? 0)
                let hh = Int(now.getHours!(").number ?? 0)
                let mm = Int(now.getMinutes!(").number ?? 0)
                let ss = Int(now.getSeconds!(").number ?? 0)
                _ = upd.textContent.set!(", "\(y)-\(zeroPad(m, 2))-\(zeroPad(d, 2))T\(zeroPad(hh, 2)):\(zeroPad(mm, 2)):\(zeroPad(ss, 2))")
            }
        }
        return .undefined
    }))
    let backBtn = doc.getElementById!("back-to-main-button")
    if !backBtn.isUndefined {
        _ = backBtn.addEventListener!("click", JSClosure({ _ in
            let mv = doc.getElementById!("main-view")
            let dv = doc.getElementById!("dev-view")
            if !mv.isUndefined { _ = mv.classList.remove!(", "hidden") }
            if !dv.isUndefined { _ = dv.classList.add!(", "hidden") }
            return .undefined
        }))
    }
}

// MARK: - WebGL Liquid Glass

var glContext: JSObject?
var shaderProgram: JSObject?
var uniforms: [String: JSObject] = [:]
var lgCanvas: JSObject?
var panelData: [(x: Double, y: Double, w: Double, h: Double)] = []
var shouldRender = false
var animFrameId: JSValue = .undefined

let VERTEX_SHADER = """
#version 300 es
precision highp float;
in vec2 aPos;
in vec2 aUV;
out vec2 vUV;
void main() {
    gl_Position = vec4(aPos, 0.0, 1.0);
    vUV = aUV;
}
"""

let FRAGMENT_SHADER = """
#version 300 es
precision highp float;
in vec2 vUV;
out vec4 fragColor;
uniform vec4 uPanel;
uniform vec2 uResolution;
uniform vec2 uMouse;
uniform float uDark;
float sdRoundedBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}
vec3 bgGradient(vec2 uv) {
    vec3 a = mix(vec3(0.02,0.02,0.06), vec3(0.88,0.86,0.95), uDark);
    vec3 b = mix(vec3(0.06,0.03,0.12), vec3(0.95,0.90,0.92), uDark);
    return mix(a, b, uv.y*0.5+0.5+sin(uv.x*2.0)*0.1);
}
void main() {
    vec2 px = vUV * uResolution;
    vec2 halfS = uPanel.zw * 0.5;
    vec2 center = uPanel.xy + halfS;
    vec2 p = px - center;
    float cr = min(20.0, min(halfS.x, halfS.y) * 0.3);
    float d = sdRoundedBox(p, halfS, cr);
    vec2 asp = vec2(uResolution.x/uResolution.y, 1.0);
    float md = length((px/uResolution.y)*asp - uMouse*asp);
    vec2 dir = length(p) > 0.001 ? normalize(p) : vec2(0,1);
    vec2 off = -dir * smoothstep(0.6,0.0,md)*10.0 / max(abs(d)+4.0,1.0);
    vec2 uv = px/uResolution + off;
    float ca = 0.008 * smoothstep(0.4,0.0,md);
    vec3 bg = vec3(bgGradient(uv+vec2(ca,0)).r, bgGradient(uv).g, bgGradient(uv-vec2(0,ca)).b);
    float edge = smoothstep(0.0,-16.0,d);
    float inner = smoothstep(-1.0,-5.0,d);
    vec3 tint = mix(vec3(0.88,0.90,0.95), vec3(1.0), uDark);
    vec3 col = mix(bg*0.3, tint, edge*0.65) * mix(0.78,1.0,inner);
    vec2 hlC = normalize(vec2(-0.35,0.55))*uPanel.z*0.2;
    col += (1.0-smoothstep(-6.0,8.0,length(p-hlC)-uPanel.z*0.16))*mix(0.12,0.2,uDark);
    col -= (1.0-smoothstep(-4.0,12.0,length(p-normalize(vec2(0.25,-0.45))*uPanel.z*0.15)-uPanel.z*0.2))*0.06;
    col -= (1.0-smoothstep(-35.0,-6.0,d))*mix(0.3,0.15,uDark);
    col += exp(-pow(abs(d+2.5),2.0)/14.0)*0.14;
    fragColor = vec4(col, smoothstep(1.5,-2.5,d));
}
"""

func compileShader(_ src: String, _ type: Int32) -> JSObject? {
    guard let g = glContext else { return nil }
    let s = g.createShader!("type).object
    guard let s = s else { return nil }
    _ = g.shaderSource!("s, src)
    _ = g.compileShader!("s)
    guard g.getShaderParameter!("s, g.COMPILE_STATUS).boolean ?? false else { return nil }
    return s
}

func initWebGL() {
    let doc = jsGlobal("document")
    lgCanvas = doc.createElement!("canvas").object
    guard let canvas = lgCanvas else { return }
    _ = canvas.setAttribute!("id", "lg-canvas")
    _ = canvas.style.cssText.set("position:fixed;top:0;left:0;width:100vw;height:100vh;pointer-events:none;z-index:9998;display:block;")
    let body = doc.body.object!
    _ = body.insertBefore!("canvas, body.firstChild)
    glContext = canvas.getContext!("webgl2").object
    guard let g = glContext else { return }

    let prog = g.createProgram!(").object
    guard let prog = prog else { return }

    guard let vs = compileShader(VERTEX_SHADER, g.VERTEX_SHADER.number ?? 0x8B31),
          let fs = compileShader(FRAGMENT_SHADER, g.FRAGMENT_SHADER.number ?? 0x8B30) else { return }
    _ = g.attachShader!("prog, vs)
    _ = g.attachShader!("prog, fs)
    _ = g.linkProgram!("prog)
    guard g.getProgramParameter!("prog, g.LINK_STATUS).boolean ?? false else { return }
    shaderProgram = prog
    _ = g.useProgram!("prog)
    for name in ["uPanel", "uResolution", "uMouse", "uDark"] {
        uniforms[name] = g.getUniformLocation!(prog, name).object
    }
    let buf = g.createBuffer!(").object
    guard let buf = buf else { return }
    _ = g.bindBuffer!("g.ARRAY_BUFFER, buf)
    _ = g.bufferData!("g.ARRAY_BUFFER, [-1,-1, 0,0, 1,-1, 1,0, -1,1, 0,1, 1,1, 1,1], g.STATIC_DRAW)
    let posL = g.getAttribLocation!("prog, "aPos").number ?? 0
    let uvL = g.getAttribLocation!("prog, "aUV").number ?? 0
    _ = g.enableVertexAttribArray!("posL)
    _ = g.vertexAttribPointer!("posL, 2, g.FLOAT, false, 16, 0)
    _ = g.enableVertexAttribArray!("uvL)
    _ = g.vertexAttribPointer!("uvL, 2, g.FLOAT, false, 16, 8)
}

func scanCards() {
    let cards = jsGlobal("document").querySelectorAll!(".card")
    panelData = []
    let length = cards.length.number ?? 0
    for i in 0..<Int(length) {
        let r = cards[i].getBoundingClientRect!()
        let x = r["left"].number ?? 0
        let y = r["top"].number ?? 0
        let w = r["width"].number ?? 0
        let h = r["height"].number ?? 0
        if w > 10 && h > 10 { panelData.append((x, y, w, h)) }
    }
}

func renderFrame() {
    guard let g = glContext, let prog = shaderProgram else { return }
    let win = jsGlobal("window")
    let dpr = min(win.devicePixelRatio.number ?? 1.0, 2.0)
    let ww = win.innerWidth.number ?? 1
    let wh = win.innerHeight.number ?? 1
    _ = lgCanvas?.width.set(ww * dpr)
    _ = lgCanvas?.height.set(wh * dpr)
    _ = g.viewport!("0, 0, ww * dpr, wh * dpr)
    _ = g.clearColor!("0, 0, 0, 0)
    _ = g.clear!("g.COLOR_BUFFER_BIT)
    _ = g.enable!("g.BLEND)
    _ = g.blendFunc!("g.SRC_ALPHA, g.ONE_MINUS_SRC_ALPHA)
    if let u = uniforms.uResolution { _ = g.uniform2f!("u, ww * dpr, wh * dpr) }
    if let u = uniforms.uMouse { _ = g.uniform2f!("u, mouseXFrac, mouseYFrac) }
    if let u = uniforms.uDark { _ = g.uniform1f!("u, isDark ? 1.0 : 0.0) }
    for panel in panelData {
        if let u = uniforms.uPanel {
            _ = g.uniform4f!("u, panel.x * dpr, (wh - panel.y - panel.h) * dpr, panel.w * dpr, panel.h * dpr)
        }
        _ = g.drawArrays!("g.TRIANGLE_STRIP, 0, 4)
    }
}

func scheduleFrame() {
    guard shouldRender else { return }
    let closure = JSClosure({ _ in renderFrame(); scheduleFrame(); return .undefined })
    animFrameId = jsGlobal("window").requestAnimationFrame!("closure)
}

func startRendering() {
    guard !shouldRender else { return }
    shouldRender = true
    if glContext == nil { initWebGL() }
    scanCards(); scheduleFrame()
}

func stopRendering() { shouldRender = false }

// MARK: - Entry Point

@main struct SiteClient {
    static func main() async {
        #if os(WASI)
        let ready = JSClosure({ _ in
            let doc = jsGlobal("document")
            let isLinks = !doc.getElementById!("profile-section").isUndefined

            applyTheme(stateTheme)
            if isLinks { updateLinksTexts() } else { updateHomeTexts() }

            let toggleFn = JSClosure({ _ in toggleTheme(); return .undefined })
            let themeBottom = doc.getElementById!("theme-toggle-bottom")
            if !themeBottom.isUndefined { _ = themeBottom.addEventListener!("click", toggleFn) }
            let themeTop = doc.getElementById!("theme-toggle")
            if !themeTop.isUndefined { _ = themeTop.addEventListener!("click", toggleFn) }

            let langFn = JSClosure({ _ in
                stateLang = stateLang == "ru" ? "en" : "ru"
                if isLinks { updateLinksTexts() } else { updateHomeTexts() }
                if !isLinks { renderCal() }
                return .undefined
            })
            let langBottom = doc.getElementById!("lang-toggle-bottom")
            if !langBottom.isUndefined { _ = langBottom.addEventListener!("click", langFn) }
            let langTop = doc.getElementById!("language-toggle")
            if !langTop.isUndefined { _ = langTop.addEventListener!("click", langFn) }

            if !isLinks {
                setupCalendar()
                setupTimeline()
            }
            if isLinks {
                setupModal()
                setupDevView()
            }

            setupOffline()
            setupMouseTracking()
            setupScrollRescan()
            observeGlassState()

            Task { await fetchData() }

            return .undefined
        })
        _ = jsGlobal("document").addEventListener!("DOMContentLoaded", ready)
        #endif
    }
}

// MARK: - Helpers

func setupOffline() {
    let fn = JSClosure({ _ in
        let online = jsGlobal("navigator").onLine.boolean ?? true
        let w = jsGlobal("document").getElementById!("offline-warning")
        if !w.isUndefined {
            if online { _ = w.classList.add!(", "hidden") } else { _ = w.classList.remove!(", "hidden") }
        }
        return .undefined
    })
    let win = jsGlobal("window")
    _ = win.addEventListener!("online", fn)
    _ = win.addEventListener!("offline", fn)
}

func setupMouseTracking() {
    let win = jsGlobal("window")
    let fn = JSClosure({ args in
        let e = args[0]
        mouseXFrac = (e["clientX"].number ?? 0) / (win.innerWidth.number ?? 1)
        mouseYFrac = 1.0 - (e["clientY"].number ?? 0) / (win.innerHeight.number ?? 1)
        return .undefined
    })
    _ = win.addEventListener!("mousemove", fn)
    _ = win.addEventListener!("touchmove", fn)
}

func setupScrollRescan() {
    let fn = JSClosure({ _ in scanCards(); return .undefined })
    let win = jsGlobal("window")
    _ = win.addEventListener!("scroll", fn)
    _ = win.addEventListener!("resize", fn)
}

func observeGlassState() {
    let body = jsGlobal("document").body.object!
    let obs = jsGlobal("MutationObserver")
    let closure = JSClosure({ _ in
        let isGlass = body.classList.contains!(", "glass-dark").boolean ?? false || body.classList.contains!(", "glass-light").boolean ?? false
        if isGlass { startRendering() } else { stopRendering() }
        return .undefined
    })
    _ = obs.new!("closure)
    _ = obs.observe!(body, JSValue(dictionaryLiteral: ("attributes", true), ("attributeFilter", ["class"])))
    let isGlass = body.classList.contains!(", "glass-dark").boolean ?? false || body.classList.contains!(", "glass-light").boolean ?? false
    if isGlass { startRendering() }
}

func setupTimeline() {
    let doc = jsGlobal("document")
    let details = doc.querySelectorAll!("#timeline details")
    let detailsLen = details.length.number ?? 0
    for i in 0..<Int(detailsLen) {
        let d = details[i]
        let icon = d.querySelector!(".material-symbols-outlined")
        _ = d.addEventListener!(" "toggle", JSClosure({ _ in
            let open = d.open.boolean ?? false
            _ = icon.style.setProperty!("transform", open ? "rotate(180deg)" : "rotate(0deg)")
            return .undefined
        }))
    }
    let expandBtn = doc.getElementById!("tl-expand")
    if !expandBtn.isUndefined {
        _ = expandBtn.addEventListener!("click", JSClosure({ _ in
            let all = doc.querySelectorAll!("#timeline details")
            let allLen = all.length.number ?? 0
            for i in 0..<Int(allLen) { all[i].open = .boolean(true) }
            return .undefined
        }))
    }
    let collapseBtn = doc.getElementById!("tl-collapse")
    if !collapseBtn.isUndefined {
        _ = collapseBtn.addEventListener!("click", JSClosure({ _ in
            let all = doc.querySelectorAll!("#timeline details")
            let allLen = all.length.number ?? 0
            for i in 0..<Int(allLen) { all[i].open = .boolean(false) }
            return .undefined
        }))
    }
}

#endif