import XCTest
@testable import BezzubickMCPlay

/// Unit tests for the pure helper functions of the site generator.
/// Run with `swift test` (also executed in CI before every deploy).
final class SiteGeneratorTests: XCTestCase {

    // MARK: - md2html

    func testMd2HtmlInlineFormatting() {
        let html = md2html("Это **жирный**, *курсив*, `код` и [ссылка](https://example.com).")
        XCTAssertTrue(html.contains("<strong>жирный</strong>"), html)
        XCTAssertTrue(html.contains("<em>курсив</em>"), html)
        XCTAssertTrue(html.contains("<code>код</code>"), html)
        XCTAssertTrue(html.contains("<a href=\"https://example.com\""), html)
        XCTAssertTrue(html.contains(">ссылка</a>"), html)
    }

    func testMd2HtmlDoesNotTreatBoldAsItalic() {
        let html = md2html("Только **жирный** текст")
        XCTAssertTrue(html.contains("<strong>жирный</strong>"), html)
        XCTAssertFalse(html.contains("<em>"), html)
    }

    func testMd2HtmlHeadingsAndLists() {
        let html = md2html("## Заголовок\n\n- пункт один\n- пункт два")
        XCTAssertTrue(html.contains("<h2"), html)
        XCTAssertTrue(html.contains("Заголовок"), html)
        XCTAssertTrue(html.contains("<li"), html)
        XCTAssertTrue(html.contains("пункт один"), html)
    }

    // MARK: - splitLang

    func testSplitLangSeparatesLanguages() {
        let body = "<!-- lang:ru -->\nПривет, мир\n<!-- lang:en -->\nHello, world"
        let parts = splitLang(body)
        XCTAssertTrue(parts.ru.contains("Привет"), parts.ru)
        XCTAssertFalse(parts.ru.contains("Hello"), parts.ru)
        XCTAssertTrue(parts.en.contains("Hello"), parts.en)
        XCTAssertFalse(parts.en.contains("Привет"), parts.en)
    }

    // MARK: - parseLinks (uses the real Config/links.yml at the package root)

    func testParseLinksProducesCleanUrls() {
        let (links, heroes) = parseLinks()
        XCTAssertFalse(links.isEmpty, "Config/links.yml должен содержать ссылки")
        for link in links {
            XCTAssertFalse(link.url.contains("<"), "URL не должен содержать угловые скобки: \(link.url)")
            XCTAssertFalse(link.url.contains(">"), "URL не должен содержать угловые скобки: \(link.url)")
            XCTAssertTrue(link.url.hasPrefix("https://"), "Ожидался https URL: \(link.url)")
        }
        for hero in heroes {
            XCTAssertFalse(hero.url.contains("<"), hero.url)
            XCTAssertFalse(hero.url.contains(">"), hero.url)
        }
    }
}
