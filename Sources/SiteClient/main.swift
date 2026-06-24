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
  let body: JSValue = doc.body

  for cls in ["dark-theme", "light-theme", "glass-dark", "glass-light"] {
    _ = body.classList.remove(cls)
  }
  _ = body.classList.add(THEME_CLASSES[theme] ?? "dark-theme")
  stateTheme = theme
  isDark = theme.contains("dark")

  // Set html background for overscroll coverage
  let htmlBg: String
  if isDark { htmlBg = "#000000" }
  else if stateTheme.contains("glass") { htmlBg = "#ffffff" }
  else { htmlBg = "#f5f0ff" }
  _ = doc.documentElement.style.setProperty("background-color", htmlBg)

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
  let now = DateObj.new()
  calYear = Int(now.getFullYear!().number ?? 0)
  calMonth = Int(now.getMonth!().number ?? 0)

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

  let firstDow = DateObj.new(calYear, calMonth, 1)
  let startDow = ((Int(firstDow.getDay!().number ?? 0)) + 6) % 7
  let daysInMonth = Int(DateObj.new(calYear, calMonth + 1, 0).getDate!().number ?? 30)

  let today = DateObj.new()
  _ = today.setHours!(0, 0, 0, 0)
  let todayTime = today.getTime!().number ?? 0

  var html = ""
  for _ in 0..<startDow { html += "<div></div>" }
  for d in 1...daysInMonth {
    let dt = DateObj.new(calYear, calMonth, d)
    let dtTime = dt.getTime!().number ?? 0
    let isToday = dtTime == todayTime
    let isPast = dtTime < todayTime
    let dow = ((Int(dt.getDay!().number ?? 0)) + 6) % 7
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
  guard let respObj = fetchFn(url).object,
        let promise = JSPromise(respObj) else { return nil }
  return try? await promise.value
}

func jsJSON(_ resp: JSValue) async -> JSValue? {
  guard let promiseObj = resp.json().object,
        let promise = JSPromise(promiseObj) else { return nil }
  return try? await promise.value
}

