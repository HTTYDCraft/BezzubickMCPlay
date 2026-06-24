import CSS

// MARK: - Main Site Stylesheet

public let siteStylesheet: Stylesheet = Stylesheet {

    // MARK: Root Variables

    CSSSelector(":root") {
        prop("--md-sys-color-primary-dark", "#BB86FC")
        prop("--md-sys-color-on-primary-dark", "#000000")
        prop("--md-sys-color-primary-container-dark", "#4A148C")
        prop("--md-sys-color-on-primary-container-dark", "#FFFFFF")
        prop("--md-sys-color-secondary-dark", "#03DAC6")
        prop("--md-sys-color-on-secondary-dark", "#000000")
        prop("--md-sys-color-surface-dark", "#000000")
        prop("--md-sys-color-on-surface-dark", "#FFFFFF")
        prop("--md-sys-color-background-dark", "#000000")
        prop("--md-sys-color-on-background-dark", "#FFFFFF")
        prop("--md-sys-color-surface-container-low-dark", "#1F1F1F")
        prop("--md-sys-color-surface-container-dark", "#2D2D2D")
        prop("--md-sys-color-outline-dark", "#8C8C8C")
        prop("--md-sys-color-error-dark", "#CF6679")

        prop("--md-sys-color-primary-light", "#6200EE")
        prop("--md-sys-color-on-primary-light", "#FFFFFF")
        prop("--md-sys-color-primary-container-light", "#BB86FC")
        prop("--md-sys-color-on-primary-container-light", "#000000")
        prop("--md-sys-color-secondary-light", "#03DAC6")
        prop("--md-sys-color-on-secondary-light", "#000000")
        prop("--md-sys-color-surface-light", "#FFFFFF")
        prop("--md-sys-color-on-surface-light", "#000000")
        prop("--md-sys-color-background-light", "#FFFFFF")
        prop("--md-sys-color-on-background-light", "#000000")
        prop("--md-sys-color-surface-container-low-light", "#F0F0F0")
        prop("--md-sys-color-surface-container-light", "#E0E0E0")
        prop("--md-sys-color-outline-light", "#BDBDBD")
        prop("--md-sys-color-error-light", "#B00020")

        prop("--live-indicator-red", "#FF0000")

        // Liquid Glass dark
        prop("--glass-bg-dark", "rgba(255,255,255,0.05)")
        prop("--glass-border-dark", "rgba(255,255,255,0.1)")
        prop("--glass-blur-dark", "20px")
        prop("--glass-highlight-dark", "rgba(255,255,255,0.08)")
        prop("--glass-shadow-dark", "0 8px 32px rgba(0,0,0,0.4)")
        prop("--glass-highlight-border-dark", "rgba(255,255,255,0.18)")

        // Liquid Glass light
        prop("--glass-bg-light", "rgba(255,255,255,0.7)")
        prop("--glass-border-light", "rgba(255,255,255,0.5)")
        prop("--glass-blur-light", "12px")
        prop("--glass-highlight-light", "rgba(255,255,255,0.6)")
        prop("--glass-shadow-light", "0 8px 32px rgba(0,0,0,0.08)")
        prop("--glass-highlight-border-light", "rgba(255,255,255,0.8)")
    }

    // MARK: Global Box-Sizing

    CSSSelector("html") {
        prop("box-sizing", "border-box")
    }

    CSSSelector("*, *::before, *::after") {
        prop("box-sizing", "inherit")
    }

    // MARK: Body Base

    CSSSelector("body") {
        fontFamily("'Roboto', sans-serif")
        transition("background-color 0.3s ease, color 0.3s ease")
        display("flex")
        justifyContent("center")
        alignItems("flex-start")
        minHeight("100vh")
        padding("20px")
        prop("box-sizing", "border-box")
        lineHeight("1.6")
        fontWeight("400")
    }

    // MARK: Shadow Utilities

    CSSSelector(".m3-shadow-md") {
        boxShadow("0 3px 5px rgba(0,0,0,.2), 0 1px 18px rgba(0,0,0,.12), 0 6px 10px rgba(0,0,0,.14)")
    }

    CSSSelector(".m3-shadow-lg") {
        boxShadow("0 6px 10px rgba(0,0,0,.2), 0 3px 18px rgba(0,0,0,.12), 0 9px 30px rgba(0,0,0,.14)")
    }

    // MARK: - Material Dark Theme

    CSSSelector("body.dark-theme") {
        backgroundColor("var(--md-sys-color-background-dark)")
        color("var(--md-sys-color-on-background-dark)")
    }

    CSSSelector("body.dark-theme .card") {
        backgroundColor("var(--md-sys-color-surface-container-low-dark)")
        color("var(--md-sys-color-on-surface-dark)")
    }

    CSSSelector("body.dark-theme .modal-content, body.dark-theme .dev-page-content") {
        backgroundColor("var(--md-sys-color-surface-container-dark)")
        color("var(--md-sys-color-on-surface-dark)")
    }

    CSSSelector("body.dark-theme .control-button") {
        backgroundColor("var(--md-sys-color-surface-container-low-dark)")
        color("var(--md-sys-color-on-surface-dark)")
    }

    CSSSelector("body.dark-theme .control-button:hover") {
        backgroundColor("var(--md-sys-color-surface-container-dark)")
    }

    CSSSelector("body.dark-theme .primary-button") {
        backgroundColor("var(--md-sys-color-primary-dark)")
        color("var(--md-sys-color-on-primary-dark)")
    }

    CSSSelector("body.dark-theme .primary-button:hover") {
        backgroundColor("var(--md-sys-color-primary-container-dark)")
        color("var(--md-sys-color-on-primary-container-dark)")
    }

    CSSSelector("body.dark-theme .support-button") {
        backgroundColor("#4CAF50")
        color("var(--md-sys-color-on-primary-dark)")
    }

    CSSSelector("body.dark-theme .support-button:hover") {
        backgroundColor("#388E3C")
    }

    CSSSelector("body.dark-theme .offline-warning") {
        backgroundColor("#FFB300")
        color("#212121")
    }

    // MARK: - Material Light Theme

    CSSSelector("body.light-theme") {
        backgroundColor("var(--md-sys-color-background-light)")
        color("var(--md-sys-color-on-background-light)")
    }

    CSSSelector("body.light-theme .card") {
        backgroundColor("var(--md-sys-color-surface-container-low-light)")
        color("var(--md-sys-color-on-surface-light)")
    }

    CSSSelector("body.light-theme .modal-content, body.light-theme .dev-page-content") {
        backgroundColor("var(--md-sys-color-surface-container-light)")
        color("var(--md-sys-color-on-surface-light)")
    }

    CSSSelector("body.light-theme .control-button") {
        backgroundColor("var(--md-sys-color-surface-container-low-light)")
        color("var(--md-sys-color-on-surface-light)")
    }

    CSSSelector("body.light-theme .control-button:hover") {
        backgroundColor("var(--md-sys-color-surface-container-light)")
    }

    CSSSelector("body.light-theme .primary-button") {
        backgroundColor("var(--md-sys-color-primary-light)")
        color("var(--md-sys-color-on-primary-light)")
    }

    CSSSelector("body.light-theme .primary-button:hover") {
        backgroundColor("var(--md-sys-color-primary-container-light)")
        color("var(--md-sys-color-on-primary-container-light)")
    }

    CSSSelector("body.light-theme .support-button") {
        backgroundColor("#66BB6A")
        color("var(--md-sys-color-on-primary-light)")
    }

    CSSSelector("body.light-theme .support-button:hover") {
        backgroundColor("#43A047")
    }

    // MARK: - Apple Liquid Glass Dark Theme

    CSSSelector("body.glass-dark") {
        background("linear-gradient(135deg, #0a0a0f 0%, #000000 50%, #0d0d1a 100%)")
        color("#FFFFFF")
    }

    CSSSelector("body.glass-dark .card") {
        backgroundColor("rgba(255,255,255,0.04)")
        backdropFilter("blur(24px)")
        prop("-webkit-backdrop-filter", "blur(24px)")
        border("1px solid rgba(255,255,255,0.08)")
        borderRadius("20px")
        boxShadow("inset 0 1px 0 0 rgba(255,255,255,0.06), 0 8px 32px rgba(0,0,0,0.5)")
    }

    CSSSelector("body.glass-dark .card:hover") {
        backgroundColor("rgba(255,255,255,0.07)")
        borderColor("rgba(255,255,255,0.15)")
        boxShadow("inset 0 1px 0 0 rgba(255,255,255,0.1), 0 0 30px rgba(187,134,252,0.12), 0 8px 32px rgba(0,0,0,0.6)")
        transform("translateY(-3px)")
    }

    CSSSelector("body.glass-dark .control-button") {
        backgroundColor("rgba(255,255,255,0.06)")
        backdropFilter("blur(12px)")
        prop("-webkit-backdrop-filter", "blur(12px)")
        border("1px solid rgba(255,255,255,0.1)")
        color("#FFFFFF")
        borderRadius("16px")
    }

    CSSSelector("body.glass-dark .control-button:hover") {
        backgroundColor("rgba(255,255,255,0.1)")
    }

    CSSSelector("body.glass-dark .primary-button") {
        background("linear-gradient(135deg, rgba(187,134,252,0.4), rgba(187,134,252,0.2))")
        backdropFilter("blur(12px)")
        prop("-webkit-backdrop-filter", "blur(12px)")
        border("1px solid rgba(187,134,252,0.3)")
        color("#FFFFFF")
        borderRadius("16px")
    }

    CSSSelector("body.glass-dark .primary-button:hover") {
        background("linear-gradient(135deg, rgba(187,134,252,0.6), rgba(187,134,252,0.3))")
        borderColor("rgba(187,134,252,0.5)")
        boxShadow("0 0 20px rgba(187,134,252,0.2)")
    }

    CSSSelector("body.glass-dark .support-button") {
        background("linear-gradient(135deg, rgba(76,175,80,0.4), rgba(76,175,80,0.2))")
        backdropFilter("blur(12px)")
        prop("-webkit-backdrop-filter", "blur(12px)")
        border("1px solid rgba(76,175,80,0.3)")
        color("#FFFFFF")
        borderRadius("16px")
    }

    CSSSelector("body.glass-dark .support-button:hover") {
        background("linear-gradient(135deg, rgba(76,175,80,0.6), rgba(76,175,80,0.3))")
    }

    CSSSelector("body.glass-dark .modal-content, body.glass-dark .dev-page-content") {
        backgroundColor("rgba(255,255,255,0.06)")
        backdropFilter("blur(24px)")
        prop("-webkit-backdrop-filter", "blur(24px)")
        border("1px solid rgba(255,255,255,0.12)")
        borderRadius("28px")
        boxShadow("inset 0 1px 0 0 rgba(255,255,255,0.1), 0 16px 48px rgba(0,0,0,0.5)")
    }

    CSSSelector("body.glass-dark .mini-button") {
        backgroundColor("rgba(255,255,255,0.06)")
        backdropFilter("blur(12px)")
        prop("-webkit-backdrop-filter", "blur(12px)")
        border("1px solid rgba(255,255,255,0.1)")
        color("#FFFFFF")
    }

    CSSSelector("body.glass-dark .mini-button.active") {
        backgroundColor("rgba(187,134,252,0.3)")
        borderColor("rgba(187,134,252,0.5)")
        color("#FFFFFF")
    }

    CSSSelector("body.glass-dark .offline-warning") {
        backgroundColor("rgba(255,179,0,0.8)")
        backdropFilter("blur(12px)")
        prop("-webkit-backdrop-filter", "blur(12px)")
        color("#212121")
        borderRadius("16px")
    }

    CSSSelector("body.glass-dark .youtube-video-container") {
        boxShadow("0 0 0 1px rgba(255,255,255,0.08), 0 8px 32px rgba(0,0,0,0.4)")
    }

    CSSSelector("body.glass-dark .stream-cal-grid .cell") {
        backgroundColor("rgba(255,255,255,0.04)")
        backdropFilter("blur(12px)")
        prop("-webkit-backdrop-filter", "blur(12px)")
        border("1px solid rgba(255,255,255,0.1)")
    }

    CSSSelector("body.glass-dark .stream-cal-grid .cell.today") {
        outline("2px solid rgba(187,134,252,0.5)")
        boxShadow("0 0 12px rgba(187,134,252,0.15)")
    }

    CSSSelector("body.glass-dark .hero .avatar") {
        border("4px solid rgba(187,134,252,0.5)")
        boxShadow("0 0 20px rgba(187,134,252,0.2)")
    }

    CSSSelector("body.glass-dark .tl-buttons .tl-btn") {
        backgroundColor("rgba(255,255,255,0.06)")
        backdropFilter("blur(12px)")
        prop("-webkit-backdrop-filter", "blur(12px)")
        border("1px solid rgba(255,255,255,0.1)")
        color("#FFFFFF")
    }

    CSSSelector("body.glass-dark .legend") {
        color("rgba(255,255,255,0.8)")
    }

    CSSSelector("body.glass-dark .md code") {
        backgroundColor("rgba(255,255,255,0.06)")
    }

    CSSSelector("body.glass-dark .md pre") {
        backgroundColor("rgba(255,255,255,0.04)")
        border("1px solid rgba(255,255,255,0.08)")
    }

    CSSSelector("body.glass-dark .md blockquote") {
        borderLeft("4px solid rgba(187,134,252,0.5)")
        backgroundColor("rgba(255,255,255,0.03)")
    }

    CSSSelector("body.glass-dark .video-carousel::-webkit-scrollbar-track") {
        backgroundColor("rgba(255,255,255,0.05)")
    }

    CSSSelector("body.glass-dark .video-carousel::-webkit-scrollbar-thumb") {
        backgroundColor("rgba(255,255,255,0.15)")
    }

    CSSSelector("body.glass-dark .video-carousel::-webkit-scrollbar-thumb:hover") {
        backgroundColor("rgba(187,134,252,0.4)")
    }

    // MARK: - Apple Liquid Glass Light Theme

    CSSSelector("body.glass-light") {
        background("linear-gradient(135deg, #E8E0F0 0%, #F2F2F7 50%, #E0E8F0 100%)")
        color("#000000")
    }

    CSSSelector("body.glass-light .card") {
        backgroundColor("rgba(255,255,255,0.65)")
        backdropFilter("blur(20px)")
        prop("-webkit-backdrop-filter", "blur(20px)")
        border("1px solid rgba(255,255,255,0.5)")
        borderRadius("20px")
        boxShadow("inset 0 1px 0 0 rgba(255,255,255,0.6), 0 8px 32px rgba(0,0,0,0.06)")
    }

    CSSSelector("body.glass-light .card:hover") {
        backgroundColor("rgba(255,255,255,0.8)")
        borderColor("rgba(255,255,255,0.8)")
        boxShadow("inset 0 1px 0 0 rgba(255,255,255,0.8), 0 0 30px rgba(98,0,238,0.06), 0 8px 32px rgba(0,0,0,0.08)")
        transform("translateY(-3px)")
    }

    CSSSelector("body.glass-light .control-button") {
        backgroundColor("rgba(255,255,255,0.6)")
        backdropFilter("blur(12px)")
        prop("-webkit-backdrop-filter", "blur(12px)")
        border("1px solid rgba(255,255,255,0.4)")
        color("#000000")
        borderRadius("16px")
    }

    CSSSelector("body.glass-light .control-button:hover") {
        backgroundColor("rgba(255,255,255,0.8)")
    }

    CSSSelector("body.glass-light .primary-button") {
        background("linear-gradient(135deg, rgba(98,0,238,0.8), rgba(98,0,238,0.6))")
        backdropFilter("blur(12px)")
        prop("-webkit-backdrop-filter", "blur(12px)")
        border("1px solid rgba(98,0,238,0.3)")
        color("#FFFFFF")
        borderRadius("16px")
    }

    CSSSelector("body.glass-light .primary-button:hover") {
        background("linear-gradient(135deg, rgba(98,0,238,0.9), rgba(98,0,238,0.7))")
        boxShadow("0 0 20px rgba(98,0,238,0.15)")
    }

    CSSSelector("body.glass-light .support-button") {
        background("linear-gradient(135deg, rgba(102,187,106,0.8), rgba(102,187,106,0.6))")
        backdropFilter("blur(12px)")
        prop("-webkit-backdrop-filter", "blur(12px)")
        border("1px solid rgba(102,187,106,0.3)")
        color("#FFFFFF")
        borderRadius("16px")
    }

    CSSSelector("body.glass-light .support-button:hover") {
        background("linear-gradient(135deg, rgba(102,187,106,0.9), rgba(102,187,106,0.7))")
    }

    CSSSelector("body.glass-light .modal-content, body.glass-light .dev-page-content") {
        backgroundColor("rgba(255,255,255,0.75)")
        backdropFilter("blur(20px)")
        prop("-webkit-backdrop-filter", "blur(20px)")
        border("1px solid rgba(255,255,255,0.5)")
        borderRadius("28px")
        boxShadow("inset 0 1px 0 0 rgba(255,255,255,0.6), 0 16px 48px rgba(0,0,0,0.1)")
    }

    CSSSelector("body.glass-light .mini-button") {
        backgroundColor("rgba(255,255,255,0.6)")
        backdropFilter("blur(8px)")
        prop("-webkit-backdrop-filter", "blur(8px)")
        border("1px solid rgba(0,0,0,0.08)")
        color("#000000")
    }

    CSSSelector("body.glass-light .mini-button.active") {
        backgroundColor("rgba(98,0,238,0.8)")
        borderColor("transparent")
        color("#FFFFFF")
    }

    CSSSelector("body.glass-light .youtube-video-container") {
        boxShadow("0 0 0 1px rgba(0,0,0,0.04), 0 8px 32px rgba(0,0,0,0.08)")
    }

    CSSSelector("body.glass-light .stream-cal-grid .cell") {
        backgroundColor("rgba(255,255,255,0.5)")
        backdropFilter("blur(8px)")
        prop("-webkit-backdrop-filter", "blur(8px)")
        border("1px solid rgba(255,255,255,0.5)")
    }

    CSSSelector("body.glass-light .stream-cal-grid .cell.today") {
        outline("2px solid rgba(98,0,238,0.4)")
        boxShadow("0 0 12px rgba(98,0,238,0.08)")
    }

    CSSSelector("body.glass-light .hero .avatar") {
        border("4px solid rgba(98,0,238,0.3)")
        boxShadow("0 0 20px rgba(98,0,238,0.1)")
    }

    CSSSelector("body.glass-light .tl-buttons .tl-btn") {
        backgroundColor("rgba(255,255,255,0.6)")
        backdropFilter("blur(8px)")
        prop("-webkit-backdrop-filter", "blur(8px)")
        border("1px solid rgba(0,0,0,0.08)")
        color("#000000")
    }

    CSSSelector("body.glass-light .md code") {
        backgroundColor("rgba(0,0,0,0.04)")
    }

    CSSSelector("body.glass-light .md pre") {
        backgroundColor("rgba(0,0,0,0.03)")
        border("1px solid rgba(0,0,0,0.06)")
    }

    CSSSelector("body.glass-light .md blockquote") {
        borderLeft("4px solid rgba(98,0,238,0.4)")
        backgroundColor("rgba(98,0,238,0.03)")
    }

    CSSSelector("body.glass-light .video-carousel::-webkit-scrollbar-track") {
        backgroundColor("rgba(0,0,0,0.05)")
    }

    CSSSelector("body.glass-light .video-carousel::-webkit-scrollbar-thumb") {
        backgroundColor("rgba(0,0,0,0.15)")
    }

    CSSSelector("body.glass-light .video-carousel::-webkit-scrollbar-thumb:hover") {
        backgroundColor("rgba(98,0,238,0.3)")
    }

    CSSSelector("body.glass-light .hero .followers") {
        color("rgba(0,0,0,0.64) !important")
    }

    // MARK: - Card (Home)

    CSSSelector(".card, .card *") {
        prop("user-select", "text !important")
        webkitUserSelect("text !important")
    }

    CSSSelector(".card") {
        borderRadius("16px")
        transition("transform .2s ease, box-shadow .2s ease")
        prop("-webkit-tap-highlight-color", "rgba(187,134,252,.25)")
        prop("will-change", "transform")
    }

    CSSSelector(".card:hover") {
        transform("translateY(-3px)")
        boxShadow("var(--md-sys-color-primary-dark) 0 4px 12px")
    }

    CSSSelector("body.light-theme .card:hover") {
        boxShadow("var(--md-sys-color-primary-light) 0 4px 12px")
    }

    CSSSelector(".card.is-hover") {
        transform("translateY(-3px)")
        boxShadow("var(--md-sys-color-primary-dark) 0 4px 12px !important")
    }

    CSSSelector("body.light-theme .card.is-hover") {
        boxShadow("var(--md-sys-color-primary-light) 0 4px 12px !important")
    }

    CSSSelector(".card:focus-visible") {
        outline("none")
        transform("translateY(-3px)")
        boxShadow("var(--md-sys-color-primary-dark) 0 4px 12px")
    }

    CSSSelector("body.light-theme .card:focus-visible") {
        boxShadow("var(--md-sys-color-primary-light) 0 4px 12px")
    }

    // MARK: - Hero

    CSSSelector(".hero") {
        textAlign("center")
    }

    CSSSelector(".hero .avatar") {
        width("112px")
        height("112px")
        borderRadius("9999px")
        objectFit("cover")
        border("4px solid var(--md-sys-color-primary-dark)")
        display("block")
        margin("0 auto 16px")
    }

    CSSSelector(".hero h1") {
        fontSize("2.25rem")
        margin("0 0 6px")
    }

    CSSSelector(".hero p") {
        margin("0 0 8px")
        opacity(".9")
    }

    CSSSelector(".hero .followers") {
        color("rgba(255,255,255,.72) !important")
    }

    CSSSelector("body.light-theme .hero .followers") {
        color("rgba(0,0,0,.64) !important")
    }

    CSSSelector(".hero-cta") {
        marginTop("12px")
    }

    CSSSelector(".hero .cta") {
        display("flex")
        flexWrap("wrap")
        justifyContent("center")
        gap("12px")
    }

    // MARK: - Markdown

    CSSSelector(".md h2") {
        fontSize("1.6rem")
        fontWeight("700")
        margin("1rem 0 .5rem")
    }

    CSSSelector(".md h3") {
        fontSize("1.25rem")
        fontWeight("700")
        margin("1rem 0 .5rem")
    }

    CSSSelector(".md p") {
        margin(".5rem 0")
        lineHeight("1.7")
    }

    CSSSelector(".md ul") {
        margin(".5rem 0 .75rem 1.15rem")
        listStyle("disc")
    }

    CSSSelector(".md li") {
        margin(".25rem 0")
    }

    CSSSelector(".md em") {
        fontStyle("italic")
    }

    CSSSelector(".md strong") {
        fontWeight("700")
    }

    CSSSelector(".md blockquote") {
        margin(".75rem 0")
        padding(".5rem .75rem")
        prop("border-left", "4px solid var(--md-sys-color-primary-dark)")
        opacity(".95")
    }

    CSSSelector(".md code") {
        backgroundColor("rgba(255,255,255,.08)")
        padding(".1rem .3rem")
        borderRadius("6px")
    }

    CSSSelector(".md pre") {
        backgroundColor("rgba(255,255,255,.08)")
        padding(".75rem")
        borderRadius("12px")
        overflow("auto")
    }

    CSSSelector("body.light-theme .md pre") {
        backgroundColor("rgba(0,0,0,.06)")
    }

    CSSSelector(".md pre code") {
        backgroundColor("transparent")
        padding("0")
    }

    // MARK: - Timeline Controls

    CSSSelector(".timeline-controls") {
        display("flex")
        gap("10px")
        alignItems("center")
        justifyContent("space-between")
        margin("14px 0 8px")
    }

    CSSSelector(".tl-buttons") {
        display("flex")
        gap("8px")
    }

    CSSSelector(".tl-buttons .tl-btn") {
        display("inline-flex")
        alignItems("center")
        gap(".5rem")
        minHeight("44px")
    }

    CSSSelector(".tl-buttons .tl-btn .material-symbols-outlined") {
        lineHeight("1")
    }

    // MARK: - Timeline

    CSSSelector("#timeline") {
        display("flex")
        flexDirection("column")
        gap("12px")
    }

    CSSSelector("#timeline details.card") {
        padding("14px 18px")
        borderRadius("16px")
    }

    CSSSelector("#timeline details.card summary") {
        display("flex")
        alignItems("center")
        justifyContent("space-between")
        gap("12px")
        cursor("pointer")
        listStyle("none")
    }

    CSSSelector("#timeline details.card summary::-webkit-details-marker") {
        display("none")
    }

    CSSSelector("#timeline details.card summary .material-symbols-outlined") {
        transition("transform .2s ease")
    }

    CSSSelector("#timeline details[open] summary .material-symbols-outlined") {
        transform("rotate(180deg)")
    }

    CSSSelector("#timeline .md") {
        paddingTop("8px")
    }

    // MARK: - Home Grid

    CSSSelector(".home-grid") {
        display("grid")
        gap("24px")
    }

    CSSSelector(".home-grid > *") {
        minWidth("0")
    }

    CSSSelector("#links-cta") {
        gridArea("links")
    }

    CSSSelector("#live") {
        gridArea("cal")
        position("relative")
    }

    CSSSelector("#calendar") {
        gridArea("cal2")
        backgroundColor("transparent")
        boxShadow("none")
    }

    CSSSelector("#skin") {
        gridArea("skin")
    }

    CSSSelector(".home-grid.no-live") {
        gridTemplateColumns("1fr")
        gridTemplateAreas("\"links\" \"cal2\" \"skin\"")
    }

    CSSSelector(".home-grid.has-live") {
        gridTemplateColumns("1fr")
        gridTemplateAreas("\"links\" \"cal\" \"cal2\" \"skin\"")
    }

    // MARK: - YouTube Container

    CSSSelector(".youtube-video-container") {
        position("relative")
        width("100%")
        prop("padding-top", "56.25%")
        borderRadius("16px")
        overflow("hidden")
        background("#000")
    }

    CSSSelector(".youtube-video-container iframe") {
        position("absolute")
        inset("0")
        width("100%")
        height("100%")
        border("0")
    }

    // MARK: - Calendar

    CSSSelector(".cal-nav") {
        display("flex")
        alignItems("center")
        justifyContent("space-between")
        gap("8px")
        margin("10px 0")
    }

    CSSSelector(".stream-cal-head, .stream-cal-grid") {
        display("grid")
        gridTemplateColumns("repeat(7, minmax(0,1fr))")
        gap("6px")
    }

    CSSSelector(".stream-cal-head div") {
        textAlign("center")
        fontWeight("600")
        opacity(".8")
    }

    CSSSelector(".stream-cal-grid .cell") {
        textAlign("center")
        padding("8px 6px")
        borderRadius("10px")
        border("1px solid var(--md-sys-color-outline-dark)")
        minHeight("46px")
        display("flex")
        flexDirection("column")
        justifyContent("center")
        gap("3px")
    }

    CSSSelector("body.light-theme .stream-cal-grid .cell") {
        borderColor("var(--md-sys-color-outline-light)")
    }

    CSSSelector(".stream-cal-grid .cell a") {
        color("var(--md-sys-color-primary-dark)")
        textDecoration("underline")
        fontSize(".9rem")
    }

    CSSSelector(".stream-cal-grid .cell.today") {
        outline("2px solid var(--md-sys-color-primary-dark)")
    }

    CSSSelector("body.light-theme .stream-cal-grid .cell.today") {
        outline("2px solid var(--md-sys-color-primary-light)")
    }

    CSSSelector(".stream-cal-grid .cell.fri") {
        backgroundColor("rgba(187,134,252,.08)")
    }

    CSSSelector(".stream-cal-grid .cell.passed.no-stream") {
        opacity(".5")
        textDecoration("line-through")
    }

    // MARK: - Legend & Dots

    CSSSelector(".legend") {
        display("flex")
        alignItems("center")
        gap("10px")
        flexWrap("wrap")
        justifyContent("center")
        marginTop("10px")
        fontSize(".95rem")
    }

    CSSSelector(".dot") {
        width("10px")
        height("10px")
        borderRadius("50%")
        display("inline-block")
    }

    CSSSelector(".dot.yt") {
        backgroundColor("#FF4444")
    }

    CSSSelector(".dot.tw") {
        backgroundColor("#9146FF")
    }

    CSSSelector(".dot.both") {
        background("linear-gradient(90deg, #FF4444 0 50%, #9146FF 50% 100%)")
    }

    CSSSelector(".dot.planned") {
        backgroundColor("#2ECC71")
    }

    CSSSelector(".legend .muted") {
        opacity(".75")
    }

    // MARK: - Skin Viewer (Home)

    CSSSelector("#skin") {
        position("relative")
    }

    CSSSelector(".skin-viewer") {
        width("100%")
        aspectRatio("1 / 1")
        height("auto")
        backgroundColor("transparent")
        borderRadius("16px")
        display("grid")
        placeItems("center")
        position("relative")
        zIndex("1")
    }

    CSSSelector("#skin-canvas") {
        width("100%")
        height("100%")
        display("block")
    }

    // MARK: - Skin Controls

    CSSSelector(".skin-controls") {
        display("flex")
        justifyContent("center")
        alignItems("center")
        gap("10px")
        flexWrap("wrap")
        maxWidth("100%")
        margin("14px 0 10px")
        position("relative")
        zIndex("2")
    }

    CSSSelector(".mini-button") {
        display("inline-flex")
        alignItems("center")
        justifyContent("center")
        height("44px")
        minWidth("44px")
        padding("0 12px")
        borderRadius("9999px")
        border("1px solid rgba(255,255,255,.1)")
        backgroundColor("#2d2d2d")
        color("#fff")
        cursor("pointer")
        prop("touch-action", "manipulation")
        prop("pointer-events", "auto")
    }

    CSSSelector(".mini-button .material-symbols-outlined") {
        fontSize("18px")
        lineHeight("1")
        color("currentColor")
    }

    CSSSelector(".mini-button.active") {
        backgroundColor("var(--md-sys-color-primary-dark)")
        color("#000")
        borderColor("transparent")
    }

    CSSSelector("body.light-theme .mini-button") {
        backgroundColor("var(--md-sys-color-surface-container-low-light)")
        color("var(--md-sys-color-on-surface-light)")
        borderColor("rgba(0,0,0,.10)")
    }

    CSSSelector("body.light-theme .mini-button.active") {
        backgroundColor("var(--md-sys-color-primary-light)")
        color("var(--md-sys-color-on-primary-light)")
        borderColor("transparent")
    }

    // MARK: - Video Carousel

    CSSSelector(".video-carousel::-webkit-scrollbar") {
        height("8px")
    }

    CSSSelector(".video-carousel::-webkit-scrollbar-track") {
        backgroundColor("rgba(255,255,255,0.1)")
        borderRadius("10px")
    }

    CSSSelector("body.light-theme .video-carousel::-webkit-scrollbar-track") {
        backgroundColor("rgba(0,0,0,0.1)")
    }

    CSSSelector(".video-carousel::-webkit-scrollbar-thumb") {
        backgroundColor("var(--md-sys-color-outline-dark)")
        borderRadius("10px")
    }

    CSSSelector("body.light-theme .video-carousel::-webkit-scrollbar-thumb") {
        backgroundColor("var(--md-sys-color-outline-light)")
    }

    CSSSelector(".video-carousel::-webkit-scrollbar-thumb:hover") {
        backgroundColor("var(--md-sys-color-primary-dark)")
    }

    CSSSelector("body.light-theme .video-carousel::-webkit-scrollbar-thumb:hover") {
        backgroundColor("var(--md-sys-color-primary-light)")
    }

    // MARK: - Button Icons

    CSSSelector(".primary-button, .support-button, #twitch-link, #back-to-main-button") {
        display("inline-flex")
        alignItems("center")
        gap("0.75rem")
    }

    CSSSelector(".primary-button .material-symbols-outlined, .support-button .material-symbols-outlined, #twitch-link .material-symbols-outlined, #back-to-main-button .material-symbols-outlined") {
        marginRight("0 !important")
    }

    // MARK: - Link Card Icons

    CSSSelector(".card .flex.items-center.select-none") {
        gap("0.75rem")
    }

    CSSSelector(".icon-large") {
        fontSize("28px")
        lineHeight("1")
        margin("0")
    }

    CSSSelector(".custom-icon-image") {
        width("28px")
        height("28px")
        margin("0")
        objectFit("contain")
        prop("flex-shrink", "0")
    }

    // MARK: Keyframes

    RawCSS("@keyframes fadeInBackground { from { background-color: rgba(0,0,0,0); backdrop-filter: blur(0px); } to { background-color: rgba(0,0,0,0.7); backdrop-filter: blur(5px); } }")
    RawCSS("@keyframes fadeIn { from { opacity:0; transform: scale(.9); } to { opacity:1; transform: scale(1); } }")

    // MARK: - Media Queries

    media("min-width: 768px") {
        CSSSelector("#timeline") {
            maxWidth("980px")
            margin("8px auto 0")
        }

        CSSSelector(".home-grid.no-live") {
            gridTemplateColumns("minmax(320px, 420px) 1fr")
            gridTemplateAreas("\"links cal2\" \"skin  cal2\"")
        }

        CSSSelector(".home-grid.has-live") {
            gridTemplateColumns("minmax(320px, 420px) 1fr")
            gridTemplateAreas("\"links cal\" \"skin  cal2\"")
        }
    }

    media("max-width: 767px") {
        CSSSelector("#page-wrap") {
            paddingLeft("16px")
            paddingRight("16px")
        }

        CSSSelector("#page-wrap > .hero, #page-wrap > .about-card, #page-wrap > .home-grid") {
            marginLeft("0 !important")
            marginRight("0 !important")
            width("100% !important")
        }

        CSSSelector("#timeline") {
            maxWidth("none")
            marginLeft("0")
            marginRight("0")
        }
    }

    media("max-width: 452px") {
        CSSSelector("#links-cta .primary-button") {
            width("100%")
            justifyContent("center")
        }

        CSSSelector("#links-cta .primary-button span") {
            whiteSpace("normal")
        }
    }

    media("max-width: 640px") {
        CSSSelector(".tl-buttons .tl-btn") {
            padding("8px")
            minWidth("44px")
            justifyContent("center")
        }

        CSSSelector(".tl-buttons .btn-text") {
            display("none")
        }
    }

    media("prefers-reduced-motion: reduce") {
        CSSSelector("#timeline details.card summary .material-symbols-outlined") {
            transition("none")
        }
    }
}

