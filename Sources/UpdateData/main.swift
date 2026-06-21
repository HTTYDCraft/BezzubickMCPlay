import Foundation

// MARK: - Data Models

struct SiteData: Codable {
    var followerCounts: [String: Int]
    var youtubeVideos: [YouTubeVideo]
    var liveStream: LiveStream
    var lastUpdated: String
    var debugInfo: [String: String]
}

struct YouTubeVideo: Codable {
    var id: String
    var title: String
    var thumbnailUrl: String
}

struct LiveStream: Codable {
    var type: String
    var id: String?
    var title: String?
    var youtubeChannelId: String?
    var twitchChannelName: String?
    var twitchLive: TwitchLive?
}

struct TwitchLive: Codable {
    var type: String
    var id: String?
    var title: String?
    var twitchChannelName: String?
}

struct StreamHistory: Codable {
    var events: [HistoryEvent]
}

struct HistoryEvent: Codable {
    var key: String
    var dt: String
    var date: String
    var platform: String
    var title: String
    var url: String
    var videoId: String?
    var streamId: String?
    var channel: String?
}

// MARK: - Environment

func env(_ key: String) -> String? {
    ProcessInfo.processInfo.environment[key].flatMap { $0.isEmpty ? nil : $0 }
}

let YOUTUBE_API_KEY = env("YOUTUBE_API_KEY")
let TWITCH_CLIENT_ID = env("TWITCH_CLIENT_ID")
let TWITCH_CLIENT_SECRET = env("TWITCH_CLIENT_SECRET")
let YOUTUBE_CHANNEL_ID = env("YOUR_YOUTUBE_CHANNEL_ID")
let TWITCH_USERNAME = env("YOUR_TWITCH_USERNAME")
let VK_GROUP_ID = env("YOUR_VK_GROUP_ID")
let VK_USER_ID = env("YOUR_VK_USER_ID")
let VK_GROUP_TOKEN = env("VK_GROUP_ACCESS_TOKEN")
let VK_USER_TOKEN = env("VK_USER_ACCESS_TOKEN")
let TELEGRAM_BOT_TOKEN = env("TELEGRAM_BOT_TOKEN")
let TELEGRAM_CHAT_ID = env("TELEGRAM_CHANNEL_CHAT_ID")
let INSTAGRAM_BUSINESS_ID = env("INSTAGRAM_BUSINESS_ACCOUNT_ID")
let INSTAGRAM_TOKEN = env("INSTAGRAM_ACCESS_TOKEN")
let X_BEARER_TOKEN = env("X_BEARER_TOKEN")
let X_USER_ID = env("YOUR_X_USER_ID")
let TIKAPI_KEY = env("TIKAPI_IO_API_KEY")
let TIKTOK_USERNAME = env("YOUR_TIKTOK_USERNAME")

let dataFilePath = "data.json"
let historyFilePath = "streams_history.json"

// MARK: - HTTP

func httpGet(url: String, headers: [String: String] = [:], params: [String: String] = [:], retries: Int = 3) -> Data? {
    var components = URLComponents(string: url)!
    if !params.isEmpty {
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
    }
    var request = URLRequest(url: components.url!)
    request.timeoutInterval = 15
    for (k, v) in headers { request.setValue(v, forHTTPHeaderField: k) }

    for attempt in 1...retries {
        let semaphore = DispatchSemaphore(value: 0)
        var resultData: Data?
        URLSession.shared.dataTask(with: request) { data, response, error in
            resultData = data
            semaphore.signal()
        }.resume()
        semaphore.wait()
        if let data = resultData { return data }
        if attempt < retries { Thread.sleep(forTimeInterval: Double(attempt) * 1.5) }
    }
    return nil
}

func httpGetJSONObject(url: String, headers: [String: String] = [:], params: [String: String] = [:]) -> Any? {
    guard let data = httpGet(url: url, headers: headers, params: params) else { return nil }
    return try? JSONSerialization.jsonObject(with: data)
}

func httpGetJSONDecodable<T: Decodable>(url: String, headers: [String: String] = [:], params: [String: String] = [:]) -> T? {
    guard let data = httpGet(url: url, headers: headers, params: params) else { return nil }
    return try? JSONDecoder().decode(T.self, from: data)
}

