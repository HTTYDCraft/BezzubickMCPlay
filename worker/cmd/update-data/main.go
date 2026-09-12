// UpdateData — ported from Sources/UpdateData/main.swift (Swift) to Go.
//
// Runs on linux (GitHub Actions, ubuntu-latest). Same env vars, same
// data.json / streams_history.json shapes.
//
// FIXes vs the Swift version:
//   - HTTP status codes are checked (Swift ignored them and silently
//     treated error pages as empty data).
//   - Twitch app token is fetched via POST (Swift used GET with query
//     params, which Twitch rejects).
//   - YouTube live detection keeps Swift's quota-saving approach
//     (videos.list liveBroadcastContent, 1 unit) with a search.list
//     fallback.
//   - Previously fetched youtubeVideos are kept when a run fails
//     (Swift overwrote them with an empty list).
//   - VK has a groups.getById fallback for member counts.
package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"time"
)

// ---------- Models (same JSON shapes as before) ----------

type YouTubeVideo struct {
	ID           string `json:"id"`
	Title        string `json:"title"`
	ThumbnailURL string `json:"thumbnailUrl"`
}

type TwitchLive struct {
	Type              string `json:"type"`
	ID                *string `json:"id,omitempty"`
	Title             *string `json:"title,omitempty"`
	TwitchChannelName *string `json:"twitchChannelName,omitempty"`
}

type LiveStream struct {
	Type              string      `json:"type"`
	ID                *string     `json:"id,omitempty"`
	Title             *string     `json:"title,omitempty"`
	YoutubeChannelID  *string     `json:"youtubeChannelId,omitempty"`
	TwitchChannelName *string     `json:"twitchChannelName,omitempty"`
	TwitchLive        *TwitchLive `json:"twitchLive,omitempty"`
}

type SiteData struct {
	FollowerCounts map[string]int `json:"followerCounts"`
	YoutubeVideos  []YouTubeVideo `json:"youtubeVideos"`
	LiveStream     LiveStream     `json:"liveStream"`
	LastUpdated    string         `json:"lastUpdated"`
	DebugInfo      map[string]string `json:"debugInfo"`
}

type HistoryEvent struct {
	Key      string  `json:"key"`
	Dt       string  `json:"dt"`
	Date     string  `json:"date"`
	Platform string  `json:"platform"`
	Title    string  `json:"title"`
	URL      string  `json:"url"`
	VideoID  *string `json:"videoId,omitempty"`
	StreamID *string `json:"streamId,omitempty"`
	Channel  *string `json:"channel,omitempty"`
}

type StreamHistory struct {
	Events []HistoryEvent `json:"events"`
}

// ---------- Env ----------

func env(key string) string { return os.Getenv(key) }

var (
	youtubeAPIKey    = env("YOUTUBE_API_KEY")
	twitchClientID   = env("TWITCH_CLIENT_ID")
	twitchSecret     = env("TWITCH_CLIENT_SECRET")
	youtubeChannelID = env("YOUR_YOUTUBE_CHANNEL_ID")
	twitchUsername   = env("YOUR_TWITCH_USERNAME")
	vkGroupID        = env("YOUR_VK_GROUP_ID")
	vkUserID         = env("YOUR_VK_USER_ID")
	vkGroupToken     = env("VK_GROUP_ACCESS_TOKEN")
	vkUserToken      = env("VK_USER_ACCESS_TOKEN")
	telegramBotToken = env("TELEGRAM_BOT_TOKEN")
	telegramChatID   = env("TELEGRAM_CHANNEL_CHAT_ID")
	instagramBizID   = env("INSTAGRAM_BUSINESS_ACCOUNT_ID")
	instagramToken   = env("INSTAGRAM_ACCESS_TOKEN")
	xBearerToken     = env("X_BEARER_TOKEN")
	xUserID          = env("YOUR_X_USER_ID")
	tikapiKey        = env("TIKAPI_IO_API_KEY")
	tiktokUsername   = env("YOUR_TIKTOK_USERNAME")
)

var httpClient = &http.Client{Timeout: 15 * time.Second}

// ---------- HTTP with retries ----------

