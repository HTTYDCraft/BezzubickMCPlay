import Publish
import Plot

// This is the main entry point for your Publish website.
// We define the site configuration, sections, and item metadata here.

struct MyWebsite: Website {
    enum SectionID: String, WebsiteSectionID {
        // Add your sections here
        case posts
        case about
    }

    struct ItemMetadata: WebsiteItemMetadata {
        // Add custom metadata for items here
        // Example: var description: String?
    }

    // Update these properties to configure your website:
    var url = URL(string: "https://your-website-url.com")!
    var name = "My Website"
    var description = "A website generated using Publish"
    var language: Language { .english }
    var imagePath: Path? { nil }
}

// Define your custom theme if needed
// extension Node where Context == HTML.BodyContext {
//     ...
// }

// Publish the website
try MyWebsite().publish(
    withTheme: .foundation,
    deployedUsing: [.gitBranch("gh-pages")]
)
