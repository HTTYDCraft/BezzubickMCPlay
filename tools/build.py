#!/usr/bin/env python3
"""Static site builder (stdlib only, runs on any Linux).

Reads (source of truth, convenient MD/YML configs — DO NOT replace):
  Content/about-intro.md, Content/about-outro.md, Content/timeline/*.md
  Config/links.yml, Config/site.yml

Writes:
  dist/index.html          — main page (content baked in, RU+EN via data-lang)
  dist/links/index.html    — links page shell
  dist/assets/links.json   — links config for runtime JS (generated from links.yml)
  + copies: assets/, css/, js/, data.json, streams_history.json,
            manifest.webmanifest, sw.js

Usage:  python3 tools/build.py [--base /BezzubickMCPlay]
"""

import html
import json
import datetime
import os
import re
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = ""
for a in sys.argv[1:]:
    if a == "--base" or a.startswith("--base="):
        BASE = a.split("=", 1)[1] if "=" in a else sys.argv[sys.argv.index(a) + 1]


def read_file(path):
    with open(os.path.join(ROOT, path), encoding="utf-8") as f:
        return f.read()


def parse_frontmatter(raw):
    lines = raw.split("\n")
    if not lines or lines[0].strip() != "---":
        return {}, raw
    try:
        end = next(i for i, l in enumerate(lines[1:], 1) if l.strip() == "---")
    except StopIteration:
        return {}, raw
    meta = {}
    for line in lines[1:end]:
        if ":" in line:
            k, v = line.split(":", 1)
            meta[k.strip()] = v.strip().strip('"').strip("'")
    return meta, "\n".join(lines[end + 1:])


def split_lang(body):
    ru, en, cur = [], [], "ru"
    for line in body.split("\n"):
        t = line.strip()
        if t == "<!-- lang:ru -->":
            cur = "ru"
            continue
        if t == "<!-- lang:en -->":
            cur = "en"
            continue
        (ru if cur == "ru" else en).append(line)
    return "\n".join(ru).strip(), "\n".join(en).strip()


def md_inline(s):
    s = html.escape(s)
    s = re.sub(r"\[([^\]]+)\]\(([^)]+)\)",
               r'<a href="\2" target="_blank" rel="noopener">\1</a>', s)
    s = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"(?<![\w\*])\*([^*]+)\*(?![\w\*])", r"<em>\1</em>", s)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    return s


def md2html(md):
    out, in_list = [], False
    for line in md.split("\n"):
        t = line.strip()
        if not t:
            if in_list:
                out.append("</ul>")
                in_list = False
            continue
        for prefix, tag in (("#### ", "h4"), ("### ", "h3"),
                            ("## ", "h2"), ("# ", "h1")):
            if t.startswith(prefix):
                if in_list:
                    out.append("</ul>")
                    in_list = False
                out.append(f"<{tag}>{md_inline(t[len(prefix):])}</{tag}>")
                break
        else:
            if t.startswith("- "):
                if not in_list:
                    out.append("<ul>")
                    in_list = True
                out.append(f"<li>{md_inline(t[2:])}</li>")
            else:
                if in_list:
                    out.append("</ul>")
                    in_list = False
                out.append(f"<p>{md_inline(t)}</p>")
    if in_list:
        out.append("</ul>")
    return "\n".join(out)


def read_bilingual(path):
    raw = read_file(path)
    _, body = parse_frontmatter(raw)
    ru, en = split_lang(body)
    return ru, en


def read_timeline():
    d = os.path.join(ROOT, "Content", "timeline")
    entries = []
    for fn in sorted(os.listdir(d)):
        if not fn.endswith(".md"):
            continue
        raw = read_file(f"Content/timeline/{fn}")
        meta, body = parse_frontmatter(raw)
        if "year" not in meta:
            continue
        ru, en = split_lang(body)
        entries.append({
            "year": meta.get("year", ""),
            "title_ru": meta.get("title", ""),
            "title_en": meta.get("title_en", meta.get("title", "")),
            "body_ru": ru,
            "body_en": en,
            "order": int(meta.get("order", "99")),
        })
    return sorted(entries, key=lambda e: e["order"])