func dictValue(_ obj: Any?, _ key: String) -> Any? {
    (obj as? [String: Any])?[key]
}

func dictArray(_ obj: Any?, _ key: String) -> [[String: Any]]? {
    (obj as? [String: Any])?[key] as? [[String: Any]]
}

func dictString(_ obj: Any?, _ key: String) -> String? {
    (obj as? [String: Any])?[key] as? String
}

func dictInt(_ obj: Any?, _ key: String) -> Int? {
    (obj as? [String: Any])?[key] as? Int
}

// MARK: - YouTube

func getYouTubeStats() -> (subs: Int?, videos: [YouTubeVideo], live: LiveStream?) {
    guard let key = YOUTUBE_API_KEY, let channelId = YOUTUBE_CHANNEL_ID else {
        return (nil, [], nil)
    }
    var subs: Int?
    var videos: [YouTubeVideo] = []
    var live: LiveStream?

    // Subscribers
    if let resp = httpGetJSONObject(url: "https://www.googleapis.com/youtube/v3/channels",
                                    params: ["part": "statistics", "id": channelId, "key": key]),
       let items = dictArray(resp, "items"),
       let stats = dictValue(items.first, "statistics"),
       let count = dictString(stats, "subscriberCount") {
        subs = Int(count)
    }

    // Recent videos
    if let resp = httpGetJSONObject(url: "https://www.googleapis.com/youtube/v3/channels",
                                    params: ["part": "contentDetails", "id": channelId, "key": key]),
       let items = dictArray(resp, "items"),
       let details = dictValue(items.first, "contentDetails"),
       let related = details as? [String: Any],
       let uploadsDict = related["relatedPlaylists"] as? [String: String],
       let uploadsPlaylist = uploadsDict["uploads"],
       let plResp = httpGetJSONObject(url: "https://www.googleapis.com/youtube/v3/playlistItems",
                                      params: ["part": "snippet", "playlistId": uploadsPlaylist, "key": key, "maxResults": "20"]),
       let plItems = dictArray(plResp, "items") {
        for item in plItems {
            guard let sn = item["snippet"] as? [String: Any],
                  let resId = sn["resourceId"] as? [String: Any],
                  let vid = resId["videoId"] as? String else { continue }
            let title = sn["title"] as? String ?? ""
            let thumbs = sn["thumbnails"] as? [String: Any] ?? [:]
            let thumbKeys = ["maxres", "standard", "high", "medium", "default"]
            var thumbUrl = ""
            for tk in thumbKeys {
                if let t = thumbs[tk] as? [String: Any], let u = t["url"] as? String { thumbUrl = u; break }
            }
            videos.append(YouTubeVideo(id: vid, title: title, thumbnailUrl: thumbUrl))
        }
    }

    // Live status
    if let resp = httpGetJSONObject(url: "https://www.googleapis.com/youtube/v3/search",
                                    params: ["part": "snippet", "channelId": channelId, "eventType": "live", "type": "video", "key": key]),
       let items = dictArray(resp, "items"),
       let first = items.first,
       let idDict = first["id"] as? [String: Any],
       let vid = idDict["videoId"] as? String,
       let sn = first["snippet"] as? [String: Any],
       let title = sn["title"] as? String {
        live = LiveStream(type: "youtube", id: vid, title: title, youtubeChannelId: channelId)
    }

    return (subs, videos, live)
}

// MARK: - Twitch

func getTwitchAccessToken() -> String? {
    guard let id = TWITCH_CLIENT_ID, let secret = TWITCH_CLIENT_SECRET else { return nil }
    let url = "https://id.twitch.tv/oauth2/token?client_id=\(id)&client_secret=\(secret)&grant_type=client_credentials"
    guard let data = httpGet(url: url),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let token = json["access_token"] as? String else { return nil }
    return token
}

