import JavaScriptEventLoop
import JavaScriptKit

#if os(WASI)

JavaScriptEventLoop.installGlobalExecutor()

// MARK: - Convenience helpers

let doc = JSObject.global.document
let win = JSObject.global.window

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

let localStorage = JSObject.global.localStorage

var stateTheme: String {
  get {
    let v = localStorage.getItem("theme")
    return v.isUndefined ? "dark" : (v.string ?? "dark")
  }
  set { _ = localStorage.setItem("theme", newValue) }
}

var stateLang: String {
  get {
    let stored = localStorage.getItem("lang")
    if !stored.isUndefined, let s = stored.string { return s }
    let navLang = JSObject.global.navigator.language.string ?? "ru"
    return navLang.hasPrefix("ru") ? "ru" : "en"
  }
  set { _ = localStorage.setItem("lang", newValue) }
}

// MARK: - Strings (Home)

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
  "navTitle": "Navigation",
  "navDesc": "Go to the page with all my links, socials, skin, and dev info.",
  "navCta": "Go to Links",
  "skinTitle": "My Minecraft Skin",
  "skinDl": "Download Skin",
  "videosTitle": "Latest Videos",
  "tlTitle": "Channel Timeline",
  "expand": "Expand",
  "collapse": "Collapse",
  "liveEmpty": "No stream right now",
  "liveSub": "Streams are usually on Fridays, 17:00–19:00 MSK.",
  "legendYt": "YouTube", "legendTw": "Twitch",
  "legendBoth": "Both", "legendPlanned": "Planned",
  "legendMissed": "Struck-out — there was no stream",
  "twitchAlso": "Stream is also live on Twitch!",
  "twitchCta": "Watch on Twitch"
]

// MARK: - Strings (Links)

let LINKS_STR_EN: [String: String] = [
  "recentVideosTitle": "Recent Videos",
  "modalTitle": "Welcome!",
  "modalDescription": "Swipe right on a link card to subscribe, swipe left on YouTube links to open the latest video or a live stream.",
  "gotItButton": "Got it!",
  "totalFollowers": "Total Followers: ",
  "minecraftTitle": "My Minecraft Skin",
  "downloadSkin": "Download Skin",
  "loading": "Loading...",
  "supportButton": "Support Me",
  "offlineMessage": "You are offline. Data might be outdated.",
  "devPageTitle": "Developer Info",
  "devLastUpdatedLabel": "Last Data Update:",
  "devDataJsonContentLabel": "data.json Content:",
  "devDebugInfoContentLabel": "API Debug Info:",
  "backToMainText": "Back to Main Site",
  "openLinkButton": "Open Link",
  "closeButton": "Close",
  "profileName": "BezzubickMCPlay",
  "profileDescription": "Minecraft adventures | Streams | Creativity",
  "avatarAlt": "BezzubickMCPlay profile avatar",
  "twitchStreamAlsoLive": "Stream also live on Twitch!",
  "youtubeChannelLabel": "YouTube Channel",
  "telegramChannelLabel": "Telegram Channel",
  "instagramProfileLabel": "Instagram Profile",
  "xTwitterProfileLabel": "X (Twitter) Profile",
  "twitchChannelLabel": "Twitch Channel",
  "tiktokProfileLabel": "TikTok Profile",
  "vkGroupLabel": "VK Group",
  "vkPersonalPageLabel": "VK Personal Page",
  "watchOnTwitch": "Watch on Twitch"
]
let LINKS_STR_RU: [String: String] = [
  "recentVideosTitle": "Последние видео",
  "modalTitle": "Добро пожаловать!",
  "modalDescription": "Проведите вправо по карточке ссылки, чтобы подписаться. Проведите влево по YouTube-ссылкам, чтобы открыть последнее видео или прямой эфир.",
  "gotItButton": "Понятно!",
  "totalFollowers": "Всего подписчиков: ",
  "minecraftTitle": "Мой скин Minecraft",
  "downloadSkin": "Скачать скин",
  "loading": "Загрузка...",
  "supportButton": "Поддержать меня",
  "offlineMessage": "Вы не в сети.",
  "devPageTitle": "Инфо для разработчиков",
  "devLastUpdatedLabel": "Последнее обновление:",
  "devDataJsonContentLabel": "data.json:",
  "devDebugInfoContentLabel": "API Debug:",
  "backToMainText": "На главную",
  "openLinkButton": "Открыть",
  "closeButton": "Закрыть",
  "profileName": "BezzubickMCPlay",
  "profileDescription": "Майнкрафт | Стримы | Творчество",
  "avatarAlt": "Аватар BezzubickMCPlay",
  "twitchStreamAlsoLive": "Стрим также идёт на Twitch!",
  "youtubeChannelLabel": "Канал YouTube",
  "telegramChannelLabel": "Канал Telegram",
  "instagramProfileLabel": "Профиль Instagram",
  "xTwitterProfileLabel": "Профиль X (Twitter)",
  "twitchChannelLabel": "Канал Twitch",
  "tiktokProfileLabel": "Профиль TikTok",
  "vkGroupLabel": "Группа VK",
  "vkPersonalPageLabel": "Страница VK",
  "watchOnTwitch": "Смотреть на Twitch"
]