func httpGetJSON(rawURL string, headers map[string]string, params map[string]string) (any, error) {
	u, err := url.Parse(rawURL)
	if err != nil {
		return nil, err
	}
	q := u.Query()
	for k, v := range params {
		q.Set(k, v)
	}
	u.RawQuery = q.Encode()

	var lastErr error
	for attempt := 1; attempt <= 3; attempt++ {
		req, _ := http.NewRequest(http.MethodGet, u.String(), nil)
		for k, v := range headers {
			req.Header.Set(k, v)
		}
		resp, err := httpClient.Do(req)
		if err != nil {
			lastErr = err
		} else {
			body, _ := io.ReadAll(resp.Body)
			resp.Body.Close()
			if resp.StatusCode == http.StatusTooManyRequests || resp.StatusCode >= 500 {
				lastErr = fmt.Errorf("HTTP %d", resp.StatusCode)
			} else if resp.StatusCode != http.StatusOK {
				return nil, fmt.Errorf("HTTP %d: %s", resp.StatusCode, truncate(string(body), 200))
			} else {
				var v any
				if err := json.Unmarshal(body, &v); err != nil {
					return nil, err
				}
				return v, nil
			}
		}
		if attempt < 3 {
			time.Sleep(time.Duration(attempt) * 1500 * time.Millisecond)
		}
	}
	return nil, lastErr
}

func truncate(s string, n int) string {
	if len(s) > n {
		return s[:n]
	}
	return s
}

func obj(v any) map[string]any {
	m, _ := v.(map[string]any)
	return m
}

func arr(m map[string]any, key string) []any {
	a, _ := m[key].([]any)
	return a
}

func str(m map[string]any, key string) string {
	s, _ := m[key].(string)
	return s
}

func num(m map[string]any, key string) (int, bool) {
	switch n := m[key].(type) {
	case float64:
		return int(n), true
	case int:
		return n, true
	}
	return 0, false
}

// ---------- YouTube ----------

func getYouTubeSubs() *int {
	if youtubeAPIKey == "" || youtubeChannelID == "" {
		return nil
	}
	v, err := httpGetJSON("https://www.googleapis.com/youtube/v3/channels", nil,
		map[string]string{"part": "statistics", "id": youtubeChannelID, "key": youtubeAPIKey})
	if err != nil {
		debug("youtube_subs_error", err)
		return nil
	}
	items := arr(obj(v), "items")
	if len(items) == 0 {
		return nil
	}
	if s := str(obj(obj(items[0])["statistics"]), "subscriberCount"); s != "" {
		var n int
		if _, err := fmt.Sscanf(s, "%d", &n); err == nil {
			return &n
		}
	}
	return nil
}

func getYouTubeVideos() []YouTubeVideo {
	if youtubeAPIKey == "" || youtubeChannelID == "" {
		return nil
	}
	v, err := httpGetJSON("https://www.googleapis.com/youtube/v3/channels", nil,
		map[string]string{"part": "contentDetails", "id": youtubeChannelID, "key": youtubeAPIKey})
	if err != nil {
		debug("youtube_videos_error", err)
		return nil
	}
	items := arr(obj(v), "items")
	if len(items) == 0 {
		return nil
	}
	uploads := str(obj(obj(obj(items[0])["contentDetails"])["relatedPlaylists"]), "uploads")
	if uploads == "" {
		return nil
	}
	pl, err := httpGetJSON("https://www.googleapis.com/youtube/v3/playlistItems", nil,
		map[string]string{"part": "snippet", "playlistId": uploads, "key": youtubeAPIKey, "maxResults": "20"})
	if err != nil {
		debug("youtube_videos_error", err)
		return nil
	}
	var out []YouTubeVideo
	seen := map[string]bool{}
	for _, it := range arr(obj(pl), "items") {
		sn := obj(obj(it)["snippet"])
		vid := str(obj(sn["resourceId"]), "videoId")
		if vid == "" || seen[vid] {
			continue
		}
		seen[vid] = true
		thumbs := obj(sn["thumbnails"])
		thumb := ""
		for _, k := range []string{"maxres", "standard", "high", "medium", "default"} {
			if u := str(obj(thumbs[k]), "url"); u != "" {
				thumb = u
				break
			}
		}
		out = append(out, YouTubeVideo{ID: vid, Title: str(sn, "title"), ThumbnailURL: thumb})
	}
	return out
}

