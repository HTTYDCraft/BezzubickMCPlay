# scripts/update_data.py — обновление данных соцсетей
# Улучшено: таймауты, бэкофф, корректный VK (groups.getMembers + resolveScreenName), подробные docstrings, безопасные фолбэки

import os
import json
import time
import requests
from datetime import datetime

# --- Secrets (оставляем имена как в репозитории) ---
YOUTUBE_API_KEY = os.environ.get('YOUTUBE_API_KEY')
TWITCH_CLIENT_ID = os.environ.get('TWITCH_CLIENT_ID')
TWITCH_CLIENT_SECRET = os.environ.get('TWITCH_CLIENT_SECRET')
YOUR_YOUTUBE_CHANNEL_ID = os.environ.get('YOUR_YOUTUBE_CHANNEL_ID')
YOUR_TWITCH_USERNAME = os.environ.get('YOUR_TWITCH_USERNAME')
YOUR_VK_GROUP_ID = os.environ.get('YOUR_VK_GROUP_ID')           # может быть числом или screen name
YOUR_VK_USER_ID = os.environ.get('YOUR_VK_USER_ID')             # может быть числом или screen name
VK_GROUP_ACCESS_TOKEN = os.environ.get('VK_GROUP_ACCESS_TOKEN') # token с правами на группы
VK_USER_ACCESS_TOKEN = os.environ.get('VK_USER_ACCESS_TOKEN')   # token пользователя
TELEGRAM_BOT_TOKEN = os.environ.get('TELEGRAM_BOT_TOKEN')
TELEGRAM_CHANNEL_CHAT_ID = os.environ.get('TELEGRAM_CHANNEL_CHAT_ID')
INSTAGRAM_BUSINESS_ACCOUNT_ID = os.environ.get('INSTAGRAM_BUSINESS_ACCOUNT_ID')
INSTAGRAM_ACCESS_TOKEN = os.environ.get('INSTAGRAM_ACCESS_TOKEN')
X_BEARER_TOKEN = os.environ.get('X_BEARER_TOKEN')
YOUR_X_USER_ID = os.environ.get('YOUR_X_USER_ID')
TIKAPI_IO_API_KEY = os.environ.get('TIKAPI_IO_API_KEY')
YOUR_TIKTOK_USERNAME = os.environ.get('YOUR_TIKTOK_USERNAME')

DATA_FILE_PATH = 'data.json'
STREAM_HISTORY_FILE = 'streams_history.json'

def load_stream_history():
    """Возвращает словарь { 'events': [...] }."""
    if os.path.exists(STREAM_HISTORY_FILE):
        try:
            with open(STREAM_HISTORY_FILE, 'r', encoding='utf-8') as f:
                h = json.load(f)
                if isinstance(h, dict) and isinstance(h.get('events'), list):
                    return h
        except Exception as e:
            print(f"[History] Failed to read {STREAM_HISTORY_FILE}: {e}")
    return {'events': []}

def save_stream_history(history):
    try:
        with open(STREAM_HISTORY_FILE, 'w', encoding='utf-8') as f:
            json.dump(history, f, ensure_ascii=False, indent=2)
    except Exception as e:
        print(f"[History] Failed to write {STREAM_HISTORY_FILE}: {e}")

def push_history_event(history, platform, id_value, title, url, extra=None):
    """
    Дедуп по ключу platform:id_value (для YouTube - videoId, Twitch - streamId).
    Сохраняем дату в UTC ISO.
    """
    now = datetime.utcnow().replace(microsecond=0).isoformat() + 'Z'
    key = f"{platform}:{id_value}"
    if any(ev.get('key') == key for ev in history['events']):
        return False
    ev = {
        'key': key,
        'dt': now,
        'date': now[:10],
        'platform': platform,
        'title': title or '',
        'url': url
    }
    if platform == 'youtube':
        ev['videoId'] = id_value
    else:
        ev['streamId'] = id_value
    if isinstance(extra, dict):
        ev.update(extra)
    history['events'].append(ev)
    # Обрезаем до последних 2000 событий
    if len(history['events']) > 2000:
        history['events'] = history['events'][-2000:]
    return True