def parse_links():
    """Minimal parser for our flat links.yml shape (mirrors old Swift parseLinks)."""
    raw = read_file("Config/links.yml")
    links, heroes, cur, section = [], [], {}, ""
    def flush():
        nonlocal cur
        if "label" in cur:
            if section == "links":
                links.append({
                    "label": cur.get("label", ""),
                    "label_en": cur.get("label_en", cur.get("label", "")),
                    "url": cur.get("url", ""),
                    "icon": cur.get("icon", "link"),
                    "platform": cur.get("platform", ""),
                    "order": int(cur.get("order", "0")),
                    "showCount": cur.get("showCount", "false") == "true",
                })
            elif section == "hero":
                heroes.append({
                    "label": cur.get("label", ""),
                    "label_en": cur.get("label_en", cur.get("label", "")),
                    "url": cur.get("url", ""),
                    "icon": cur.get("icon", "link"),
                    "style": cur.get("style", "support"),
                })
        cur = {}
    for line in raw.split("\n"):
        t = line.strip()
        if t == "links:":
            flush()
            section = "links"
            continue
        if t == "heroButtons:":
            flush()
            section = "hero"
            continue
        if t.startswith("- "):
            flush()
            t = t[2:].strip()
        if ":" in t and section:
            k, v = t.split(":", 1)
            cur[k.strip().lstrip("- ")] = v.strip().strip('"').strip("<>")
    flush()
    return sorted(links, key=lambda l: l["order"]), heroes


def bilingual_div(ru_html, en_html):
    return (f'<div data-lang="ru">{ru_html}</div>'
            f'<div data-lang="en" style="display:none">{en_html}</div>')


def load_snapshot(name, fallback):
    try:
        with open(os.path.join(ROOT, name), encoding="utf-8") as f:
            # Escape closing tags so the JSON can't break out of <script>.
            return f.read().replace("</", "<\\/")
    except OSError:
        return fallback


