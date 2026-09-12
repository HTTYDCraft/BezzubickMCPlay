# BezzubickMCPlay

Чистый статический сайт (HTML + CSS + JS) с видом Apple Liquid Glass.
Никакого Swift, macOS или WASM-тулчейна: сборка и воркер работают на Linux.

## Структура

- `Content/` — **конфиги контента (Markdown, источник правды)**:
  `about-intro.md`, `about-outro.md`, `timeline/*.md` (двуязычные через
  `<!-- lang:ru -->` / `<!-- lang:en -->`, мета — `title`, `title_en`, `year`, `order`)
- `Config/` — **конфиги (YAML, источник правды)**: `links.yml` (ссылки + кнопки hero),
  `site.yml` (мета сайта)
- `css/style.css` — все стили: 4 темы (`dark`, `light`, `glass-dark`, `glass-light`),
  календарь, таймлайн, скин, карусель. Порт `SiteStyles.swift`
- `js/` — `common.js` (темы/язык/скин/fetch), `home.js` (главная), `links.js`
  (страница ссылок), `vendor/skinview3d.bundle.js` (3D-скин, локально).
  Порт `siteJS`/`linksJS` из Swift без WASM-загрузчика
- `assets/` — аватар, скин
- `tools/build.py` — сборщик (только stdlib): читает `Content/` + `Config/`,
  пишет `dist/` (`index.html`, `links/`, `assets/links.json` + копии)
- `worker/cmd/update-data/main.go` — воркер данных (порт `UpdateData/main.swift` на Go):
  подписчики, видео, live-статус → `data.json`, `streams_history.json`
- `data.json`, `streams_history.json` — данные (обновляет воркер)
- `sw.js`, `manifest.webmanifest` — PWA
- `_deprecated/` — старый HTML и весь Swift-код (`swift-legacy/`)

## Локальный предпросмотр

```sh
python3 tools/build.py --base ""   # без префикса для localhost
python3 -m http.server 8000 --directory dist
```

Для GitHub Pages (проект): `--base /BezzubickMCPlay` (см. `deploy.yml`,
переменная `SITE_BASE`).

## Воркер локально

```sh
go run ./worker/cmd/update-data --data data.json --history streams_history.json
```

Тест live: открой сайт с `?mockLive=youtube:VIDEO_ID`,
`?mockLive=twitch:channel`, `?mockLive=both:YT:TW` или `?mockLive=none`.
Dev-панель страницы ссылок: только по ссылке `?dev=1`.

## Язык и темы

- Первый визит: язык — из браузера, тема — из системы.
- Любой выбор (кнопками или диплинком) запоминается и дальше не меняется сам.
- Диплинки: `?lang=ru|en`, `?theme=dark|light|glass-dark|glass-light`
  (например `/links/?lang=en&theme=glass-light`).
- Переключатель тем: везде только glass (`glass-dark`/`glass-light`),
  на Android — Material (`dark`/`light`).