VK_API = 'https://api.vk.com/method'
VK_VER = '5.199'

# --- Load current data to keep previous values on failures ---
data = {
    "followerCounts": {
        "youtube": 0, "telegram": 0, "instagram": 0, "x": 0, "twitch": 0, "tiktok": 0,
        "vk_group": 0, "vk_personal": 0
    },
    "youtubeVideos": [],
    "liveStream": {"type": "none"},
    "lastUpdated": datetime.now().isoformat(),
    "debugInfo": {}
}

if os.path.exists(DATA_FILE_PATH):
    try:
        with open(DATA_FILE_PATH, 'r', encoding='utf-8') as f:
            old = json.load(f)
            if isinstance(old.get('followerCounts'), dict):
                data['followerCounts'].update(old['followerCounts'])
            if isinstance(old.get('youtubeVideos'), list):
                data['youtubeVideos'] = old['youtubeVideos']
            if isinstance(old.get('liveStream'), dict):
                data['liveStream'] = old['liveStream']
    except Exception as e:
        print(f"[WARN] Could not load existing data.json: {e}")

data['debugInfo'] = {}  # clear for this run

def http_get_json(url, headers=None, params=None, timeout=15, retries=3, backoff=1.5):
    """
    Выполняет GET, возвращает JSON или выбрасывает исключение после ретраев.
    Ретраи на коды 429/5xx и VK ошибках 6/29. С прогрессивным бэкоффом.
    """
    for attempt in range(1, retries + 1):
        try:
            r = requests.get(url, headers=headers, params=params, timeout=timeout)
            if r.status_code in (429, 500, 502, 503, 504):
                raise requests.HTTPError(f"HTTP {r.status_code}")
            j = r.json()
            # VK specific error throttling
            if isinstance(j, dict) and 'error' in j:
                code = j['error'].get('error_code')
                if code in (6, 29):  # rate limit
                    raise requests.HTTPError(f"VK rate limit {code}: {j['error'].get('error_msg')}")
            return j
        except Exception as e:
            if attempt == retries:
                raise
            sleep = backoff ** attempt
            print(f"[Retry] {url} attempt {attempt}/{retries} failed: {e}. Sleeping {sleep:.1f}s")
            time.sleep(sleep)

# --- YouTube ---
def get_youtube_channel_stats(channel_id, api_key):
    if not channel_id or not api_key: return None
    url = "https://www.googleapis.com/youtube/v3/channels"
    params = {"part": "statistics", "id": channel_id, "key": api_key}
    try:
        j = http_get_json(url, params=params)
        items = j.get('items') or []
        if items:
            return int(items[0]['statistics']['subscriberCount'])
    except Exception as e:
        data['debugInfo']['youtube_subs_error'] = str(e)
    return None

def get_youtube_recent_videos(channel_id, api_key, max_results=20):
    if not channel_id or not api_key: return []
    try:
        j1 = http_get_json("https://www.googleapis.com/youtube/v3/channels",
                           params={"part": "contentDetails", "id": channel_id, "key": api_key})
        items = j1.get('items') or []
        if not items: return []
        uploads = items[0]['contentDetails']['relatedPlaylists']['uploads']
        j2 = http_get_json("https://www.googleapis.com/youtube/v3/playlistItems",
                           params={"part": "snippet", "playlistId": uploads, "key": api_key, "maxResults": max_results})
        out = []
        for it in j2.get('items', []):
            sn = it['snippet']
            vid = sn['resourceId']['videoId']
            title = sn['title']
            th = sn.get('thumbnails', {})
            thumb = th.get('maxres', {}).get('url') or th.get('standard', {}).get('url') or th.get('high', {}).get('url') or th.get('medium', {}).get('url') or th.get('default', {}).get('url')
            out.append({"id": vid, "title": title, "thumbnailUrl": thumb})
        return out
    except Exception as e:
        data['debugInfo']['youtube_videos_error'] = str(e)
        return []