def build():
    ru_intro, en_intro = read_bilingual("Content/about-intro.md")
    ru_outro, en_outro = read_bilingual("Content/about-outro.md")
    timeline = read_timeline()
    links, heroes = parse_links()

    links_json = [{
        "label": l["label"],
        "label_en": l["label_en"],
        "url": l["url"],
        "icon": l["icon"],
        "platform": l["platform"],
        "order": l["order"],
        "showCount": l["showCount"],
        "subscribeUrl": (l["url"] + ("&" if "?" in l["url"] else "?") + "sub_confirmation=1")
        if l["platform"] == "youtube" else "",
    } for l in links]

    # Instant first paint: bake current data/history/links into the HTML.
    # JS renders the snapshot synchronously, then refreshes from network.
    data_snapshot = load_snapshot("data.json",
        '{"followerCounts":{},"youtubeVideos":[],"liveStream":{"type":"none"}}')
    history_snapshot = load_snapshot("streams_history.json", '{"events":[]}')
    links_snapshot = json.dumps(links_json, ensure_ascii=False).replace("</", "<\\/")

    dist = os.path.join(ROOT, "dist")
    shutil.rmtree(dist, ignore_errors=True)
    os.makedirs(os.path.join(dist, "links"), exist_ok=True)
    os.makedirs(os.path.join(dist, "assets"), exist_ok=True)

    tl_html = []
    for i, e in enumerate(timeline):
        tl_html.append(f"""<details class="timeline card m3-shadow-md" data-reveal{' open' if i == 0 else ''}>
<summary><span class="text-lg font-medium"><span data-lang="ru">{html.escape(e['year'])} — {html.escape(e['title_ru'])}</span><span data-lang="en" style="display:none">{html.escape(e['year'])} — {html.escape(e['title_en'])}</span></span><span class="material-symbols-outlined" aria-hidden="true">expand_more</span></summary>
<div class="md">{bilingual_div(md2html(e['body_ru']), md2html(e['body_en']))}</div>
</details>""")

    hero_btns = []
    for b in heroes:
        href = b["url"] if not b["url"].startswith("/") else BASE + b["url"]
        cls = "support-button" if b.get("style") == "support" else "primary-button"
        hero_btns.append(
            f'<a href="{html.escape(href)}" class="{cls} rounded-full px-6 py-3 font-medium m3-shadow-md">'
            f'<span class="material-symbols-outlined" aria-hidden="true">{html.escape(b.get("icon", "link"))}</span>'
            f'<span data-lang="ru">{html.escape(b.get("label", ""))}</span>'
            f'<span data-lang="en" style="display:none">{html.escape(b.get("label_en", b.get("label", "")))}</span></a>')

    head = f"""<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<link rel="icon" href="{BASE}/assets/avatar.png" type="image/png" />
<link rel="manifest" href="{BASE}/manifest.webmanifest" />
<link rel="apple-touch-icon" href="{BASE}/assets/avatar.png" />
<meta name="theme-color" content="#121212" />
<link rel="preconnect" href="https://fonts.googleapis.com" />
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,1,0&display=swap" rel="stylesheet" />
<link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet" />
<link rel="stylesheet" href="{BASE}/css/style.css" />"""

    index_html = f"""<!DOCTYPE html>
<html lang="ru">
<head>
{head}
<title>Bezzubick MCPlay — Minecraft приключения и стримы</title>
<meta name="description" content="Официальный сайт Bezzubick MCPlay: Minecraft-приключения, стримы, последние видео, календарь стримов и все ссылки." />
<meta property="og:type" content="website" />
<meta property="og:title" content="Bezzubick MCPlay" />
<meta property="og:description" content="Minecraft-приключения, стримы, последние видео и все ссылки." />
<meta property="og:image" content="{BASE}/assets/avatar.png" />
</head>
<body class="dark-theme">
<div id="page-wrap" class="w-full max-w-5xl mx-auto p-4 sm:p-6 lg:p-8">
<div id="offline-warning" class="hidden fixed top-0 left-0 w-full p-3 text-center font-medium z-50 offline-warning rounded-b-lg shadow-lg"><span data-lang="ru">Вы не в сети. Данные могут быть устаревшими.</span><span data-lang="en" style="display:none">You are offline. Data might be outdated.</span></div>
<section class="hero text-center mb-8" data-reveal>
<img class="w-28 h-28 rounded-full mx-auto mb-4 border-4 border-purple-500 object-cover m3-shadow-md" src="{BASE}/assets/avatar.png" alt="Bezzubick MCPlay" fetchpriority="high" />
<h1 class="text-4xl font-bold mb-2">Bezzubick MCPlay</h1>
<p id="hero-tagline" class="text-lg text-gray-400 mb-4"><span data-lang="ru">Привет! Я ютубер и стример из России. Minecraft — мой основной контент.</span><span data-lang="en" style="display:none">Hey! I'm a YouTuber and streamer from Russia. Minecraft is my main content.</span></p>
<div id="totals" class="text-xl font-medium text-purple-400 mb-4">Всего подписчиков: —</div>
<div class="cta hero-cta">
{''.join(hero_btns)}
</div>
</section>
<section class="about-card card m3-shadow-md p-6 mt-6" data-reveal>
<div id="about-intro" class="md">{bilingual_div(md2html(ru_intro), md2html(en_intro))}</div>
<div class="timeline-controls">
<h3 class="text-xl font-bold" id="timeline-title">Лента канала</h3>
<div class="tl-buttons">
<button id="tl-expand" class="primary-button rounded-full px-4 py-2 font-medium m3-shadow-md tl-btn" aria-label="Expand"><span class="material-symbols-outlined" aria-hidden="true">unfold_more</span><span id="tl-expand-text" class="btn-text">Развернуть</span></button>
<button id="tl-collapse" class="control-button rounded-full px-4 py-2 font-medium m3-shadow-md tl-btn" aria-label="Collapse"><span class="material-symbols-outlined" aria-hidden="true">unfold_less</span><span id="tl-collapse-text" class="btn-text">Свернуть</span></button>
</div>
</div>
<div id="timeline">
{''.join(tl_html)}
</div>
<div id="about-outro" class="md mt-4">{bilingual_div(md2html(ru_outro), md2html(en_outro))}</div>
</section>
<div id="content-grid" class="home-grid mt-6 no-live">
<section class="card m3-shadow-md p-6" id="links-cta" data-reveal>
<h2 class="text-xl font-bold mb-2" id="nav-title">Навигация</h2>
<p id="nav-desc" class="text-gray-400 mb-4">Перейдите на страницу со всеми моими ссылками, соцсетями, скином и dev‑инфо.</p>
<a href="{BASE}/links/" class="primary-button rounded-full px-6 py-3 font-medium m3-shadow-md"><span class="material-symbols-outlined" aria-hidden="true">link</span><span id="nav-cta-text">Перейти к ссылкам</span></a>
</section>
<section id="live" class="relative overflow-hidden p-0 hidden" data-reveal>
<div class="youtube-video-container" id="live-embed-wrap"><iframe id="live-embed" title="Live stream" loading="lazy" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe></div>
<div id="live-badge" class="absolute top-3 left-3 px-3 py-1 rounded-full text-white text-xs font-bold live-indicator m3-shadow-md">LIVE</div>
<div id="twitch-notice" class="hidden mt-4 p-4 rounded-2xl text-sm text-center card m3-shadow-md">
<p class="mb-2" id="twitch-text">Стрим также идёт на Twitch!</p>
<a id="twitch-link" href="#" target="_blank" rel="noopener" class="primary-button inline-flex items-center px-4 py-2 rounded-full font-medium"><span class="material-symbols-outlined text-base" aria-hidden="true">videocam</span><span id="twitch-cta">Смотреть на Twitch</span></a>
</div>
</section>
<section id="calendar" class="p-6" data-reveal>
<div class="md text-center mb-2"><h3 id="live-empty-title">Сейчас стрима нет</h3><p id="live-empty-sub">Обычно стримы по пятницам, 17:00–19:00 МСК.</p></div>
<div class="cal-nav">
<button id="cal-prev" class="control-button p-2 rounded-full m3-shadow-md" aria-label="Previous month"><span class="material-symbols-outlined" aria-hidden="true">chevron_left</span></button>
<div id="cal-label" class="font-medium"></div>
<button id="cal-next" class="control-button p-2 rounded-full m3-shadow-md" aria-label="Next month"><span class="material-symbols-outlined" aria-hidden="true">chevron_right</span></button>
</div>
<div id="cal-weekdays" class="stream-cal-head"></div>
<div id="cal-grid" class="stream-cal-grid"></div>
<div class="legend"><span class="dot yt"></span><span id="legend-yt">YouTube</span><span class="dot tw"></span><span id="legend-tw">Twitch</span><span class="dot both"></span><span id="legend-both">Оба</span><span class="dot planned"></span><span id="legend-planned">Потенциальный</span><span class="muted" id="legend-missed">Зачёркнутые — стрима не было</span></div>
</section>
<section id="skin" class="card m3-shadow-md p-6" data-reveal>
<h2 class="text-xl font-bold text-center mb-4" id="skin-title">Мой скин Minecraft</h2>
<div id="skin-viewer" class="skin-viewer"><canvas id="skin-canvas"></canvas></div>
<div id="skin-controls" class="skin-controls" role="group" aria-label="Skin animation"></div>
<div class="flex justify-center mt-4"><a id="download-skin" href="{BASE}/assets/skin.png" class="primary-button rounded-full px-6 py-3 font-medium m3-shadow-md" download="minecraft_skin.png" rel="noopener"><span class="material-symbols-outlined" aria-hidden="true">download</span><span id="skin-download-text">Скачать скин</span></a></div>
</section>
</div>
<section class="mb-8 mt-8" data-reveal>
<h2 class="text-xl font-bold mb-3" id="videos-title">Последние видео</h2>
<div id="carousel" class="flex overflow-x-auto space-x-4 pb-4 video-carousel scroll-smooth"></div>
</section>
<div class="flex justify-center items-center space-x-4 mt-8 mb-8">
<button id="theme-toggle" class="control-button p-3 rounded-full m3-shadow-md flex items-center justify-center" aria-label="Toggle theme"><span class="material-symbols-outlined" id="theme-icon">light_mode</span></button>
<button id="lang-toggle" class="control-button p-3 rounded-full m3-shadow-md flex items-center justify-center" aria-label="Toggle language"><span class="material-symbols-outlined" aria-hidden="true">translate</span></button>
</div>
</div>
<script id="data-snapshot" type="application/json">{data_snapshot}</script>
<script id="history-snapshot" type="application/json">{history_snapshot}</script>
<script id="links-snapshot" type="application/json">{links_snapshot}</script>
<script>window.__BASE__={json.dumps(BASE)};</script>
<script defer src="{BASE}/js/vendor/skinview3d.bundle.js"></script>
<script type="module" src="{BASE}/js/home.js"></script>
</body>
</html>
"""

    links_html = f"""<!DOCTYPE html>
<html lang="ru">
<head>
{head}
<title>BezzubickMCPlay | Мои ссылки</title>
<meta name="description" content="Все ссылки BezzubickMCPlay: YouTube, Telegram, Twitch, TikTok, Instagram и X. Стримы, видео и Minecraft-скин." />
<meta property="og:type" content="website" />
<meta property="og:title" content="BezzubickMCPlay | Links" />
<meta property="og:description" content="Все ссылки BezzubickMCPlay: YouTube, Telegram, Twitch, TikTok, Instagram и X." />
<meta property="og:image" content="{BASE}/assets/avatar.png" />
</head>
<body class="dark-theme">
<div id="app" class="w-full max-w-4xl mx-auto p-4 sm:p-6 lg:p-8">
<div id="offline-warning" class="hidden fixed top-0 left-0 w-full p-3 text-center font-medium z-50 offline-warning rounded-b-lg shadow-lg"><span id="offline-message"></span></div>
<div id="main-view">
<section id="profile-section" class="text-center mb-8 hidden" data-reveal>
<img id="avatar" class="w-28 h-28 rounded-full mx-auto mb-4 border-4 border-purple-500 object-cover m3-shadow-md" src="{BASE}/assets/avatar.png" alt="Аватар" />
<h1 id="profile-name" class="text-4xl font-bold mb-2"></h1>
<p id="profile-description" class="text-lg text-gray-400 mb-4"></p>
<div id="total-followers" class="text-xl font-medium text-purple-400"></div>
</section>
<div id="content-grid" class="content-container grid-layout grid-no-live">
<section id="live-stream-section" class="relative rounded-2xl overflow-hidden m3-shadow-md hidden" data-reveal>
<div class="youtube-video-container"><iframe id="live-embed" title="Live stream" loading="lazy" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe></div>
<div class="absolute top-3 left-3 px-3 py-1 rounded-full text-white text-xs font-bold live-indicator m3-shadow-md">LIVE</div>
<div id="twitch-notification" class="hidden mt-4 p-4 rounded-2xl text-sm text-center card m3-shadow-md">
<p id="twitch-message" class="mb-2"></p>
<a id="twitch-link" href="#" target="_blank" rel="noopener" class="primary-button px-4 py-2 rounded-full font-medium"><span class="material-symbols-outlined text-base" aria-hidden="true">videocam</span><span id="twitch-link-text"></span></a>
</div>
</section>
<div class="main-links-block" data-reveal>
<section id="links-section" class="space-y-4 hidden"></section>
<section id="support-section" class="flex justify-center hidden mt-8">
<a id="support-button" href="https://www.donationalerts.com/r/bezzubickmcplay" target="_blank" rel="noopener" class="primary-button px-6 py-3 rounded-full font-medium m3-shadow-md"><span class="material-symbols-outlined" aria-hidden="true">favorite</span><span id="support-button-text"></span></a>
</section>
</div>
<section id="minecraft-block" class="hidden" data-reveal>
<h2 id="minecraft-title" class="text-xl font-bold text-center mb-4"></h2>
<div id="skin-viewer-container"><canvas id="skin-canvas"></canvas></div>
<div class="flex justify-center mt-4 mb-2"><button id="download-skin-button" class="primary-button px-6 py-3 rounded-full font-medium m3-shadow-md"><span class="material-symbols-outlined" aria-hidden="true">download</span><span id="download-skin-text"></span></button></div>
</section>
</div>
<section id="youtube-videos-section" class="mb-8 mt-8 hidden" data-reveal>
<h2 id="recent-videos-title" class="text-xl font-bold mb-4"></h2>
<div id="video-carousel" class="flex overflow-x-auto space-x-4 pb-4 video-carousel scroll-smooth"></div>
</section>
</div>
<div id="dev-view" class="hidden w-full max-w-4xl mx-auto py-8">
<h2 id="dev-title" class="text-3xl font-bold text-center mb-6"></h2>
<div class="dev-page-content p-6 rounded-2xl m3-shadow-md">
<p class="mb-4"><span id="dev-last-updated-label" class="font-medium"></span> <span id="dev-last-updated" class="text-purple-400"></span></p>
<h3 id="dev-data-json-content-label" class="text-xl font-bold text-left mb-3"></h3>
<pre class="text-left bg-gray-900 p-4 rounded-lg overflow-x-auto text-sm" style="max-height:500px;white-space:pre-wrap;word-wrap:break-word"><code id="dev-data-json-content"></code></pre>
<h3 id="dev-debug-info-content-label" class="text-xl font-bold text-left mt-6 mb-3"></h3>
<pre class="text-left bg-gray-900 p-4 rounded-lg overflow-x-auto text-sm" style="max-height:300px;white-space:pre-wrap;word-wrap:break-word"><code id="dev-debug-info-content"></code></pre>
</div>
<div class="flex justify-center mt-8"><a href="{BASE}/" id="back-to-main-button" class="primary-button px-6 py-3 rounded-full font-medium m3-shadow-md"><span class="material-symbols-outlined" aria-hidden="true">arrow_back</span><span id="back-to-main-text"></span></a></div>
</div>
<div class="flex justify-center items-center space-x-4 mt-8 mb-8">
<a href="{BASE}/" class="control-button p-3 rounded-full m3-shadow-md flex items-center justify-center" aria-label="Back to main site"><span class="material-symbols-outlined" aria-hidden="true">arrow_back</span></a>
<button id="theme-toggle" class="control-button p-3 rounded-full m3-shadow-md flex items-center justify-center" aria-label="Toggle theme"><span class="material-symbols-outlined" id="theme-icon">light_mode</span></button>
<button id="language-toggle" class="control-button p-3 rounded-full m3-shadow-md flex items-center justify-center" aria-label="Toggle language"><span class="material-symbols-outlined" aria-hidden="true">language</span></button>
<button id="dev-toggle" class="control-button p-3 rounded-full m3-shadow-md flex items-center justify-center hidden" aria-label="Toggle developer view"><span class="material-symbols-outlined" aria-hidden="true">code</span></button>
</div>
<div id="first-visit-modal" class="modal" role="dialog" aria-modal="true" aria-labelledby="modal-title">
<div class="modal-content"><h3 id="modal-title" class="text-2xl font-bold mb-4"></h3><p id="modal-description" class="text-base mb-6"></p><button id="modal-close" class="primary-button px-6 py-3 rounded-full font-medium"></button></div>
</div>
</div>
<script id="data-snapshot" type="application/json">{data_snapshot}</script>
<script id="links-snapshot" type="application/json">{links_snapshot}</script>
<script>window.__BASE__={json.dumps(BASE)};</script>
<script defer src="{BASE}/js/vendor/skinview3d.bundle.js"></script>
<script type="module" src="{BASE}/js/links.js"></script>
</body>
</html>
"""

    with open(os.path.join(dist, "index.html"), "w", encoding="utf-8") as f:
        f.write(index_html)
    with open(os.path.join(dist, "links", "index.html"), "w", encoding="utf-8") as f:
        f.write(links_html)

    with open(os.path.join(dist, "assets", "links.json"), "w", encoding="utf-8") as f:
        json.dump(links_json, f, ensure_ascii=False, indent=2)

    for name in ("assets", "css", "js"):
        src = os.path.join(ROOT, name)
        if os.path.isdir(src):
            for fn in os.listdir(src):
                if fn == "links.json":
                    continue
                s, d = os.path.join(src, fn), os.path.join(dist, name, fn)
                if os.path.isdir(s):
                    shutil.copytree(s, d, dirs_exist_ok=True)
                elif os.path.isfile(s):
                    os.makedirs(os.path.dirname(d), exist_ok=True)
                    shutil.copy2(s, d)
    for fn in ("data.json", "streams_history.json",
               "manifest.webmanifest"):
        src = os.path.join(ROOT, fn)
        if os.path.isfile(src):
            shutil.copy2(src, os.path.join(dist, fn))
    # Service worker: stamp a unique cache name per build so browsers
    # detect changed sw.js bytes and actually update the cached shell.
    # (A constant cache name meant clients tested stale code for days.)
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%d%H%M%S")
    with open(os.path.join(ROOT, "sw.js"), encoding="utf-8") as f:
        sw = f.read()
    sw = sw.replace("bezzubick-dev", f"bezzubick-{stamp}")
    with open(os.path.join(dist, "sw.js"), "w", encoding="utf-8") as f:
        f.write(sw)
    print(f"Built dist/ (base={BASE or '/'}), timeline={len(timeline)}, links={len(links)}")


if __name__ == "__main__":
    build()