// Quota-saving live check: videos.list costs 1 unit, search.list costs 100.
func getYouTubeLive(videos []YouTubeVideo) *LiveStream {
	if youtubeAPIKey == "" || youtubeChannelID == "" || len(videos) == 0 {
		return nil
	}
	ids := ""
	for i, v := range videos {
		if i > 0 {
			ids += ","
		}
		ids += v.ID
	}
	if v, err := httpGetJSON("https://www.googleapis.com/youtube/v3/videos", nil,
		map[string]string{"part": "snippet", "id": ids, "key": youtubeAPIKey}); err == nil {
		for _, it := range arr(obj(v), "items") {
			sn := obj(obj(it)["snippet"])
			if str(sn, "liveBroadcastContent") == "live" {
				id := str(obj(it), "id")
				title := str(sn, "title")
				ch := youtubeChannelID
				return &LiveStream{Type: "youtube", ID: &id, Title: &title, YoutubeChannelID: &ch}
			}
		}
	} else {
		debug("youtube_live_error", err)
		// Fallback to the expensive search endpoint.
		if s, err2 := httpGetJSON("https://www.googleapis.com/youtube/v3/search", nil,
			map[string]string{"part": "snippet", "channelId": youtubeChannelID,
				"eventType": "live", "type": "video", "key": youtubeAPIKey}); err2 == nil {
			if items := arr(obj(s), "items"); len(items) > 0 {
				first := obj(items[0])
				id := str(obj(first["id"]), "videoId")
				title := str(obj(first["snippet"]), "title")
				ch := youtubeChannelID
				if id != "" {
					return &LiveStream{Type: "youtube", ID: &id, Title: &title, YoutubeChannelID: &ch}
				}
			}
		} else {
			debug("youtube_live_search_error", err2)
		}
	}
	return nil
}

// ---------- Twitch ----------

func getTwitchToken() string {
	if twitchClientID == "" || twitchSecret == "" {
		return ""
	}
	// FIX vs Swift: token endpoint requires POST, not GET.
	form := url.Values{"client_id": {twitchClientID}, "client_secret": {twitchSecret}, "grant_type": {"client_credentials"}}
	var token string
	var lastErr error
	for attempt := 1; attempt <= 3; attempt++ {
		resp, err := httpClient.PostForm("https://id.twitch.tv/oauth2/token", form)
		if err != nil {
			lastErr = err
		} else {
			body, _ := io.ReadAll(resp.Body)
			resp.Body.Close()
			if resp.StatusCode != http.StatusOK {
				lastErr = fmt.Errorf("HTTP %d", resp.StatusCode)
			} else {
				var v map[string]any
				if err := json.Unmarshal(body, &v); err != nil {
					lastErr = err
				} else {
					token = str(v, "access_token")
					if token == "" {
						lastErr = fmt.Errorf("no access_token")
					} else {
						return token
					}
				}
			}
		}
		if attempt < 3 {
			time.Sleep(time.Duration(attempt) * 1500 * time.Millisecond)
		}
	}
	debug("twitch_token_error", lastErr)
	return ""
}

func twitchHeaders(token string) map[string]string {
	return map[string]string{"Client-ID": twitchClientID, "Authorization": "Bearer " + token}
}

func getTwitchUserID(token string) string {
	v, err := httpGetJSON("https://api.twitch.tv/helix/users", twitchHeaders(token),
		map[string]string{"login": twitchUsername})
	if err != nil {
		debug("twitch_user_error", err)
		return ""
	}
	if d := arr(obj(v), "data"); len(d) > 0 {
		return str(obj(d[0]), "id")
	}
	return ""
}

func getTwitchFollowers(token, userID string) *int {
	v, err := httpGetJSON("https://api.twitch.tv/helix/channels/followers", twitchHeaders(token),
		map[string]string{"broadcaster_id": userID})
	if err != nil {
		debug("twitch_followers_error", err)
		return nil
	}
	if n, ok := num(obj(v), "total"); ok {
		return &n
	}
	return nil
}

func getTwitchLive(token string) *LiveStream {
	if twitchUsername == "" || token == "" {
		return nil
	}
	v, err := httpGetJSON("https://api.twitch.tv/helix/streams", twitchHeaders(token),
		map[string]string{"user_login": twitchUsername})
	if err != nil {
		debug("twitch_live_error", err)
		return nil
	}
	if d := arr(obj(v), "data"); len(d) > 0 {
		st := obj(d[0])
		id := str(st, "id")
		title := str(st, "title")
		ch := twitchUsername
		return &LiveStream{Type: "twitch", ID: &id, Title: &title, TwitchChannelName: &ch}
	}
	return nil
}

// ---------- VK / Telegram / Instagram / X / TikTok ----------

const vkVer = "5.199"

func getVKGroupMembers() *int {
	if vkGroupID == "" || vkGroupToken == "" {
		return nil
	}
	if v, err := httpGetJSON("https://api.vk.com/method/groups.getMembers", nil,
		map[string]string{"group_id": vkGroupID, "access_token": vkGroupToken, "v": vkVer}); err == nil {
		if n, ok := num(obj(obj(v)["response"]), "count"); ok {
			return &n
		}
		if v2, err2 := httpGetJSON("https://api.vk.com/method/groups.getById", nil,
			map[string]string{"group_id": vkGroupID, "fields": "members_count", "access_token": vkGroupToken, "v": vkVer}); err2 == nil {
			if r := arr(obj(v2), "response"); len(r) > 0 {
				if n, ok := num(obj(r[0]), "members_count"); ok {
					return &n
				}
			}
		} else {
			debug("vk_group_error", err2)
		}
	} else {
		debug("vk_group_error", err)
	}
	return nil
}