def get_youtube_live_status(channel_id, api_key):
    if not channel_id or not api_key: return None
    try:
        j = http_get_json("https://www.googleapis.com/youtube/v3/search",
                          params={"part": "snippet", "channelId": channel_id, "eventType": "live", "type": "video", "key": api_key})
        items = j.get('items') or []
        if items:
            vid = items[0]['id']['videoId']
            title = items[0]['snippet']['title']
            return {"type": "youtube", "id": vid, "title": title, "youtubeChannelId": channel_id}
    except Exception as e:
        data['debugInfo']['youtube_live_error'] = str(e)
    return None

# --- Twitch ---
def get_twitch_access_token(client_id, client_secret):
    if not client_id or not client_secret: return None
    try:
        r = requests.post("https://id.twitch.tv/oauth2/token",
                          params={"client_id": client_id, "client_secret": client_secret, "grant_type": "client_credentials"},
                          timeout=15)
        r.raise_for_status()
        return r.json()['access_token']
    except Exception as e:
        data['debugInfo']['twitch_token_error'] = str(e)
        return None

def twitch_get(path, client_id, token, params=None):
    headers = {"Client-ID": client_id, "Authorization": f"Bearer {token}"}
    j = http_get_json(f"https://api.twitch.tv/helix/{path}", headers=headers, params=params)
    return j

def get_twitch_user_id(username, client_id, token):
    if not username or not client_id or not token: return None
    try:
        j = twitch_get("users", client_id, token, params={"login": username})
        d = j.get('data') or []
        if d:
            return d[0]['id']
    except Exception as e:
        data['debugInfo']['twitch_user_error'] = str(e)
    return None

def get_twitch_followers(user_id, client_id, token):
    if not user_id or not client_id or not token: return None
    try:
        j = twitch_get("channels/followers", client_id, token, params={"broadcaster_id": user_id})
        return j.get('total')
    except Exception as e:
        data['debugInfo']['twitch_followers_error'] = str(e)
    return None

def get_twitch_live_status(username, client_id, token):
    if not username or not client_id or not token: return None
    try:
        j = twitch_get("streams", client_id, token, params={"user_login": username})
        d = j.get('data') or []
        if d:
            st = d[0]
            return {"type": "twitch", "id": st['id'], "title": st['title'], "twitchChannelName": username}
    except Exception as e:
        data['debugInfo']['twitch_live_error'] = str(e)
    return None

# --- VK helpers ---
def vk_resolve_screen_name(name, token):
    """
    Возвращает dict: {"type": "user"|"group"|"page", "object_id": int} или None
    """
    if not name or not token:
        return None
    try:
        j = http_get_json(f"{VK_API}/utils.resolveScreenName", params={"screen_name": name, "access_token": token, "v": VK_VER})
        resp = j.get('response')
        return resp
    except Exception as e:
        data['debugInfo']['vk_resolve_error'] = str(e)
        return None

def get_vk_group_members(group_id_or_name, token):
    """
    Наиболее надёжно: groups.getMembers -> response.count
    group_id может быть числовым ID или коротким именем (без '-').
    """
    if not group_id_or_name or not token:
        data['debugInfo']['vk_group_error'] = "Missing group_id or token"
        return None
    try:
        j = http_get_json(f"{VK_API}/groups.getMembers",
                          params={"group_id": group_id_or_name, "access_token": token, "v": VK_VER})
        resp = j.get('response') or {}
        cnt = resp.get('count')
        if isinstance(cnt, int):
            return cnt
        # Fallback: groups.getById with fields=members_count
        j2 = http_get_json(f"{VK_API}/groups.getById",
                           params={"group_id": group_id_or_name, "fields": "members_count", "access_token": token, "v": VK_VER})
        resp2 = j2.get('response') or []
        if resp2 and 'members_count' in resp2[0]:
            return resp2[0]['members_count']
    except Exception as e:
        data['debugInfo']['vk_group_error'] = str(e)
    return None