// MARK: - Links Page Stylesheet

public let linksPageStylesheet: Stylesheet = Stylesheet {

    // MARK: Root Variables

    CSSSelector(":root") {
        prop("--md-sys-color-primary-dark", "#BB86FC")
        prop("--md-sys-color-on-primary-dark", "#000000")
        prop("--md-sys-color-primary-container-dark", "#4A148C")
        prop("--md-sys-color-on-primary-container-dark", "#FFFFFF")
        prop("--md-sys-color-secondary-dark", "#03DAC6")
        prop("--md-sys-color-on-secondary-dark", "#000000")
        prop("--md-sys-color-surface-dark", "#000000")
        prop("--md-sys-color-on-surface-dark", "#FFFFFF")
        prop("--md-sys-color-background-dark", "#000000")
        prop("--md-sys-color-on-background-dark", "#FFFFFF")
        prop("--md-sys-color-surface-container-low-dark", "#1F1F1F")
        prop("--md-sys-color-surface-container-dark", "#2D2D2D")
        prop("--md-sys-color-outline-dark", "#8C8C8C")
        prop("--md-sys-color-error-dark", "#CF6679")

        prop("--md-sys-color-primary-light", "#6200EE")
        prop("--md-sys-color-on-primary-light", "#FFFFFF")
        prop("--md-sys-color-primary-container-light", "#BB86FC")
        prop("--md-sys-color-on-primary-container-light", "#000000")
        prop("--md-sys-color-secondary-light", "#03DAC6")
        prop("--md-sys-color-on-secondary-light", "#000000")
        prop("--md-sys-color-surface-light", "#FFFFFF")
        prop("--md-sys-color-on-surface-light", "#000000")
        prop("--md-sys-color-background-light", "#FFFFFF")
        prop("--md-sys-color-on-background-light", "#000000")
        prop("--md-sys-color-surface-container-low-light", "#F0F0F0")
        prop("--md-sys-color-surface-container-light", "#E0E0E0")
        prop("--md-sys-color-outline-light", "#BDBDBD")
        prop("--md-sys-color-error-light", "#B00020")

        prop("--live-indicator-red", "#FF0000")

        prop("--glass-bg-dark", "rgba(255,255,255,0.05)")
        prop("--glass-border-dark", "rgba(255,255,255,0.1)")
        prop("--glass-blur-dark", "20px")
        prop("--glass-highlight-dark", "rgba(255,255,255,0.08)")
        prop("--glass-shadow-dark", "0 8px 32px rgba(0,0,0,0.4)")
        prop("--glass-highlight-border-dark", "rgba(255,255,255,0.18)")

        prop("--glass-bg-light", "rgba(255,255,255,0.7)")
        prop("--glass-border-light", "rgba(255,255,255,0.5)")
        prop("--glass-blur-light", "12px")
        prop("--glass-highlight-light", "rgba(255,255,255,0.6)")
        prop("--glass-shadow-light", "0 8px 32px rgba(0,0,0,0.08)")
        prop("--glass-highlight-border-light", "rgba(255,255,255,0.8)")
    }

    // MARK: Body Base

    CSSSelector("body") {
        fontFamily("'Roboto', sans-serif")
        transition("background-color 0.3s ease, color 0.3s ease")
        display("flex")
        justifyContent("center")
        alignItems("flex-start")
        minHeight("100vh")
        padding("20px")
        prop("box-sizing", "border-box")
        lineHeight("1.6")
        fontWeight("400")
    }

    // MARK: Shadow Utilities

    CSSSelector(".m3-shadow-md") {
        boxShadow("0 3px 5px rgba(0,0,0,.2), 0 1px 18px rgba(0,0,0,.12), 0 6px 10px rgba(0,0,0,.14)")
    }

    CSSSelector(".m3-shadow-lg") {
        boxShadow("0 6px 10px rgba(0,0,0,.2), 0 3px 18px rgba(0,0,0,.12), 0 9px 30px rgba(0,0,0,.14)")
    }

    // MARK: - Material Dark Theme (Links)

    CSSSelector("body.dark-theme") {
        backgroundColor("var(--md-sys-color-background-dark)")
        color("var(--md-sys-color-on-background-dark)")
    }

    CSSSelector("body.dark-theme .card") {
        backgroundColor("var(--md-sys-color-surface-container-low-dark)")
        color("var(--md-sys-color-on-surface-dark)")
    }

    CSSSelector("body.dark-theme .modal-content, body.dark-theme .dev-page-content") {
        backgroundColor("var(--md-sys-color-surface-container-dark)")
        color("var(--md-sys-color-on-surface-dark)")
    }

    CSSSelector("body.dark-theme .control-button") {
        backgroundColor("var(--md-sys-color-surface-container-low-dark)")
        color("var(--md-sys-color-on-surface-dark)")
    }

    CSSSelector("body.dark-theme .control-button:hover") {
        backgroundColor("var(--md-sys-color-surface-container-dark)")
    }

    CSSSelector("body.dark-theme .primary-button") {
        backgroundColor("var(--md-sys-color-primary-dark)")
        color("var(--md-sys-color-on-primary-dark)")
    }

    CSSSelector("body.dark-theme .primary-button:hover") {
        backgroundColor("var(--md-sys-color-primary-container-dark)")
        color("var(--md-sys-color-on-primary-container-dark)")
    }

    CSSSelector("body.dark-theme .support-button") {
        backgroundColor("#4CAF50")
        color("var(--md-sys-color-on-primary-dark)")
    }

    CSSSelector("body.dark-theme .support-button:hover") {
        backgroundColor("#388E3C")
    }

    CSSSelector("body.dark-theme .mini-button.active") {
        backgroundColor("var(--md-sys-color-primary-dark)")
        color("var(--md-sys-color-on-primary-dark)")
        borderColor("transparent")
    }

    // MARK: - Material Light Theme (Links)

    CSSSelector("body.light-theme") {
        backgroundColor("var(--md-sys-color-background-light)")
        color("var(--md-sys-color-on-background-light)")
    }

    CSSSelector("body.light-theme .card") {
        backgroundColor("var(--md-sys-color-surface-container-low-light)")
        color("var(--md-sys-color-on-surface-light)")
    }

    CSSSelector("body.light-theme .modal-content, body.light-theme .dev-page-content") {
        backgroundColor("var(--md-sys-color-surface-container-light)")
        color("var(--md-sys-color-on-surface-light)")
    }

    CSSSelector("body.light-theme .control-button") {
        backgroundColor("var(--md-sys-color-surface-container-low-light)")
        color("var(--md-sys-color-on-surface-light)")
    }

    CSSSelector("body.light-theme .control-button:hover") {
        backgroundColor("var(--md-sys-color-surface-container-light)")
    }

    CSSSelector("body.light-theme .primary-button") {
        backgroundColor("var(--md-sys-color-primary-light)")
        color("var(--md-sys-color-on-primary-light)")
    }

    CSSSelector("body.light-theme .primary-button:hover") {
        backgroundColor("var(--md-sys-color-primary-container-light)")
        color("var(--md-sys-color-on-primary-container-light)")
    }

    CSSSelector("body.light-theme .support-button") {
        backgroundColor("#66BB6A")
        color("var(--md-sys-color-on-primary-light)")
    }

    CSSSelector("body.light-theme .support-button:hover") {
        backgroundColor("#43A047")
    }

    CSSSelector("body.light-theme .mini-button.active") {
        backgroundColor("var(--md-sys-color-primary-light)")
        color("var(--md-sys-color-on-primary-light)")
        borderColor("transparent")
    }

    // MARK: - Apple Liquid Glass Dark Theme (Links)

    CSSSelector("body.glass-dark") {
        background("linear-gradient(135deg, #0a0a0f 0%, #000000 50%, #0d0d1a 100%)")
        color("#FFFFFF")
    }

    CSSSelector("body.glass-dark .card") {
        backgroundColor("rgba(255,255,255,0.04)")
        backdropFilter("blur(24px)")
        prop("-webkit-backdrop-filter", "blur(24px)")
        border("1px solid rgba(255,255,255,0.08)")
        borderRadius("20px")
        boxShadow("inset 0 1px 0 0 rgba(255,255,255,0.06), 0 8px 32px rgba(0,0,0,0.5)")
    }

    CSSSelector("body.glass-dark .card:hover") {
        backgroundColor("rgba(255,255,255,0.07)")
        borderColor("rgba(255,255,255,0.15)")
        boxShadow("inset 0 1px 0 0 rgba(255,255,255,0.1), 0 0 30px rgba(187,134,252,0.12), 0 8px 32px rgba(0,0,0,0.6)")
        transform("translateY(-3px)")
    }

    CSSSelector("body.glass-dark .control-button") {
        backgroundColor("rgba(255,255,255,0.06)")
        backdropFilter("blur(12px)")
        prop("-webkit-backdrop-filter", "blur(12px)")
        border("1px solid rgba(255,255,255,0.1)")
        color("#FFFFFF")
        borderRadius("16px")
    }

    CSSSelector("body.glass-dark .control-button:hover") {
        backgroundColor("rgba(255,255,255,0.1)")
    }

    CSSSelector("body.glass-dark .primary-button") {
        background("linear-gradient(135deg, rgba(187,134,252,0.4), rgba(187,134,252,0.2))")
        backdropFilter("blur(12px)")
        prop("-webkit-backdrop-filter", "blur(12px)")
        border("1px solid rgba(187,134,252,0.3)")
        color("#FFFFFF")
        borderRadius("16px")
    }

    CSSSelector("body.glass-dark .primary-button:hover") {
        background("linear-gradient(135deg, rgba(187,134,252,0.6), rgba(187,134,252,0.3))")
        borderColor("rgba(187,134,252,0.5)")
        boxShadow("0 0 20px rgba(187,134,252,0.2)")
    }

    CSSSelector("body.glass-dark .support-button") {
        background("linear-gradient(135deg, rgba(76,175,80,0.4), rgba(76,175,80,0.2))")
        backdropFilter("blur(12px)")
        prop("-webkit-backdrop-filter", "blur(12px)")
        border("1px solid rgba(76,175,80,0.3)")
        color("#FFFFFF")
        borderRadius("16px")
    }

    CSSSelector("body.glass-dark .support-button:hover") {
        background("linear-gradient(135deg, rgba(76,175,80,0.6), rgba(76,175,80,0.3))")
    }

    CSSSelector("body.glass-dark .modal-content, body.glass-dark .dev-page-content") {
        backgroundColor("rgba(255,255,255,0.06)")
        backdropFilter("blur(24px)")
        prop("-webkit-backdrop-filter", "blur(24px)")
        border("1px solid rgba(255,255,255,0.12)")
        borderRadius("28px")
        boxShadow("inset 0 1px 0 0 rgba(255,255,255,0.1), 0 16px 48px rgba(0,0,0,0.5)")
    }

    CSSSelector("body.glass-dark .mini-button") {
        backgroundColor("rgba(255,255,255,0.06)")
        backdropFilter("blur(12px)")
        prop("-webkit-backdrop-filter", "blur(12px)")
        border("1px solid rgba(255,255,255,0.1)")
        color("#FFFFFF")
    }

    CSSSelector("body.glass-dark .mini-button.active") {
        backgroundColor("rgba(187,134,252,0.3)")
        borderColor("rgba(187,134,252,0.5)")
        color("#FFFFFF")
    }

    CSSSelector("body.glass-dark .youtube-video-container") {
        boxShadow("0 0 0 1px rgba(255,255,255,0.08), 0 8px 32px rgba(0,0,0,0.4)")
    }

    CSSSelector("body.glass-dark .stream-cal-grid .cell") {
        backgroundColor("rgba(255,255,255,0.04)")
        backdropFilter("blur(12px)")
        prop("-webkit-backdrop-filter", "blur(12px)")
        border("1px solid rgba(255,255,255,0.1)")
    }

    CSSSelector("body.glass-dark .mini-icon.material-symbols-outlined") {
        color("currentColor")
    }

    // MARK: - Apple Liquid Glass Light Theme (Links)

    CSSSelector("body.glass-light") {
        background("linear-gradient(135deg, #E8E0F0 0%, #F2F2F7 50%, #E0E8F0 100%)")
        color("#000000")
    }

    CSSSelector("body.glass-light .card") {
        backgroundColor("rgba(255,255,255,0.65)")
        backdropFilter("blur(20px)")
        prop("-webkit-backdrop-filter", "blur(20px)")
        border("1px solid rgba(255,255,255,0.5)")
        borderRadius("20px")
        boxShadow("inset 0 1px 0 0 rgba(255,255,255,0.6), 0 8px 32px rgba(0,0,0,0.06)")
    }

    CSSSelector("body.glass-light .card:hover") {
        backgroundColor("rgba(255,255,255,0.8)")
        borderColor("rgba(255,255,255,0.8)")
        boxShadow("inset 0 1px 0 0 rgba(255,255,255,0.8), 0 0 30px rgba(98,0,238,0.06), 0 8px 32px rgba(0,0,0,0.08)")
        transform("translateY(-3px)")
    }

    CSSSelector("body.glass-light .control-button") {
        backgroundColor("rgba(255,255,255,0.6)")
        backdropFilter("blur(8px)")
        prop("-webkit-backdrop-filter", "blur(8px)")
        border("1px solid rgba(255,255,255,0.4)")
        color("#000000")
        borderRadius("16px")
    }

    CSSSelector("body.glass-light .control-button:hover") {
        backgroundColor("rgba(255,255,255,0.8)")
    }

    CSSSelector("body.glass-light .primary-button") {
        background("linear-gradient(135deg, rgba(98,0,238,0.8), rgba(98,0,238,0.6))")
        backdropFilter("blur(12px)")
        prop("-webkit-backdrop-filter", "blur(12px)")
        border("1px solid rgba(98,0,238,0.3)")
        color("#FFFFFF")
        borderRadius("16px")
    }

    CSSSelector("body.glass-light .primary-button:hover") {
        background("linear-gradient(135deg, rgba(98,0,238,0.9), rgba(98,0,238,0.7))")
        boxShadow("0 0 20px rgba(98,0,238,0.15)")
    }

    CSSSelector("body.glass-light .support-button") {
        background("linear-gradient(135deg, rgba(102,187,106,0.8), rgba(102,187,106,0.6))")
        backdropFilter("blur(12px)")
        prop("-webkit-backdrop-filter", "blur(12px)")
        border("1px solid rgba(102,187,106,0.3)")
        color("#FFFFFF")
        borderRadius("16px")
    }

    CSSSelector("body.glass-light .support-button:hover") {
        background("linear-gradient(135deg, rgba(102,187,106,0.9), rgba(102,187,106,0.7))")
    }

    CSSSelector("body.glass-light .modal-content, body.glass-light .dev-page-content") {
        backgroundColor("rgba(255,255,255,0.75)")
        backdropFilter("blur(20px)")
        prop("-webkit-backdrop-filter", "blur(20px)")
        border("1px solid rgba(255,255,255,0.5)")
        borderRadius("28px")
        boxShadow("inset 0 1px 0 0 rgba(255,255,255,0.6), 0 16px 48px rgba(0,0,0,0.1)")
    }

    CSSSelector("body.glass-light .mini-button") {
        backgroundColor("rgba(255,255,255,0.6)")
        backdropFilter("blur(8px)")
        prop("-webkit-backdrop-filter", "blur(8px)")
        border("1px solid rgba(0,0,0,0.08)")
        color("#000000")
    }

    CSSSelector("body.glass-light .mini-button.active") {
        backgroundColor("rgba(98,0,238,0.8)")
        borderColor("transparent")
        color("#FFFFFF")
    }

    CSSSelector("body.glass-light .youtube-video-container") {
        boxShadow("0 0 0 1px rgba(0,0,0,0.04), 0 8px 32px rgba(0,0,0,0.08)")
    }

    CSSSelector("body.glass-light .mini-icon.material-symbols-outlined") {
        color("currentColor")
    }

    // MARK: - Card (Links)

    CSSSelector(".card") {
        borderRadius("16px")
        transition("background-color .3s ease, transform .2s ease, box-shadow .2s ease")
        userSelect("none")
        webkitUserSelect("none")
    }

    CSSSelector(".card:hover") {
        transform("translateY(-3px)")
        boxShadow("var(--md-sys-color-primary-dark) 0 4px 12px")
    }

    CSSSelector("body.light-theme .card:hover") {
        boxShadow("var(--md-sys-color-primary-light) 0 4px 12px")
    }

    // MARK: - Live Indicator

    CSSSelector(".live-indicator") {
        backgroundColor("var(--live-indicator-red)")
    }

    // MARK: - Modals

    CSSSelector(".modal") {
        display("none")
        position("fixed")
        zIndex("100")
        left("0")
        top("0")
        width("100%")
        height("100%")
        backgroundColor("rgba(0,0,0,0.7)")
        alignItems("center")
        justifyContent("center")
        backdropFilter("blur(5px)")
        animation("fadeInBackground .3s ease-out")
    }

    CSSSelector(".modal.active") {
        display("flex")
    }

    CSSSelector(".modal-content, .dev-page-content") {
        padding("24px")
        borderRadius("28px")
        maxWidth("90%")
        animation("fadeIn .3s ease-out")
        textAlign("center")
        boxShadow("var(--md-sys-color-outline-dark) 0 8px 16px")
    }

    CSSSelector("body.light-theme .modal-content, body.light-theme .dev-page-content") {
        boxShadow("var(--md-sys-color-outline-light) 0 8px 16px")
    }

    // MARK: - Swipe Effects

    CSSSelector(".card.swiping-right") {
        transform("translateX(60px) scale(0.98)")
        boxShadow("0 0 20px var(--md-sys-color-primary-dark)")
        background("linear-gradient(to right, var(--md-sys-color-primary-dark) 0%, transparent 100%)")
    }

    CSSSelector("body.light-theme .card.swiping-right") {
        boxShadow("0 0 20px var(--md-sys-color-primary-light)")
        background("linear-gradient(to right, var(--md-sys-color-primary-light) 0%, transparent 100%)")
    }

    CSSSelector(".card.swiping-left") {
        transform("translateX(-60px) scale(0.98)")
        boxShadow("0 0 20px var(--live-indicator-red)")
        background("linear-gradient(to left, var(--live-indicator-red) 0%, transparent 100%)")
    }

    // MARK: - Links Grid Layout

    CSSSelector(".content-container.grid-layout") {
        display("grid")
        gap("24px")
    }

    CSSSelector("#live-stream-section") {
        gridArea("live")
    }

    CSSSelector(".main-links-block") {
        gridArea("links")
    }

    CSSSelector("#minecraft-block") {
        gridArea("skin")
    }

    CSSSelector(".content-container.grid-layout.grid-has-live") {
        gridTemplateColumns("1fr")
        gridTemplateAreas("\"live\" \"links\" \"skin\"")
    }

    CSSSelector(".content-container.grid-layout.grid-no-live") {
        gridTemplateColumns("1fr")
        gridTemplateAreas("\"links\" \"skin\"")
    }

    // MARK: - YouTube Container (Links)

    CSSSelector(".youtube-video-container") {
        position("relative")
        width("100%")
        prop("padding-bottom", "56.25%")
        height("0")
        overflow("hidden")
        borderRadius("16px")
        boxShadow("var(--md-sys-color-outline-dark) 0 4px 8px")
    }

    CSSSelector("body.light-theme .youtube-video-container") {
        boxShadow("var(--md-sys-color-outline-light) 0 4px 8px")
    }

    CSSSelector(".youtube-video-container iframe") {
        position("absolute")
        inset("0")
        width("100%")
        height("100%")
    }

    // MARK: - Skin Viewer (Links)

    CSSSelector("#minecraft-block") {
        display("flex")
        flexDirection("column")
        alignItems("center")
        textAlign("center")
    }

    CSSSelector("#skin-viewer-container") {
        display("grid")
        placeItems("center")
        marginLeft("auto")
        marginRight("auto")
        width("100%")
        height("20rem")
        boxShadow("none")
        backgroundColor("transparent")
    }

    CSSSelector("#skin-viewer-container > canvas") {
        display("block")
        margin("0 auto")
    }

    CSSSelector("body.light-theme #skin-viewer-container, body.light-theme #skin-viewer-container img") {
        boxShadow("none")
        backgroundColor("transparent")
    }

    // MARK: - Skin Controls (Links)

    CSSSelector(".skin-controls") {
        display("flex")
        justifyContent("center")
        alignItems("center")
        gap("10px")
        flexWrap("wrap")
        maxWidth("100%")
        marginTop("16px")
        marginBottom("12px")
    }

    CSSSelector(".mini-button") {
        display("inline-flex")
        alignItems("center")
        justifyContent("center")
        height("34px")
        minWidth("36px")
        padding("0 10px")
        borderRadius("9999px")
        fontSize("12px")
        lineHeight("1")
        cursor("pointer")
        border("1px solid transparent")
        transition("background-color .2s, color .2s, box-shadow .2s, border-color .2s")
        flex("0 0 auto")
    }

    CSSSelector(".mini-button .mini-icon.material-symbols-outlined") {
        fontSize("18px")
        lineHeight("1")
    }

    CSSSelector(".mini-button .material-symbols-outlined") {
        color("currentColor")
    }

    // MARK: - Button Icons (Links)

    CSSSelector(".primary-button, .support-button, #twitch-link, #back-to-main-button") {
        display("inline-flex")
        alignItems("center")
        gap("0.75rem")
    }

    CSSSelector(".primary-button .material-symbols-outlined, .support-button .material-symbols-outlined, #twitch-link .material-symbols-outlined, #back-to-main-button .material-symbols-outlined") {
        marginRight("0 !important")
    }

    // MARK: - Link Card Icons (Links)

    CSSSelector(".card .flex.items-center.select-none") {
        gap("0.75rem")
    }

    CSSSelector(".icon-large") {
        fontSize("28px")
        lineHeight("1")
        margin("0")
    }

    CSSSelector(".custom-icon-image") {
        width("28px")
        height("28px")
        margin("0")
        objectFit("contain")
        prop("flex-shrink", "0")
    }

    // MARK: - Video Carousel (Links)

    CSSSelector(".video-carousel::-webkit-scrollbar") {
        height("8px")
    }

    CSSSelector(".video-carousel::-webkit-scrollbar-track") {
        backgroundColor("rgba(255,255,255,0.1)")
        borderRadius("10px")
    }

    CSSSelector("body.light-theme .video-carousel::-webkit-scrollbar-track") {
        backgroundColor("rgba(0,0,0,0.1)")
    }

    CSSSelector(".video-carousel::-webkit-scrollbar-thumb") {
        backgroundColor("var(--md-sys-color-outline-dark)")
        borderRadius("10px")
    }

    CSSSelector("body.light-theme .video-carousel::-webkit-scrollbar-thumb") {
        backgroundColor("var(--md-sys-color-outline-light)")
    }

    CSSSelector(".video-carousel::-webkit-scrollbar-thumb:hover") {
        backgroundColor("var(--md-sys-color-primary-dark)")
    }

    CSSSelector("body.light-theme .video-carousel::-webkit-scrollbar-thumb:hover") {
        backgroundColor("var(--md-sys-color-primary-light)")
    }

    // MARK: Keyframes

    RawCSS("@keyframes fadeInBackground { from { background-color: rgba(0,0,0,0); backdrop-filter: blur(0px); } to { background-color: rgba(0,0,0,0.7); backdrop-filter: blur(5px); } }")
    RawCSS("@keyframes fadeIn { from { opacity:0; transform: scale(.9); } to { opacity:1; transform: scale(1); } }")

    // MARK: - Media Queries (Links)

    media("min-width: 768px") {
        CSSSelector(".content-container.grid-layout.grid-has-live") {
            gridTemplateColumns("1fr 350px")
            gridTemplateAreas("\"links live\" \"links skin\"")
        }

        CSSSelector(".content-container.grid-layout.grid-no-live") {
            gridTemplateColumns("1fr 350px")
            gridTemplateAreas("\"links skin\"")
        }
    }

    media("max-width: 767px") {
        CSSSelector("#skin-viewer-container") {
            width("clamp(240px, 80vw, 320px)")
            height("clamp(240px, 80vw, 320px)")
        }
    }
}