// MARK: - Set / translate helpers

func setById(_ id: String, _ val: String) {
  let el = doc.getElementById(id)
  if !el.isUndefined && !el.isNull { el.textContent = .string(val) }
}

func t(_ k: String) -> String {
  let hasLinks = !doc.getElementById("links-section").isUndefined
  let hasProfile = !doc.getElementById("profile-section").isUndefined
  if hasLinks || hasProfile {
    return (stateLang == "en" ? LINKS_STR_EN : LINKS_STR_RU)[k] ?? k
  }
  return (stateLang == "en" ? HOME_STR_EN : HOME_STR_RU)[k] ?? k
}

// MARK: - Theme

let THEMES = ["dark", "light", "glass-dark", "glass-light"]
let THEME_ICONS: [String: String] = [
  "dark": "light_mode", "light": "dark_mode",
  "glass-dark": "light_mode", "glass-light": "dark_mode"
]
let THEME_CLASSES: [String: String] = [
  "dark": "dark-theme", "light": "light-theme",
  "glass-dark": "glass-dark", "glass-light": "glass-light"
]

func applyTheme(_ theme: String) {
  let body = doc.body

  for cls in ["dark-theme", "light-theme", "glass-dark", "glass-light"] {
    _ = body.classList.remove(cls)
  }
  _ = body.classList.add(THEME_CLASSES[theme] ?? "dark-theme")
  stateTheme = theme
  isDark = theme.contains("dark")

  let iconBottom = doc.getElementById("theme-icon-bottom")
  if !iconBottom.isUndefined { iconBottom.textContent = .string(THEME_ICONS[theme] ?? "light_mode") }
  let iconTop = doc.getElementById("theme-icon")
  if !iconTop.isUndefined { iconTop.textContent = .string(THEME_ICONS[theme] ?? "light_mode") }
}

func toggleTheme() {
  let idx = THEMES.firstIndex(of: stateTheme) ?? 0
  applyTheme(THEMES[(idx + 1) % THEMES.count])
}

// MARK: - Language

func updateLangContent() {
  let els = doc.querySelectorAll("[data-lang]")
  let length = Int(els.length.number ?? 0)
  for i in 0..<length {
    let el = els[i]
    let lang = el.getAttribute("data-lang").string ?? ""
    _ = el.style.setProperty("display", lang == stateLang ? "" : "none")
  }
}

func updateHomeTexts() {
  let s = stateLang == "en" ? HOME_STR_EN : HOME_STR_RU
  setById("totals", (s["followers"] ?? "") + "\u{2014}")
  setById("nav-title", s["navTitle"] ?? "")
  setById("nav-desc", s["navDesc"] ?? "")
  setById("go-links-text", s["navCta"] ?? "")
  setById("go-links-btn-text-2", s["navCta"] ?? "")
  setById("skin-title", s["skinTitle"] ?? "")
  setById("skin-download-text", s["skinDl"] ?? "")
  setById("videos-title", s["videosTitle"] ?? "")
  setById("timeline-title", s["tlTitle"] ?? "")
  setById("tl-expand-text", s["expand"] ?? "")
  setById("tl-collapse-text", s["collapse"] ?? "")
  setById("live-empty-title", s["liveEmpty"] ?? "")
  setById("live-empty-sub", s["liveSub"] ?? "")
  setById("legend-yt", s["legendYt"] ?? "")
  setById("legend-tw", s["legendTw"] ?? "")
  setById("legend-both", s["legendBoth"] ?? "")
  setById("legend-planned", s["legendPlanned"] ?? "")
  setById("legend-missed", s["legendMissed"] ?? "")
  setById("twitch-text", s["twitchAlso"] ?? "")
  setById("twitch-cta", s["twitchCta"] ?? "")
  updateLangContent()
}