def get_vk_user_followers(user_id_or_name, token):
    """
    Надёжнее через users.getFollowers -> response.count, с фолбэком на users.get fields=followers_count
    """
    if not user_id_or_name or not token:
        data['debugInfo']['vk_personal_error'] = "Missing user_id or token"
        return None
    try:
        # Если не число — можно резолвнуть
        uid = user_id_or_name
        if not str(user_id_or_name).isdigit():
            resolved = vk_resolve_screen_name(user_id_or_name, token)
            if resolved and resolved.get('type') == 'user':
                uid = resolved['object_id']

        j = http_get_json(f"{VK_API}/users.getFollowers",
                          params={"user_id": uid, "access_token": token, "v": VK_VER})
        resp = j.get('response') or {}
        cnt = resp.get('count')
        if isinstance(cnt, int):
            return cnt

        # fallback
        j2 = http_get_json(f"{VK_API}/users.get",
                           params={"user_ids": uid, "fields": "followers_count", "access_token": token, "v": VK_VER})
        resp2 = j2.get('response') or []
        if resp2 and 'followers_count' in resp2[0]:
            return resp2[0]['followers_count']
    except Exception as e:
        data['debugInfo']['vk_personal_error'] = str(e)
    return None

# --- Telegram ---
def get_telegram_channel_members(bot_token, chat_id):
    if not bot_token or not chat_id:
        data['debugInfo']['telegram_error'] = "Missing bot token or chat id"
        return None
    try:
        j = http_get_json(f"https://api.telegram.org/bot{bot_token}/getChatMemberCount",
                          params={"chat_id": chat_id})
        if j.get('ok') and 'result' in j:
            return j['result']
    except Exception as e:
        data['debugInfo']['telegram_error'] = str(e)
    return None

# --- Instagram ---
def get_instagram_followers(business_account_id, access_token):
    if not business_account_id or not access_token:
        data['debugInfo']['instagram_setup_warning'] = "Missing Instagram credentials"
        return None
    try:
        j = http_get_json(f"https://graph.facebook.com/v19.0/{business_account_id}/insights",
                          params={"metric": "followers_count", "period": "day", "access_token": access_token})
        if j.get('data') and j['data'][0].get('values'):
            return j['data'][0]['values'][0]['value']
    except Exception as e:
        data['debugInfo']['instagram_error'] = str(e)
    return None

# --- X (Twitter) ---
def get_x_followers(user_id, bearer):
    if not user_id or not bearer:
        data['debugInfo']['x_setup_warning'] = "Missing X credentials"
        return None
    try:
        j = http_get_json(f"https://api.twitter.com/2/users/{user_id}",
                          headers={"Authorization": f"Bearer {bearer}"},
                          params={"user.fields": "public_metrics"})
        d = j.get('data') or {}
        pm = d.get('public_metrics') or {}
        if 'followers_count' in pm:
            return pm['followers_count']
    except Exception as e:
        data['debugInfo']['x_error'] = str(e)
    return None

# --- TikTok (TikAPI.io) ---
def get_tiktok_followers(username, api_key):
    if not username or not api_key:
        data['debugInfo']['tiktok_setup_warning'] = "Missing TikTok credentials"
        return None
    try:
        j = http_get_json("https://api.tikapi.io/profile/user/" + username,
                          headers={"x-api-key": api_key, "Accept": "application/json"})
        if j.get('data') and j['data'].get('stats') and 'followerCount' in j['data']['stats']:
            return j['data']['stats']['followerCount']
        if j.get('user') and j['user'].get('stats') and 'followerCount' in j['user']['stats']:
            return j['user']['stats']['followerCount']
        data['debugInfo']['tiktok_error'] = "Unexpected TikAPI response"
    except Exception as e:
        data['debugInfo']['tiktok_error'] = str(e)
    return None

# --- Execute ---

print("\n--- YouTube ---")
yt_subs = get_youtube_channel_stats(YOUR_YOUTUBE_CHANNEL_ID, YOUTUBE_API_KEY)
if yt_subs is not None: data['followerCounts']['youtube'] = yt_subs
videos = get_youtube_recent_videos(YOUR_YOUTUBE_CHANNEL_ID, YOUTUBE_API_KEY)
data['youtubeVideos'] = videos
yt_live = get_youtube_live_status(YOUR_YOUTUBE_CHANNEL_ID, YOUTUBE_API_KEY)