func getTwitchData() -> (followers: Int?, live: LiveStream?) {
    guard let username = TWITCH_USERNAME, let clientId = TWITCH_CLIENT_ID,
          let token = getTwitchAccessToken() else { return (nil, nil) }
    let headers = ["Client-ID": clientId, "Authorization": "Bearer \(token)"]
    var followers: Int?
    var live: LiveStream?

    // User ID + followers
    if let resp = httpGetJSONObject(url: "https://api.twitch.tv/helix/users",
                                    headers: headers, params: ["login": username]),
       let data = dictArray(resp, "data"),
       let userId = data.first?["id"] as? String,
       let fResp = httpGetJSONObject(url: "https://api.twitch.tv/helix/channels/followers",
                                     headers: headers, params: ["broadcaster_id": userId]) {
        followers = dictInt(fResp, "total")
    }

    // Live status
    if let resp = httpGetJSONObject(url: "https://api.twitch.tv/helix/streams",
                                    headers: headers, params: ["user_login": username]),
       let data = dictArray(resp, "data"),
       let stream = data.first {
        live = LiveStream(type: "twitch", id: stream["id"] as? String,
                          title: stream["title"] as? String, twitchChannelName: username)
    }

    return (followers, live)
}

// MARK: - VK

func getVKGroupMembers() -> Int? {
    guard let groupId = VK_GROUP_ID, let token = VK_GROUP_TOKEN else { return nil }
    if let resp = httpGetJSONObject(url: "https://api.vk.com/method/groups.getMembers",
                                    params: ["group_id": groupId, "access_token": token, "v": "5.199"]),
       let response = dictValue(resp, "response") as? [String: Any],
       let count = response["count"] as? Int {
        return count
    }
    return nil
}

func getVKUserFollowers() -> Int? {
    guard let userId = VK_USER_ID, let token = VK_USER_TOKEN else { return nil }
    if let resp = httpGetJSONObject(url: "https://api.vk.com/method/users.getFollowers",
                                    params: ["user_id": userId, "access_token": token, "v": "5.199"]),
       let response = dictValue(resp, "response") as? [String: Any],
       let count = response["count"] as? Int {
        return count
    }
    return nil
}

// MARK: - Telegram

func getTelegramMembers() -> Int? {
    guard let token = TELEGRAM_BOT_TOKEN, let chatId = TELEGRAM_CHAT_ID else { return nil }
    if let resp = httpGetJSONObject(url: "https://api.telegram.org/bot\(token)/getChatMemberCount",
                                    params: ["chat_id": chatId]),
       (dictValue(resp, "ok") as? Bool) == true,
       let result = dictValue(resp, "result") as? Int {
        return result
    }
    return nil
}

// MARK: - Instagram

func getInstagramFollowers() -> Int? {
    guard let businessId = INSTAGRAM_BUSINESS_ID, let token = INSTAGRAM_TOKEN else { return nil }
    if let resp = httpGetJSONObject(url: "https://graph.facebook.com/v19.0/\(businessId)/insights",
                                    params: ["metric": "followers_count", "period": "day", "access_token": token]),
       let data = dictArray(resp, "data"),
       let first = data.first,
       let values = first["values"] as? [[String: Any]],
       let value = values.first?["value"] as? Int {
        return value
    }
    return nil
}

// MARK: - X (Twitter)

func getXFollowers() -> Int? {
    guard let userId = X_USER_ID, let bearer = X_BEARER_TOKEN else { return nil }
    if let resp = httpGetJSONObject(url: "https://api.twitter.com/2/users/\(userId)",
                                    headers: ["Authorization": "Bearer \(bearer)"],
                                    params: ["user.fields": "public_metrics"]),
       let data = dictValue(resp, "data") as? [String: Any],
       let metrics = data["public_metrics"] as? [String: Any],
       let count = metrics["followers_count"] as? Int {
        return count
    }
    return nil
}

// MARK: - TikTok

func getTikTokFollowers() -> Int? {
    guard let username = TIKTOK_USERNAME, let apiKey = TIKAPI_KEY else { return nil }
    if let resp = httpGetJSONObject(url: "https://api.tikapi.io/profile/user/\(username)",
                                    headers: ["x-api-key": apiKey, "Accept": "application/json"]),
       let data = dictValue(resp, "data") as? [String: Any],
       let stats = data["stats"] as? [String: Any],
       let count = stats["followerCount"] as? Int {
        return count
    }
    return nil
}

// MARK: - History

