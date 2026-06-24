---
title: "README"
---

# Debug & URL Parameters

## Language
- `?lang=ru` — русский
- `?lang=en` — English

## Theme (override auto-detect)
- `?theme=dark` — Material You dark
- `?theme=light` — Material You light
- `?theme=glass-dark` — Liquid Glass dark
- `?theme=glass-light` — Liquid Glass light
- `?debugTheme=dark` — same as theme, but persists in code as "debug" source

## Mock data (for testing live stream UI)
- `?mockLive=none` — no live stream
- `?mockLive=youtube:VIDEO_ID` — YouTube live with given video ID
- `?mockLive=twitch:CHANNEL` — Twitch live with given channel name
- `?mockLive=both:VIDEO_ID:CHANNEL` — both platforms simultaneously
- `?mockLive=youtube:e7K5ijK2VOo` — example YouTube mock
- `?mockLive=twitch:monstercat` — example Twitch mock