print("\n--- Twitch ---")
tw_token = get_twitch_access_token(TWITCH_CLIENT_ID, TWITCH_CLIENT_SECRET)
tw_user_id = get_twitch_user_id(YOUR_TWITCH_USERNAME, TWITCH_CLIENT_ID, tw_token) if tw_token else None
if tw_user_id and tw_token:
    tw_followers = get_twitch_followers(tw_user_id, TWITCH_CLIENT_ID, tw_token)
    if tw_followers is not None: data['followerCounts']['twitch'] = tw_followers
tw_live = get_twitch_live_status(YOUR_TWITCH_USERNAME, TWITCH_CLIENT_ID, tw_token) if tw_token else None

# выбрать приоритет стрима
if yt_live:
    data['liveStream'] = yt_live
    if tw_live: data['liveStream']['twitchLive'] = tw_live
elif tw_live:
    data['liveStream'] = tw_live
else:
    data['liveStream'] = {"type": "none"}

print("\n--- VK ---")
# Группа: разрешаем передавать как screen name, так и numeric
if YOUR_VK_GROUP_ID and VK_GROUP_ACCESS_TOKEN:
    vk_group_count = get_vk_group_members(YOUR_VK_GROUP_ID, VK_GROUP_ACCESS_TOKEN)
    if vk_group_count is not None:
        data['followerCounts']['vk_group'] = vk_group_count
else:
    data['debugInfo']['vk_group_status'] = "Missing VK group ID or token"

# Пользователь: followers
if YOUR_VK_USER_ID and VK_USER_ACCESS_TOKEN:
    vk_user_followers = get_vk_user_followers(YOUR_VK_USER_ID, VK_USER_ACCESS_TOKEN)
    if vk_user_followers is not None:
        data['followerCounts']['vk_personal'] = vk_user_followers
else:
    data['debugInfo']['vk_personal_status'] = "Missing VK user ID or token"

print("\n--- Telegram ---")
tg = get_telegram_channel_members(TELEGRAM_BOT_TOKEN, TELEGRAM_CHANNEL_CHAT_ID)
if tg is not None: data['followerCounts']['telegram'] = tg

print("\n--- Instagram ---")
ig = get_instagram_followers(INSTAGRAM_BUSINESS_ACCOUNT_ID, INSTAGRAM_ACCESS_TOKEN)
if ig is not None: data['followerCounts']['instagram'] = ig

print("\n--- X (Twitter) ---")
xf = get_x_followers(YOUR_X_USER_ID, X_BEARER_TOKEN)
if xf is not None: data['followerCounts']['x'] = xf

print("\n--- TikTok ---")
tt = get_tiktok_followers(YOUR_TIKTOK_USERNAME, TIKAPI_IO_API_KEY)
if tt is not None: data['followerCounts']['tiktok'] = tt

# загрузим историю до записи
history = load_stream_history()

# ... после определения yt_live и tw_live (там же, где выставляешь data['liveStream'])
yt_added = False
tw_added = False

if yt_live:
    yt_url = f"https://www.youtube.com/watch?v={yt_live.get('id')}"
    yt_added = push_history_event(history, 'youtube', yt_live.get('id'), yt_live.get('title'), yt_url)

if tw_live:
    tw_url = f"https://www.twitch.tv/{YOUR_TWITCH_USERNAME}" if YOUR_TWITCH_USERNAME else "https://www.twitch.tv/"
    tw_added = push_history_event(history, 'twitch', tw_live.get('id'), tw_live.get('title'), tw_url, extra={'channel': YOUR_TWITCH_USERNAME})

# сохраняем историю в любом случае (даже если не добавилось)
save_stream_history(history)

# finalize
data['lastUpdated'] = datetime.now().isoformat()

with open(DATA_FILE_PATH, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"\nData updated and saved to {DATA_FILE_PATH}")
print("Debug Info:", json.dumps(data.get('debugInfo', {}), ensure_ascii=False, indent=2))