func loadHistory() -> StreamHistory {
    let url = URL(fileURLWithPath: historyFilePath)
    guard let data = try? Data(contentsOf: url),
          let history = try? JSONDecoder().decode(StreamHistory.self, from: data) else {
        return StreamHistory(events: [])
    }
    return history
}

func saveHistory(_ history: StreamHistory) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    guard let data = try? encoder.encode(history) else { return }
    try? data.write(to: URL(fileURLWithPath: historyFilePath))
}

func pushEvent(_ history: inout StreamHistory, platform: String, id: String, title: String, url: String, channel: String? = nil) -> Bool {
    let key = "\(platform):\(id)"
    if history.events.contains(where: { $0.key == key }) { return false }
    let now = ISO8601DateFormatter().string(from: Date())
    let dateStr = String(now.prefix(10))
    var event = HistoryEvent(key: key, dt: now, date: dateStr, platform: platform, title: title, url: url)
    if platform == "youtube" { event.videoId = id }
    else { event.streamId = id }
    if let ch = channel { event.channel = ch }
    history.events.append(event)
    if history.events.count > 2000 { history.events = Array(history.events.suffix(2000)) }
    return true
}

// MARK: - Main

print("\n--- YouTube ---")
let (ytSubs, ytVideos, ytLive) = getYouTubeStats()

print("\n--- Twitch ---")
let (twFollowers, twLive) = getTwitchData()

print("\n--- VK ---")
let vkGroup = getVKGroupMembers()
let vkUser = getVKUserFollowers()

print("\n--- Telegram ---")
let tgMembers = getTelegramMembers()

print("\n--- Instagram ---")
let igFollowers = getInstagramFollowers()

print("\n--- X ---")
let xFollowers = getXFollowers()

print("\n--- TikTok ---")
let ttFollowers = getTikTokFollowers()

// Merge live streams
var liveStream = LiveStream(type: "none")
if let ytLive = ytLive {
    liveStream = ytLive
    if let twLive = twLive { liveStream.twitchLive = TwitchLive(type: "twitch", id: twLive.id, title: twLive.title, twitchChannelName: twLive.twitchChannelName) }
} else if let twLive = twLive {
    liveStream = twLive
}

var debugInfo: [String: String] = [:]
if igFollowers == nil { debugInfo["instagram_setup_warning"] = "Missing Instagram credentials" }
if ttFollowers == nil { debugInfo["tiktok_setup_warning"] = "Missing TikTok credentials" }

// Build data
var data = SiteData(
    followerCounts: [
        "youtube": ytSubs ?? 0,
        "telegram": tgMembers ?? 0,
        "instagram": igFollowers ?? 0,
        "x": xFollowers ?? 0,
        "twitch": twFollowers ?? 0,
        "tiktok": ttFollowers ?? 0,
        "vk_group": vkGroup ?? 0,
        "vk_personal": vkUser ?? 0
    ],
    youtubeVideos: ytVideos,
    liveStream: liveStream,
    lastUpdated: ISO8601DateFormatter().string(from: Date()),
    debugInfo: debugInfo
)

// Load existing data to keep previous values on failure
if let existingData = try? Data(contentsOf: URL(fileURLWithPath: dataFilePath)),
   let existing = try? JSONDecoder().decode(SiteData.self, from: existingData) {
    for (key, value) in existing.followerCounts {
        if data.followerCounts[key] == 0 { data.followerCounts[key] = value }
    }
}

// Save history
var history = loadHistory()
if let ytLive = ytLive, let vid = ytLive.id {
    _ = pushEvent(&history, platform: "youtube", id: vid, title: ytLive.title ?? "", url: "https://www.youtube.com/watch?v=\(vid)")
}
if let twLive = twLive, let streamId = twLive.id {
    _ = pushEvent(&history, platform: "twitch", id: streamId, title: twLive.title ?? "", url: "https://www.twitch.tv/\(TWITCH_USERNAME ?? "")", channel: TWITCH_USERNAME)
}
saveHistory(history)

// Write data.json
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
if let jsonData = try? encoder.encode(data) {
    try? jsonData.write(to: URL(fileURLWithPath: dataFilePath))
}

print("\nData updated and saved to \(dataFilePath)")
print("Debug: \(debugInfo)")
