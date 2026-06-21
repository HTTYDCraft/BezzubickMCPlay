// config_en.js — конфигурация приложения

export const appConfig = {
    dataUrl: "../data.json", // из /links/ выходим в корень
    showLiveStreamSection: true,
    showProfileSection: true,
    showMinecraftSkinSection: true,
    showLinksSection: true,
    showYouTubeVideosSection: true,
    showSupportButton: true,
    developmentMode: true,
    showDevToggle: true,
    showLanguageToggle: true,
    showThemeToggle: true,
    supportUrl: "https://www.donationalerts.com/r/bezzubickmcplay" // ЗАМЕНИТЕ на ваш реальный URL
};

export const profileConfig = {
    name_key: "profileName",
    description_key: "profileDescription",
    avatar: "./assets/avatar.png",      // добавьте файл
    minecraftSkinUrl: "./assets/skin.png" // уже в репозитории
};

export const linksConfig = [
    {
        label_key: "youtubeChannelLabel",
        url: "https://www.youtube.com/channel/UCm6mheCT60mZ5qlxG5r2GeA",
        icon: "play_arrow",
        order: 1,
        isSocial: true,
        showSubscriberCount: true,
        platformId: "youtube",
        subscribeUrl: "https://www.youtube.com/channel/UCm6mheCT60mZ5qlxG5r2GeA?sub_confirmation=1",
        active: true
    },
    {
        label_key: "telegramChannelLabel",
        url: "https://t.me/bezzubickmcplay",
        icon: "send",
        order: 2,
        isSocial: true,
        showSubscriberCount: true,
        platformId: "telegram",
        active: true
    },
    {
        label_key: "twitchChannelLabel",
        url: "https://www.twitch.tv/bezzubickmcplay",
        icon: "live_tv",
        order: 3,
        isSocial: true,
        showSubscriberCount: true,
        platformId: "twitch",
        active: true
    },
    {
        label_key: "tiktokProfileLabel",
        url: "https://www.tiktok.com/@bezzubickmcplay",
        icon: "music_note",
        order: 4,
        isSocial: true,
        showSubscriberCount: false,
        platformId: "tiktok",
        active: true
    },
    {
        label_key: "instagramProfileLabel",
        url: "https://www.instagram.com/bezzubickmcplay/",
        icon: "photo_camera",
        order: 5,
        isSocial: true,
        showSubscriberCount: false,
        platformId: "instagram",
        active: true
    },
    {
        label_key: "xTwitterProfileLabel",
        url: "https://x.com/bezzubickmcplay",
        icon: "public",
        order: 6,
        isSocial: true,
        showSubscriberCount: false,
        platformId: "x",
        active: true
    },
    {
        label_key: "vkGroupLabel",
        url: "https://vk.com/bezzubickmcplay",
        icon: "group",
        order: 7,
        isSocial: true,
        showSubscriberCount: true,
        platformId: "vk_group",
        active: true
    },
    {
        label_key: "vkPersonalPageLabel",
        url: "https://vk.com/bezzubickmcplay_official",
        icon: "person",
        order: 8,
        isSocial: true,
        showSubscriberCount: true,
        platformId: "vk_personal",
        active: true
    }
];