func getVKUserFollowers() *int {
	if vkUserID == "" || vkUserToken == "" {
		return nil
	}
	if v, err := httpGetJSON("https://api.vk.com/method/users.getFollowers", nil,
		map[string]string{"user_id": vkUserID, "access_token": vkUserToken, "v": vkVer}); err == nil {
		if n, ok := num(obj(obj(v)["response"]), "count"); ok {
			return &n
		}
		if v2, err2 := httpGetJSON("https://api.vk.com/method/users.get", nil,
			map[string]string{"user_ids": vkUserID, "fields": "followers_count", "access_token": vkUserToken, "v": vkVer}); err2 == nil {
			if r := arr(obj(v2), "response"); len(r) > 0 {
				if n, ok := num(obj(r[0]), "followers_count"); ok {
					return &n
				}
			}
		} else {
			debug("vk_personal_error", err2)
		}
	} else {
		debug("vk_personal_error", err)
	}
	return nil
}

func getTelegramMembers() *int {
	if telegramBotToken == "" || telegramChatID == "" {
		return nil
	}
	v, err := httpGetJSON("https://api.telegram.org/bot"+telegramBotToken+"/getChatMemberCount", nil,
		map[string]string{"chat_id": telegramChatID})
	if err != nil {
		debug("telegram_error", err)
		return nil
	}
	m := obj(v)
	if ok, _ := m["ok"].(bool); ok {
		if n, ok := num(m, "result"); ok {
			return &n
		}
	}
	return nil
}

func getInstagramFollowers() *int {
	if instagramBizID == "" || instagramToken == "" {
		return nil
	}
	v, err := httpGetJSON("https://graph.facebook.com/v19.0/"+instagramBizID+"/insights", nil,
		map[string]string{"metric": "followers_count", "period": "day", "access_token": instagramToken})
	if err != nil {
		debug("instagram_error", err)
		return nil
	}
	if d := arr(obj(v), "data"); len(d) > 0 {
		if vals, ok := obj(d[0])["values"].([]any); ok && len(vals) > 0 {
			if n, ok := num(obj(vals[0]), "value"); ok {
				return &n
			}
		}
	}
	return nil
}

func getXFollowers() *int {
	if xUserID == "" || xBearerToken == "" {
		return nil
	}
	v, err := httpGetJSON("https://api.twitter.com/2/users/"+xUserID,
		map[string]string{"Authorization": "Bearer " + xBearerToken},
		map[string]string{"user.fields": "public_metrics"})
	if err != nil {
		debug("x_error", err)
		return nil
	}
	if n, ok := num(obj(obj(obj(v)["data"])["public_metrics"]), "followers_count"); ok {
		return &n
	}
	return nil
}

func getTikTokFollowers() *int {
	if tiktokUsername == "" || tikapiKey == "" {
		return nil
	}
	v, err := httpGetJSON("https://api.tikapi.io/profile/user/"+tiktokUsername,
		map[string]string{"x-api-key": tikapiKey, "Accept": "application/json"}, nil)
	if err != nil {
		debug("tiktok_error", err)
		return nil
	}
	m := obj(v)
	if stats := obj(obj(m["data"])["stats"]); stats != nil {
		if n, ok := num(stats, "followerCount"); ok {
			return &n
		}
	}
	return nil
}

// ---------- History ----------

func loadHistory(path string) StreamHistory {
	var h StreamHistory
	data, err := os.ReadFile(path)
	if err != nil {
		return h
	}
	_ = json.Unmarshal(data, &h)
	if h.Events == nil {
		h.Events = []HistoryEvent{}
	}
	return h
}

func saveHistory(path string, h StreamHistory) {
	data, _ := json.MarshalIndent(h, "", "  ")
	_ = os.WriteFile(path, data, 0o644)
}

func strVal(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}

func pushEvent(h *StreamHistory, platform, id, title, url string, channel *string) bool {
	key := platform + ":" + id
	for _, e := range h.Events {
		if e.Key == key {
			return false
		}
	}
	now := time.Now().UTC().Format(time.RFC3339)
	ev := HistoryEvent{Key: key, Dt: now, Date: now[:10], Platform: platform, Title: title, URL: url}
	if platform == "youtube" {
		ev.VideoID = &id
	} else {
		ev.StreamID = &id
	}
	if channel != nil {
		ev.Channel = channel
	}
	h.Events = append(h.Events, ev)
	if len(h.Events) > 2000 {
		h.Events = h.Events[len(h.Events)-2000:]
	}
	return true
}