func fetchData() async {
  let ts = Int(DateObj.new().getTime!().number ?? 0)

  guard let resp = await jsFetch("/BezzubickMCPlay/data.json?t=\(ts)"),
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

  let ts2 = Int(DateObj.new().getTime!().number ?? 0)
  guard let resp2 = await jsFetch("/BezzubickMCPlay/streams_history.json?t=\(ts2)"),
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
        let now = DateObj.new()
        let y = Int(now.getFullYear!().number ?? 0)
        let m = Int(now.getMonth!().number ?? 0) + 1
        let d = Int(now.getDate!().number ?? 0)
        let hh = Int(now.getHours!().number ?? 0)
        let mm = Int(now.getMinutes!().number ?? 0)
        let ss = Int(now.getSeconds!().number ?? 0)
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

// MARK: - WebGL Liquid Glass (exact reference copy)

var glCtx: JSValue = .undefined
var shaderProg: JSValue = .undefined
var uniformLocs: [String: JSValue] = [:]
var lgCanvas: JSValue = .undefined
var shouldRender = false
var rafId: JSValue = .undefined
var rafClosure: JSClosure?

// Smooth mouse
var smoothMouseX = 0.5
var smoothMouseY = 0.5
var targetMouseX = 0.5
var targetMouseY = 0.5
let SMOOTHING = 0.05
let PI = 3.14159265359

var bgTexture: JSValue = .undefined
var texWidth = 512.0
var texHeight = 512.0
var closureStore: [String: JSClosure] = [:]

let VERTEX_SHADER = """
#version 300 es
precision mediump float;
in vec3 aVertexPosition;
in vec2 aTextureCoord;
uniform mat4 uMVMatrix;
uniform mat4 uPMatrix;
uniform mat4 uTextureMatrix;
out vec2 vTextureCoord;
void main() {
  gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
  vTextureCoord = (uTextureMatrix * vec4(aTextureCoord, 0, 1)).xy;
}
"""

let FRAGMENT_SHADER = """
#version 300 es
precision mediump float;
in vec2 vTextureCoord;
uniform sampler2D uTexture;
uniform sampler2D uMaskTexture;
uniform vec2 uMousePos;
uniform vec2 uTMousePos;
uniform vec2 uResolution;
uniform vec2 uTextureResolution;
uniform float uRadius;
uniform float uDistort;
uniform float uDispersion;
uniform float uRotSpeed;
uniform float uShadowIntensity;
uniform float uShadowOffsetX;
uniform float uShadowOffsetY;
uniform float uShadowBlur;
uniform float uHighlightIntensity;
uniform float uHighlightSize;
uniform float uHighlightOffsetX;
uniform float uHighlightOffsetY;
out vec4 fragColor;
const float PI = 3.14159265359;
mat2 rot(float a) {
  float c = cos(a), s = sin(a);
  return mat2(c, -s, s, c);
}
vec2 getAspectCorrectedUV(vec2 uv, out bool isOutOfBounds) {
  float textureAspect = uTextureResolution.x / uTextureResolution.y;
  float screenAspect = uResolution.x / uResolution.y;
  vec2 scale = vec2(1.0);
  if (textureAspect > screenAspect) {
    scale.y = textureAspect / screenAspect;
  } else {
    scale.x = screenAspect / textureAspect;
  }
  vec2 correctedUV = (uv - 0.5) * scale + 0.5;
  isOutOfBounds = correctedUV.x < 0.0 || correctedUV.x > 1.0 || correctedUV.y < 0.0 || correctedUV.y > 1.0;
  return correctedUV;
}
float sdCircle(vec2 uv, float r) {
  return length(uv) - r;
}
float getDist(vec2 uv) {
  float sd = sdCircle(uv, uRadius);
  vec2 asp = vec2(uResolution.x / uResolution.y, 1.0);
  vec2 mp = uTMousePos * asp;
  float md = length(vTextureCoord * asp - mp);
  float fall = smoothstep(0.0, 0.8, md);
  float tweak = mix(0.02 / fall, 0.1 / fall, uDistort * sd);
  tweak = min(-tweak, 0.0);
  return sd - tweak;
}
float getShadow(vec2 uv, vec2 lightPos) {
  vec2 shadowOffset = vec2(uShadowOffsetX, uShadowOffsetY);
  vec2 shadowPos = uv - lightPos + shadowOffset;
  vec2 asp = vec2(uResolution.x / uResolution.y, 1.0);
  vec2 st = shadowPos * asp;
  st *= 1.0 / (0.4920 + 0.2);
  st = rot(-uRotSpeed * 2.0 * PI) * st;
  float shadowDist = getDist(st);
  float shadow = 1.0 - smoothstep(-uShadowBlur, uShadowBlur, shadowDist);
  float distanceFromLight = length(uv - lightPos);
  float attenuation = 1.0 - smoothstep(0.0, 1.0, distanceFromLight);
  return shadow * uShadowIntensity * attenuation;
}
float getHighlight(vec2 uv, vec2 lightPos) {
  vec2 highlightOffset = vec2(uHighlightOffsetX, uHighlightOffsetY);
  vec2 highlightPos = uv - lightPos + highlightOffset;
  vec2 asp = vec2(uResolution.x / uResolution.y, 1.0);
  vec2 st = highlightPos * asp;
  st *= 1.0 / (0.4920 + 0.2);
  st = rot(-uRotSpeed * 2.0 * PI) * st;
  float highlightRadius = uRadius * uHighlightSize;
  float highlightDist = sdCircle(st, highlightRadius);
  float highlight = 1.0 - smoothstep(-0.02, 0.02, highlightDist);
  float centerDist = length(st);
  float centerFalloff = 1.0 - smoothstep(0.0, highlightRadius * 0.8, centerDist);
  highlight *= centerFalloff;
  float distanceFromLight = length(uv - lightPos);
  float attenuation = 1.0 - smoothstep(0.0, 1.0, distanceFromLight);
  return highlight * uHighlightIntensity * attenuation;
}
vec4 refrakt(float sd, vec2 st, vec4 bg, vec2 originalUV) {
  vec2 offset = mix(vec2(0), normalize(st) / sd, length(st));
  float disp = uDispersion * 0.01;
  vec2 redOffset = offset * disp * 1.2;
  vec2 greenOffset = offset * disp * 1.0;
  vec2 blueOffset = offset * disp * 0.8;
  bool isOutOfBoundsR, isOutOfBoundsG, isOutOfBoundsB;
  vec2 redUV = originalUV + redOffset;
  vec2 greenUV = originalUV + greenOffset;
  vec2 blueUV = originalUV + blueOffset;
  vec2 aspectCorrectedRedUV = getAspectCorrectedUV(redUV, isOutOfBoundsR);
  vec2 aspectCorrectedGreenUV = getAspectCorrectedUV(greenUV, isOutOfBoundsG);
  vec2 aspectCorrectedBlueUV = getAspectCorrectedUV(blueUV, isOutOfBoundsB);
  float r, g, b;
  if (isOutOfBoundsR) { r = 0.8; } else { r = texture(uTexture, aspectCorrectedRedUV).r; }
  if (isOutOfBoundsG) { g = 0.8; } else { g = texture(uTexture, aspectCorrectedGreenUV).g; }
  if (isOutOfBoundsB) { b = 0.8; } else { b = texture(uTexture, aspectCorrectedBlueUV).b; }
  vec2 avgUV = originalUV + offset * disp;
  float shadow = getShadow(avgUV, uMousePos);
  vec4 refractedColor = vec4(r, g, b, 1.0);
  vec3 shadowColor = vec3(0.0, 0.0, 0.0);
  refractedColor.rgb = mix(refractedColor.rgb, shadowColor, shadow);
  float op = smoothstep(0.0, 0.0025, -sd);
  return mix(bg, refractedColor, op);
}
vec4 getEffect(vec2 st, vec4 bg, vec2 originalUV) {
  float eps = 0.0005;
  vec4 sum = vec4(0.0);
  sum += refrakt(getDist(st), st, bg, originalUV);
  sum += refrakt(getDist(st + vec2(eps, 0)), st + vec2(eps, 0), bg, originalUV);
  sum += refrakt(getDist(st - vec2(eps, 0)), st - vec2(eps, 0), bg, originalUV);
  sum += refrakt(getDist(st + vec2(0, eps)), st + vec2(0, eps), bg, originalUV);
  sum += refrakt(getDist(st - vec2(0, eps)), st - vec2(0, eps), bg, originalUV);
  return sum * 0.2;
}
void main() {
  vec2 uv = vTextureCoord;
  bool isOutOfBounds;
  vec2 aspectCorrectedUV = getAspectCorrectedUV(uv, isOutOfBounds);
  vec4 bg;
  if (isOutOfBounds) {
    bg = vec4(0.8, 0.8, 0.8, 1.0);
  } else {
    bg = texture(uTexture, aspectCorrectedUV);
  }
  float shadow = getShadow(uv, uMousePos);
  vec3 shadowColor = vec3(0.0, 0.0, 0.0);
  bg.rgb = mix(bg.rgb, shadowColor, shadow);
  vec2 st = uv - uMousePos;
  st *= vec2(uResolution.x / uResolution.y, 1.0);
  st *= 1.0 / (0.4920 + 0.2);
  st = rot(-uRotSpeed * 2.0 * PI) * st;
  vec4 color = getEffect(st, bg, uv);
  float highlight = getHighlight(uv, uMousePos);
  float exposure = 1.0 + highlight * 2.5;
  vec3 exposedColor = 1.0 - exp(-color.rgb * exposure);
  vec3 brightenedColor = color.rgb * (1.0 + highlight * 1.8);
  color.rgb = mix(exposedColor, brightenedColor, 0.3);
  vec3 warmTint = vec3(1.02, 1.01, 0.98);
  color.rgb *= mix(vec3(1.0), warmTint, highlight * 0.3);
  vec4 m = texture(uMaskTexture, uv);
  fragColor = color * (m.a * m.a);
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
  canvas.style.cssText = .string("position:fixed;top:0;left:0;width:100vw;height:100vh;pointer-events:none;z-index:-1;display:block;")
  let body: JSValue = docObj.body
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
  for name in ["uMVMatrix", "uPMatrix", "uTextureMatrix", "uTexture", "uMaskTexture",
               "uMousePos", "uTMousePos", "uResolution", "uTextureResolution",
               "uRadius", "uDistort", "uDispersion", "uRotSpeed",
               "uShadowIntensity", "uShadowOffsetX", "uShadowOffsetY", "uShadowBlur",
               "uHighlightIntensity", "uHighlightSize", "uHighlightOffsetX", "uHighlightOffsetY"] {
    uniformLocs[name] = glCtx.getUniformLocation(prog, name)
  }

  // Identity matrices
  let id = [1.0,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1]
  if let u = uniformLocs["uMVMatrix"] { _ = glCtx.uniformMatrix4fv(u, false, id.jsValue) }
  if let u = uniformLocs["uPMatrix"] { _ = glCtx.uniformMatrix4fv(u, false, id.jsValue) }
  if let u = uniformLocs["uTextureMatrix"] { _ = glCtx.uniformMatrix4fv(u, false, id.jsValue) }
  if let u = uniformLocs["uTexture"] { _ = glCtx.uniform1i(u, 0) }
  if let u = uniformLocs["uMaskTexture"] { _ = glCtx.uniform1i(u, 1) }

  // Geometry: vec3 pos + vec2 uv = 5 floats per vertex
  let buf = glCtx.createBuffer()
  if buf.isUndefined { return }
  _ = glCtx.bindBuffer(glCtx.ARRAY_BUFFER, buf)
  let vertData: [Double] = [-1,-1,0, 0,0,  1,-1,0, 1,0,  -1,1,0, 0,1,  1,1,0, 1,1]
  _ = glCtx.bufferData(glCtx.ARRAY_BUFFER, vertData.jsValue, glCtx.STATIC_DRAW)

  let posL = glCtx.getAttribLocation(prog, "aVertexPosition").number ?? 0
  let uvL = glCtx.getAttribLocation(prog, "aTextureCoord").number ?? 0
  _ = glCtx.enableVertexAttribArray(posL)
  _ = glCtx.vertexAttribPointer(posL, 3, glCtx.FLOAT, false, 20, 0)
  _ = glCtx.enableVertexAttribArray(uvL)
  _ = glCtx.vertexAttribPointer(uvL, 2, glCtx.FLOAT, false, 20, 12)

  // Create mask texture (white = fully opaque)
  let maskCanvas = docObj.createElement("canvas")
  _ = maskCanvas.setAttribute("width", "512")
  _ = maskCanvas.setAttribute("height", "512")
  let maskCtx = maskCanvas.getContext("2d")
  maskCtx.fillStyle = .string("#ffffff")
  _ = maskCtx.fillRect(0, 0, 512, 512)
  _ = glCtx.activeTexture(glCtx.TEXTURE1)
  let maskTex = glCtx.createTexture()
  _ = glCtx.bindTexture(glCtx.TEXTURE_2D, maskTex)
  _ = glCtx.pixelStorei(glCtx.UNPACK_FLIP_Y_WEBGL, 1)
  _ = glCtx.texImage2D(glCtx.TEXTURE_2D, 0, glCtx.RGBA, glCtx.RGBA, glCtx.UNSIGNED_BYTE, maskCanvas)
  _ = glCtx.texParameteri(glCtx.TEXTURE_2D, glCtx.TEXTURE_MIN_FILTER, glCtx.LINEAR)
  _ = glCtx.texParameteri(glCtx.TEXTURE_2D, glCtx.TEXTURE_MAG_FILTER, glCtx.LINEAR)
  _ = glCtx.texParameteri(glCtx.TEXTURE_2D, glCtx.TEXTURE_WRAP_S, glCtx.CLAMP_TO_EDGE)
  _ = glCtx.texParameteri(glCtx.TEXTURE_2D, glCtx.TEXTURE_WRAP_T, glCtx.CLAMP_TO_EDGE)

  // Create initial background texture from gradient (synchronous fallback)
  let bgCanvas = docObj.createElement("canvas")
  _ = bgCanvas.setAttribute("width", "512")
  _ = bgCanvas.setAttribute("height", "512")
  let bgCtx = bgCanvas.getContext("2d")
  let grad = bgCtx.createLinearGradient(0, 0, 512, 512)
  _ = grad.addColorStop(0, "#ff9a9e")
  _ = grad.addColorStop(1, "#fad0c4")
  bgCtx.fillStyle = grad
  _ = bgCtx.fillRect(0, 0, 512, 512)
  _ = glCtx.activeTexture(glCtx.TEXTURE0)
  let texture = glCtx.createTexture()
  bgTexture = texture
  _ = glCtx.bindTexture(glCtx.TEXTURE_2D, texture)
  _ = glCtx.pixelStorei(glCtx.UNPACK_FLIP_Y_WEBGL, 1)
  _ = glCtx.texImage2D(glCtx.TEXTURE_2D, 0, glCtx.RGBA, glCtx.RGBA, glCtx.UNSIGNED_BYTE, bgCanvas)
  _ = glCtx.texParameteri(glCtx.TEXTURE_2D, glCtx.TEXTURE_MIN_FILTER, glCtx.LINEAR)
  _ = glCtx.texParameteri(glCtx.TEXTURE_2D, glCtx.TEXTURE_MAG_FILTER, glCtx.LINEAR)
  _ = glCtx.texParameteri(glCtx.TEXTURE_2D, glCtx.TEXTURE_WRAP_S, glCtx.CLAMP_TO_EDGE)
  _ = glCtx.texParameteri(glCtx.TEXTURE_2D, glCtx.TEXTURE_WRAP_T, glCtx.CLAMP_TO_EDGE)

  // Start async load of real background image (replaces gradient when done)
  loadBackgroundImage()
}

func loadBackgroundImage() {
  let img = JSObject.global.Image.new()
  img.crossOrigin = "anonymous"

  let onload = JSClosure { _ in
    if glCtx.isUndefined { return .undefined }
    _ = glCtx.activeTexture(glCtx.TEXTURE0)
    _ = glCtx.bindTexture(glCtx.TEXTURE_2D, bgTexture)
    _ = glCtx.texImage2D(glCtx.TEXTURE_2D, 0, glCtx.RGBA, glCtx.RGBA, glCtx.UNSIGNED_BYTE, img)
    texWidth = img.width.number ?? 512
    texHeight = img.height.number ?? 512
    closureStore["bgOnload"] = nil
    closureStore["bgOnerror"] = nil
    return .undefined
  }
  let onerror = JSClosure { _ in
    console.warn("[LiquidGlass] Failed to load background image, using gradient")
    closureStore["bgOnload"] = nil
    closureStore["bgOnerror"] = nil
    return .undefined
  }

  closureStore["bgOnload"] = onload
  closureStore["bgOnerror"] = onerror
  img.onload = onload
  img.onerror = onerror
  img.src = .string("https://plus.unsplash.com/premium_photo-1677094766116-aa0f8742d36b?q=80&w=3087&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D")
}

func renderFrame() {
  if glCtx.isUndefined || shaderProg.isUndefined { return }
  let dpr = win.devicePixelRatio.number ?? 1.0
  let ww = win.innerWidth.number ?? 1
  let wh = win.innerHeight.number ?? 1

  if !lgCanvas.isUndefined {
    lgCanvas.width = .number(ww * dpr)
    lgCanvas.height = .number(wh * dpr)
  }

  _ = glCtx.viewport(0, 0, ww * dpr, wh * dpr)
  _ = glCtx.clearColor(0, 0, 0, 0)
  _ = glCtx.clear(glCtx.COLOR_BUFFER_BIT)

  // Smooth mouse
  smoothMouseX += (targetMouseX - smoothMouseX) * SMOOTHING
  smoothMouseY += (targetMouseY - smoothMouseY) * SMOOTHING

  // Set uniforms
  if let u = uniformLocs["uResolution"] { _ = glCtx.uniform2f(u, ww * dpr, wh * dpr) }
  if let u = uniformLocs["uTextureResolution"] { _ = glCtx.uniform2f(u, texWidth, texHeight) }
  if let u = uniformLocs["uMousePos"] { _ = glCtx.uniform2f(u, smoothMouseX, smoothMouseY) }
  if let u = uniformLocs["uTMousePos"] { _ = glCtx.uniform2f(u, targetMouseX, targetMouseY) }
  if let u = uniformLocs["uRadius"] { _ = glCtx.uniform1f(u, 0.3) }
  if let u = uniformLocs["uDistort"] { _ = glCtx.uniform1f(u, 2.3) }
  if let u = uniformLocs["uDispersion"] { _ = glCtx.uniform1f(u, 0.7) }
  if let u = uniformLocs["uRotSpeed"] { _ = glCtx.uniform1f(u, 1.0) }
  if let u = uniformLocs["uShadowIntensity"] { _ = glCtx.uniform1f(u, 0.3) }
  if let u = uniformLocs["uShadowOffsetX"] { _ = glCtx.uniform1f(u, 0.01) }
  if let u = uniformLocs["uShadowOffsetY"] { _ = glCtx.uniform1f(u, 0.08) }
  if let u = uniformLocs["uShadowBlur"] { _ = glCtx.uniform1f(u, 0.4) }
  if let u = uniformLocs["uHighlightIntensity"] { _ = glCtx.uniform1f(u, 0.4) }
  if let u = uniformLocs["uHighlightSize"] { _ = glCtx.uniform1f(u, 1.25) }
  if let u = uniformLocs["uHighlightOffsetX"] { _ = glCtx.uniform1f(u, 0.01) }
  if let u = uniformLocs["uHighlightOffsetY"] { _ = glCtx.uniform1f(u, 0.03) }

  _ = glCtx.drawArrays(glCtx.TRIANGLE_STRIP, 0, 4)
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
    targetMouseX = (e.clientX.number ?? 0) / (win.innerWidth.number ?? 1)
    targetMouseY = 1.0 - (e.clientY.number ?? 0) / (win.innerHeight.number ?? 1)
    return .undefined
  }
  smoothMouseX = targetMouseX
  smoothMouseY = targetMouseY
  _ = win.addEventListener("mousemove", fn)
  _ = win.addEventListener("touchmove", fn)
}

func observeGlassState() {
  let body: JSValue = doc.body
  let ObsCtor = JSObject.global.MutationObserver.object!
  let cb = JSClosure { _ in
    let isGlass = (body.classList.contains("glass-dark").boolean ?? false) || (body.classList.contains("glass-light").boolean ?? false)
    if isGlass { startRendering() } else { stopRendering() }
    return .undefined
  }
  let observer = ObsCtor.new(cb)
  let config = JSObject()
  config["attributes"] = .boolean(true)
  config["attributeFilter"] = ["class"].jsValue
  _ = observer.observe!(body, config)
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
  observeGlassState()

  Task { await fetchData() }

  return .undefined
}

_ = doc.addEventListener("DOMContentLoaded", readyClosure)

#endif