func updateLinksTexts() {
  let s = stateLang == "en" ? LINKS_STR_EN : LINKS_STR_RU
  setById("modal-title", s["modalTitle"] ?? "")
  setById("modal-description", s["modalDescription"] ?? "")
  setById("modal-close", s["gotItButton"] ?? "")
  setById("recent-videos-title", s["recentVideosTitle"] ?? "")
  setById("minecraft-title", s["minecraftTitle"] ?? "")
  setById("download-skin-text", s["downloadSkin"] ?? "")
  setById("support-button-text", s["supportButton"] ?? "")
  setById("offline-message", s["offlineMessage"] ?? "")
  setById("dev-title", s["devPageTitle"] ?? "")
  setById("dev-last-updated-label", s["devLastUpdatedLabel"] ?? "")
  setById("dev-data-json-content-label", s["devDataJsonContentLabel"] ?? "")
  setById("dev-debug-info-content-label", s["devDebugInfoContentLabel"] ?? "")
  setById("back-to-main-text", s["backToMainText"] ?? "")
  setById("twitch-message", s["twitchStreamAlsoLive"] ?? "")
  setById("twitch-link-text", s["watchOnTwitch"] ?? "")
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

let DateObj = JSObject.global.Date.object!

func setupCalendar() {
  let now = DateObj.new!()
  calYear = Int(now.getFullYear().number ?? 0)
  calMonth = Int(now.getMonth().number ?? 0)

  let prev = doc.getElementById("cal-prev")
  if !prev.isUndefined {
    _ = prev.addEventListener("click", JSClosure { _ in
      calMonth -= 1
      if calMonth < 0 { calMonth = 11; calYear -= 1 }
      renderCal()
      return .undefined
    })
  }
  let next = doc.getElementById("cal-next")
  if !next.isUndefined {
    _ = next.addEventListener("click", JSClosure { _ in
      calMonth += 1
      if calMonth > 11 { calMonth = 0; calYear += 1 }
      renderCal()
      return .undefined
    })
  }
  renderCal()
}

func renderCal() {
  let months = stateLang == "en" ? MONTHS_EN : MONTHS_RU
  let wdays = stateLang == "en" ? WDAYS_EN : WDAYS_RU

  let label = doc.getElementById("cal-label")
  if !label.isUndefined { label.textContent = .string("\(months[calMonth]) \(calYear)") }

  let head = doc.getElementById("cal-weekdays")
  if !head.isUndefined { head.innerHTML = .string(wdays.map { "<div>\($0)</div>" }.joined(separator: "")) }

  let firstDow = DateObj.new!(calYear, calMonth, 1)
  let startDow = ((Int(firstDow.getDay().number ?? 0)) + 6) % 7
  let daysInMonth = Int(DateObj.new!(calYear, calMonth + 1, 0).getDate().number ?? 30)

  let today = DateObj.new!()
  _ = today.setHours(0, 0, 0, 0)
  let todayTime = today.getTime().number ?? 0

  var html = ""
  for _ in 0..<startDow { html += "<div></div>" }
  for d in 1...daysInMonth {
    let dt = DateObj.new!(calYear, calMonth, d)
    let dtTime = dt.getTime().number ?? 0
    let isToday = dtTime == todayTime
    let isPast = dtTime < todayTime
    let dow = ((Int(dt.getDay().number ?? 0)) + 6) % 7
    var cls: [String] = ["cell"]
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

  let grid = doc.getElementById("cal-grid")
  if !grid.isUndefined { grid.innerHTML = .string(html) }
}

// MARK: - Data Fetch

let fetchFn = JSObject.global.fetch.object!

func jsFetch(_ url: String) async -> JSValue? {
  guard let respObj = fetchFn!(url).object,
        let promise = JSPromise(respObj) else { return nil }
  return try? await promise.value
}

func jsJSON(_ resp: JSValue) async -> JSValue? {
  guard let promiseObj = resp.json().object,
        let promise = JSPromise(promiseObj) else { return nil }
  return try? await promise.value
}

func fetchData() async {
  let ts = Int(DateObj.new!().getTime().number ?? 0)

  guard let resp = await jsFetch("/data.json?t=\(ts)"),
        resp.ok.boolean ?? false,
        let json = await jsJSON(resp) else { return }

  let docObj = JSObject.global.document

  let vids = json.object!["youtubeVideos"]
  let carousel = docObj.getElementById("carousel")
  if !carousel.isUndefined {
    carousel.innerHTML = .string("")
    let len = Int(vids.length.number ?? 0)
    for i in 0..<len {
      let v = vids[i]
      let id = v.id.string ?? ""
      let title = v.title.string ?? ""
      let thumb = v.thumbnailUrl.string ?? ""
      let a = docObj.createElement("a")
      _ = a.setAttribute("href", "https://www.youtube.com/watch?v=\(id)")
      _ = a.setAttribute("target", "_blank")
      _ = a.setAttribute("class", "flex-shrink-0 w-64 rounded-2xl overflow-hidden m3-shadow-md card")
      a.innerHTML = .string("<img src=\"\(thumb)\" alt=\"\(title)\" class=\"w-full h-36 object-cover\"><div class=\"p-3\"><p class=\"text-sm font-medium leading-tight\">\(title)</p></div>")
      _ = carousel.appendChild(a)
    }
  }

  let fc = json.object!["followerCounts"]
  var total = 0.0
  for key in ["youtube", "telegram", "twitch", "vk_group", "vk_personal"] {
    total += fc.object![key].number ?? 0
  }
  let totals = docObj.getElementById("totals")
  if !totals.isUndefined {
    totals.textContent = .string(t("followers") + fmtCount(total))
  }

  if !docObj.getElementById("links-section").isUndefined {
    renderLinksPage(json: json)
  }

  let ts2 = Int(DateObj.new!().getTime().number ?? 0)
  guard let resp2 = await jsFetch("/streams_history.json?t=\(ts2)"),
        resp2.ok.boolean ?? false,
        let hist = await jsJSON(resp2) else { return }

  let events = hist.object!["events"]
  let len = Int(events.length.number ?? 0)
  streamEvents = [:]
  for i in 0..<len {
    let e = events[i]
    let date = e.object!["date"].string ?? ""
    let platform = e.object!["platform"].string ?? ""
    let url = e.object!["url"].string ?? ""
    if streamEvents[date] == nil { streamEvents[date] = (yt: false, tw: false, ytUrl: "", twUrl: "") }
    if platform == "youtube" { streamEvents[date]?.yt = true; streamEvents[date]?.ytUrl = url }
    if platform == "twitch" { streamEvents[date]?.tw = true; streamEvents[date]?.twUrl = url }
  }
  renderCal()
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
  let docObj = JSObject.global.document

  let nameEl = docObj.getElementById("profile-name")
  if !nameEl.isUndefined { nameEl.textContent = .string(s["profileName"] ?? "") }
  let descEl = docObj.getElementById("profile-description")
  if !descEl.isUndefined { descEl.textContent = .string(s["profileDescription"] ?? "") }

  let fc = json.object!["followerCounts"]
  var total = 0.0
  for link in LINKS_CONFIG { total += fc.object![link.platformId].number ?? 0 }
  let tf = docObj.getElementById("total-followers")
  if !tf.isUndefined { tf.textContent = .string((s["totalFollowers"] ?? "") + fmtCount(total)) }

  let section = docObj.getElementById("links-section")
  if !section.isUndefined {
    section.innerHTML = .string("")
    for link in LINKS_CONFIG {
      let a = docObj.createElement("a")
      _ = a.setAttribute("href", link.url)
      _ = a.setAttribute("target", "_blank")
      _ = a.setAttribute("rel", "noopener noreferrer")
      _ = a.setAttribute("class", "card relative flex items-center justify-between p-4 rounded-2xl m3-shadow-md swipe-target cursor-pointer")
      _ = a.setAttribute("data-link-id", link.labelKey)
      _ = a.setAttribute("data-platform-id", link.platformId)
      _ = a.setAttribute("data-subscribe-url", link.subscribeUrl)
      _ = a.setAttribute("data-url", link.url)
      var countText = ""
      if link.showCount != 0 {
        let c = fc.object![link.platformId].number ?? 0
        countText = "<span class=\"text-sm text-gray-400 mr-2 follower-count-display\">\(fmtCount(c))</span>"
      }
      let label = s[link.labelKey] ?? link.labelKey
      a.innerHTML = .string("<div class=\"flex items-center select-none\"><span class=\"material-symbols-outlined icon-large\">\(link.icon)</span><div><span class=\"block text-lg font-medium\">\(label)</span>\(countText)</div></div>")
      _ = section.appendChild(a)
    }
    initSwipeGestures()
  }

  let btn = docObj.getElementById("support-button")
  if !btn.isUndefined { _ = btn.setAttribute("href", "https://www.donationalerts.com/r/bezzubickmcplay") }
}

// MARK: - Links Page Live Stream

func renderLinksLiveStream(json: JSValue) {
  let info = json.object!["liveStream"]
  let has = !info.isUndefined && (info.type.string ?? "none") != "none"
  let docObj = JSObject.global.document
  let section = docObj.getElementById("live-stream-section")
  if !section.isUndefined {
    if has { _ = section.classList.remove("hidden") } else { _ = section.classList.add("hidden") }
  }
  if has {
    let embed = docObj.getElementById("live-embed")
    if !embed.isUndefined {
      if info.type.string == "youtube", let vid = info.id.string {
        _ = embed.setAttribute("src", "https://www.youtube.com/embed/\(vid)?autoplay=1&mute=1")
      } else if info.type.string == "twitch", let ch = info.twitchChannelName.string {
        let parent = win.location.hostname.string ?? "localhost"
        _ = embed.setAttribute("src", "https://player.twitch.tv/?channel=\(ch)&parent=\(parent)&autoplay=true&mute=1")
      }
    }
  }
}

// MARK: - Swipe Gestures

func initSwipeGestures() {
  let cards = doc.querySelectorAll(".swipe-target")
  let length = Int(cards.length.number ?? 0)
  for i in 0..<length {
    let card = cards[i]
    let platformId = card.getAttribute("data-platform-id").string ?? ""
    let url = card.getAttribute("data-url").string ?? ""
    let subUrl = card.getAttribute("data-subscribe-url").string ?? ""
    var startX = 0.0
    var currentX = 0.0
    var pointerDown = false
    var swipeActive = false

    let onStart = JSClosure { args in
      let e = args[0]
      pointerDown = true; swipeActive = false
      let touches = e.object!["touches"]
      startX = touches.isUndefined ? (e.clientX.number ?? 0) : (touches[0].object!["clientX"].number ?? 0)
      _ = card.style.setProperty("transition", "none")
      return .undefined
    }
    // need to hold closures for the loop lifetime. We keep them alive via the closures dict
    let onMove = JSClosure { args in
      guard pointerDown else { return .undefined }
      let e = args[0]
      currentX = e.object!["touches"].isUndefined ? (e.clientX.number ?? 0) : (e.object!["touches"][0].object!["clientX"].number ?? 0)
      let dx = currentX - startX
      if !swipeActive && abs(dx) > 20 { swipeActive = true }
      if swipeActive { _ = card.style.setProperty("transform", "translateX(\(dx)px)") }
      return .undefined
    }
    let onEnd = JSClosure { _ in
      pointerDown = false
      _ = card.style.setProperty("transition", "transform .2s ease")
      let dx = currentX - startX
      if swipeActive {
        let direction = dx > 0 ? "right" : "left"
        let targetX = direction == "right" ? 200 : -200
        _ = card.style.setProperty("transform", "translateX(\(targetX)px)")
        if direction == "right" { _ = card.setAttribute("data-swiped", "true") }
        if direction == "left" { _ = card.setAttribute("data-swiped", "false") }
        _ = card.classList.add("swiped")
        swipeActive = false
      }
      return .undefined
    }

    _ = card.addEventListener("touchstart", onStart)
    _ = card.addEventListener("touchmove", onMove)
    _ = card.addEventListener("touchend", onEnd)
    _ = card.addEventListener("mousedown", onStart)
    _ = card.addEventListener("mousemove", onMove)
    _ = card.addEventListener("mouseup", onEnd)
  }
}

// MARK: - First Visit Modal

func setupModal() {
  let docObj = JSObject.global.document
  let modal = docObj.getElementById("first-visit-modal")
  let btn = docObj.getElementById("modal-close")
  if modal.isUndefined || btn.isUndefined { return }
  let seen = localStorage.getItem("visited_modal")
  if !seen.isUndefined { return }
  _ = modal.classList.add("active")
  _ = btn.addEventListener("click", JSClosure { _ in
    _ = modal.classList.remove("active")
    _ = localStorage.setItem("visited_modal", "true")
    return .undefined
  })
}

// MARK: - Dev View

func setupDevView() {
  let docObj = JSObject.global.document
  let devBtn = docObj.getElementById("dev-toggle")
  if devBtn.isUndefined { return }
  _ = devBtn.addEventListener("click", JSClosure { _ in
    let mainView = docObj.getElementById("main-view")
    let devView = docObj.getElementById("dev-view")
    if !mainView.isUndefined { _ = mainView.classList.toggle("hidden") }
    if !devView.isUndefined {
      _ = devView.classList.toggle("hidden")
      let content = docObj.getElementById("dev-data-json-content")
      if !content.isUndefined { content.textContent = .string("{}") }
      let upd = docObj.getElementById("dev-last-updated")
      if !upd.isUndefined {
        let now = DateObj.new!()
        let y = Int(now.getFullYear().number ?? 0)
        let m = Int(now.getMonth().number ?? 0) + 1
        let d = Int(now.getDate().number ?? 0)
        let hh = Int(now.getHours().number ?? 0)
        let mm = Int(now.getMinutes().number ?? 0)
        let ss = Int(now.getSeconds().number ?? 0)
        upd.textContent = .string("\(y)-\(zeroPad(m, 2))-\(zeroPad(d, 2))T\(zeroPad(hh, 2)):\(zeroPad(mm, 2)):\(zeroPad(ss, 2))")
      }
    }
    return .undefined
  })
  let backBtn = docObj.getElementById("back-to-main-button")
  if !backBtn.isUndefined {
    _ = backBtn.addEventListener("click", JSClosure { _ in
      let mv = docObj.getElementById("main-view")
      let dv = docObj.getElementById("dev-view")
      if !mv.isUndefined { _ = mv.classList.remove("hidden") }
      if !dv.isUndefined { _ = dv.classList.add("hidden") }
      return .undefined
    })
  }
}

// MARK: - WebGL Liquid Glass

var glCtx: JSValue = .undefined
var shaderProg: JSValue = .undefined
var uniformLocs: [String: JSValue] = [:]
var lgCanvas: JSValue = .undefined
var panelData: [(x: Double, y: Double, w: Double, h: Double)] = []
var shouldRender = false
var rafId: JSValue = .undefined
var rafClosure: JSClosure?

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

func compileShader(_ src: String, _ type: Int32) -> JSValue? {
  if glCtx.isUndefined { return nil }
  let s = glCtx.createShader(type)
  if s.isNull || s.isUndefined { return nil }
  _ = glCtx.shaderSource(s, src)
  _ = glCtx.compileShader(s)
  guard glCtx.getShaderParameter(s, glCtx.COMPILE_STATUS).boolean ?? false else { return nil }
  return s
}

func initWebGL() {
  let docObj = JSObject.global.document
  lgCanvas = docObj.createElement("canvas")
  let canvas = lgCanvas
  if canvas.isUndefined { return }
  _ = canvas.setAttribute("id", "lg-canvas")
  canvas.style.cssText = .string("position:fixed;top:0;left:0;width:100vw;height:100vh;pointer-events:none;z-index:9998;display:block;")
  let body = docObj.body
  _ = body.insertBefore(canvas, body.firstChild)
  glCtx = canvas.getContext("webgl2")
  if glCtx.isUndefined || glCtx.isNull { return }

  let prog = glCtx.createProgram()
  if prog.isUndefined { return }

  guard let vs = compileShader(VERTEX_SHADER, Int32(glCtx.VERTEX_SHADER.number ?? 0x8B31)),
        let fs = compileShader(FRAGMENT_SHADER, Int32(glCtx.FRAGMENT_SHADER.number ?? 0x8B30)) else { return }
  _ = glCtx.attachShader(prog, vs)
  _ = glCtx.attachShader(prog, fs)
  _ = glCtx.linkProgram(prog)
  guard glCtx.getProgramParameter(prog, glCtx.LINK_STATUS).boolean ?? false else { return }
  shaderProg = prog
  _ = glCtx.useProgram(prog)
  for name in ["uPanel", "uResolution", "uMouse", "uDark"] {
    uniformLocs[name] = glCtx.getUniformLocation(prog, name)
  }

  let buf = glCtx.createBuffer()
  if buf.isUndefined { return }
  _ = glCtx.bindBuffer(glCtx.ARRAY_BUFFER, buf)
  let vertData: [Double] = [-1,-1, 0,0, 1,-1, 1,0, -1,1, 0,1, 1,1, 1,1]
  _ = glCtx.bufferData(glCtx.ARRAY_BUFFER, vertData.jsValue, glCtx.STATIC_DRAW)

  let posL = glCtx.getAttribLocation(prog, "aPos").number ?? 0
  let uvL = glCtx.getAttribLocation(prog, "aUV").number ?? 0
  _ = glCtx.enableVertexAttribArray(posL)
  _ = glCtx.vertexAttribPointer(posL, 2, glCtx.FLOAT, false, 16, 0)
  _ = glCtx.enableVertexAttribArray(uvL)
  _ = glCtx.vertexAttribPointer(uvL, 2, glCtx.FLOAT, false, 16, 8)
}

func scanCards() {
  let cards = doc.querySelectorAll(".card")
  panelData = []
  let length = Int(cards.length.number ?? 0)
  for i in 0..<length {
    let r = cards[i].getBoundingClientRect()
    let x = r.left.number ?? 0
    let y = r.top.number ?? 0
    let w = r.width.number ?? 0
    let h = r.height.number ?? 0
    if w > 10 && h > 10 { panelData.append((x, y, w, h)) }
  }
}

func renderFrame() {
  if glCtx.isUndefined || shaderProg.isUndefined { return }
  let dpr = min(win.devicePixelRatio.number ?? 1.0, 2.0)
  let ww = win.innerWidth.number ?? 1
  let wh = win.innerHeight.number ?? 1

  if !lgCanvas.isUndefined {
    lgCanvas.width = .number(ww * dpr)
    lgCanvas.height = .number(wh * dpr)
  }

  _ = glCtx.viewport(0, 0, ww * dpr, wh * dpr)
  _ = glCtx.clearColor(0, 0, 0, 0)
  _ = glCtx.clear(glCtx.COLOR_BUFFER_BIT)
  _ = glCtx.enable(glCtx.BLEND)
  _ = glCtx.blendFunc(glCtx.SRC_ALPHA, glCtx.ONE_MINUS_SRC_ALPHA)

  if let u = uniformLocs["uResolution"] {
    if !u.isUndefined { _ = glCtx.uniform2f(u, ww * dpr, wh * dpr) }
  }
  if let u = uniformLocs["uMouse"] {
    if !u.isUndefined { _ = glCtx.uniform2f(u, mouseXFrac, mouseYFrac) }
  }
  if let u = uniformLocs["uDark"] {
    if !u.isUndefined { _ = glCtx.uniform1f(u, isDark ? 1.0 : 0.0) }
  }
  for panel in panelData {
    if let u = uniformLocs["uPanel"] {
      if !u.isUndefined {
        _ = glCtx.uniform4f(u, panel.x * dpr, (wh - panel.y - panel.h) * dpr, panel.w * dpr, panel.h * dpr)
      }
    }
    _ = glCtx.drawArrays(glCtx.TRIANGLE_STRIP, 0, 4)
  }
}

func scheduleFrame() {
  guard shouldRender else { return }
  if rafClosure == nil {
    rafClosure = JSClosure { _ in
      renderFrame()
      scheduleFrame()
      return .undefined
    }
  }
  rafId = win.requestAnimationFrame(rafClosure!)
}

func startRendering() {
  guard !shouldRender else { return }
  shouldRender = true
  if glCtx.isUndefined { initWebGL() }
  scanCards()
  scheduleFrame()
}

func stopRendering() { shouldRender = false }

// MARK: - Helpers

func setupOffline() {
  let fn = JSClosure { _ in
    let online = JSObject.global.navigator.onLine.boolean ?? true
    let w = JSObject.global.document.getElementById("offline-warning")
    if !w.isUndefined {
      if online { _ = w.classList.add("hidden") } else { _ = w.classList.remove("hidden") }
    }
    return .undefined
  }
  _ = win.addEventListener("online", fn)
  _ = win.addEventListener("offline", fn)
}

func setupMouseTracking() {
  let fn = JSClosure { args in
    let e = args[0]
    mouseXFrac = (e.clientX.number ?? 0) / (win.innerWidth.number ?? 1)
    mouseYFrac = 1.0 - (e.clientY.number ?? 0) / (win.innerHeight.number ?? 1)
    return .undefined
  }
  _ = win.addEventListener("mousemove", fn)
  _ = win.addEventListener("touchmove", fn)
}

func setupScrollRescan() {
  let fn = JSClosure { _ in scanCards(); return .undefined }
  _ = win.addEventListener("scroll", fn)
  _ = win.addEventListener("resize", fn)
}

func observeGlassState() {
  let body = doc.body
  let ObsCtor = JSObject.global.MutationObserver.object!
  let cb = JSClosure { _ in
    let isGlass = (body.classList.contains("glass-dark").boolean ?? false) || (body.classList.contains("glass-light").boolean ?? false)
    if isGlass { startRendering() } else { stopRendering() }
    return .undefined
  }
  let observer = ObsCtor.new!(cb)
  let config = JSObject()
  config["attributes"] = .boolean(true)
  config["attributeFilter"] = ["class"].jsValue
  _ = observer.observe(body, .object(config))
  let isGlass = (body.classList.contains("glass-dark").boolean ?? false) || (body.classList.contains("glass-light").boolean ?? false)
  if isGlass { startRendering() }
}

func setupTimeline() {
  let docObj = JSObject.global.document
  let details = docObj.querySelectorAll("#timeline details")
  let detailsLen = Int(details.length.number ?? 0)
  for i in 0..<detailsLen {
    let d = details[i]
    let icon = d.querySelector(".material-symbols-outlined")
    _ = d.addEventListener("toggle", JSClosure { _ in
      let open = d.open.boolean ?? false
      _ = icon.style.setProperty("transform", open ? "rotate(180deg)" : "rotate(0deg)")
      return .undefined
    })
  }
  let expandBtn = docObj.getElementById("tl-expand")
  if !expandBtn.isUndefined {
    _ = expandBtn.addEventListener("click", JSClosure { _ in
      let all = docObj.querySelectorAll("#timeline details")
      let allLen = Int(all.length.number ?? 0)
      for j in 0..<allLen { all[j].open = .boolean(true) }
      return .undefined
    })
  }
  let collapseBtn = docObj.getElementById("tl-collapse")
  if !collapseBtn.isUndefined {
    _ = collapseBtn.addEventListener("click", JSClosure { _ in
      let all = docObj.querySelectorAll("#timeline details")
      let allLen = Int(all.length.number ?? 0)
      for j in 0..<allLen { all[j].open = .boolean(false) }
      return .undefined
    })
  }
}

// MARK: - Entry Point

let readyClosure = JSClosure { _ in
  let docObj = JSObject.global.document
  let isLinks = !docObj.getElementById("profile-section").isUndefined

  applyTheme(stateTheme)
  if isLinks { updateLinksTexts() } else { updateHomeTexts() }

  let toggleFn = JSClosure { _ in toggleTheme(); return .undefined }
  let themeBottom = docObj.getElementById("theme-toggle-bottom")
  if !themeBottom.isUndefined { _ = themeBottom.addEventListener("click", toggleFn) }
  let themeTop = docObj.getElementById("theme-toggle")
  if !themeTop.isUndefined { _ = themeTop.addEventListener("click", toggleFn) }

  let langFn = JSClosure { _ in
    stateLang = stateLang == "ru" ? "en" : "ru"
    if isLinks { updateLinksTexts() } else { updateHomeTexts() }
    if !isLinks { renderCal() }
    return .undefined
  }
  let langBottom = docObj.getElementById("lang-toggle-bottom")
  if !langBottom.isUndefined { _ = langBottom.addEventListener("click", langFn) }
  let langTop = docObj.getElementById("language-toggle")
  if !langTop.isUndefined { _ = langTop.addEventListener("click", langFn) }

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
}

_ = doc.addEventListener("DOMContentLoaded", readyClosure)

#endif