// ---------- debug ----------

var debugInfo = map[string]string{}

func debug(key string, err error) {
	if err != nil {
		debugInfo[key] = err.Error()
		fmt.Printf("[ERR] %s: %v\n", key, err)
	}
}

// ---------- main ----------

func main() {
	dataPath := flag.String("data", "data.json", "path to data.json")
	historyPath := flag.String("history", "streams_history.json", "path to streams_history.json")
	flag.Parse()

	// Load previous data to keep values on per-API failures.
	var prev SiteData
	if raw, err := os.ReadFile(*dataPath); err == nil {
		_ = json.Unmarshal(raw, &prev)
	}
	counts := map[string]int{
		"youtube": 0, "telegram": 0, "instagram": 0, "x": 0,
		"twitch": 0, "tiktok": 0, "vk_group": 0, "vk_personal": 0,
	}
	for k, v := range prev.FollowerCounts {
		counts[k] = v
	}
	videos := prev.YoutubeVideos

	fmt.Println("--- YouTube ---")
	if n := getYouTubeSubs(); n != nil {
		counts["youtube"] = *n
	}
	if fresh := getYouTubeVideos(); len(fresh) > 0 {
		videos = fresh
	}
	ytLive := getYouTubeLive(videos)

	fmt.Println("--- Twitch ---")
	token := getTwitchToken()
	var twLive *LiveStream
	if token != "" && twitchUsername != "" {
		if uid := getTwitchUserID(token); uid != "" {
			if n := getTwitchFollowers(token, uid); n != nil {
				counts["twitch"] = *n
			}
		}
		twLive = getTwitchLive(token)
	}

	fmt.Println("--- VK ---")
	if n := getVKGroupMembers(); n != nil {
		counts["vk_group"] = *n
	}
	if n := getVKUserFollowers(); n != nil {
		counts["vk_personal"] = *n
	}

	fmt.Println("--- Telegram ---")
	if n := getTelegramMembers(); n != nil {
		counts["telegram"] = *n
	}

	fmt.Println("--- Instagram ---")
	if n := getInstagramFollowers(); n != nil {
		counts["instagram"] = *n
	} else if instagramBizID == "" || instagramToken == "" {
		debugInfo["instagram_setup_warning"] = "Missing Instagram credentials"
	}

	fmt.Println("--- X ---")
	if n := getXFollowers(); n != nil {
		counts["x"] = *n
	}

	fmt.Println("--- TikTok ---")
	if n := getTikTokFollowers(); n != nil {
		counts["tiktok"] = *n
	} else if tiktokUsername == "" || tikapiKey == "" {
		debugInfo["tiktok_setup_warning"] = "Missing TikTok credentials"
	}

	live := LiveStream{Type: "none"}
	if ytLive != nil {
		live = *ytLive
		if twLive != nil {
			live.TwitchLive = &TwitchLive{Type: "twitch", ID: twLive.ID, Title: twLive.Title, TwitchChannelName: twLive.TwitchChannelName}
		}
	} else if twLive != nil {
		live = *twLive
	}

	data := SiteData{
		FollowerCounts: counts,
		YoutubeVideos:  videos,
		LiveStream:     live,
		LastUpdated:    time.Now().UTC().Format(time.RFC3339),
		DebugInfo:      debugInfo,
	}
	if data.YoutubeVideos == nil {
		data.YoutubeVideos = []YouTubeVideo{}
	}

	history := loadHistory(*historyPath)
	if ytLive != nil && ytLive.ID != nil {
		pushEvent(&history, "youtube", *ytLive.ID, strVal(ytLive.Title),
			"https://www.youtube.com/watch?v="+*ytLive.ID, nil)
	}
	if twLive != nil && twLive.ID != nil {
		ch := twitchUsername
		pushEvent(&history, "twitch", *twLive.ID, strVal(twLive.Title),
			"https://www.twitch.tv/"+twitchUsername, &ch)
	}
	saveHistory(*historyPath, history)

	out, _ := json.MarshalIndent(data, "", "  ")
	var pretty bytes.Buffer
	_ = json.Indent(&pretty, out, "", "  ")
	_ = os.WriteFile(*dataPath, pretty.Bytes(), 0o644)

	fmt.Printf("\nData updated and saved to %s\n", *dataPath)
	dbg, _ := json.Marshal(debugInfo)
	fmt.Printf("Debug: %s\n", string(dbg))
}
