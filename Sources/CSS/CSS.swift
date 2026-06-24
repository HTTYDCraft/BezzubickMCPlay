import Foundation

// MARK: - Type-Safe CSS Builder (SwiftUI-like)

@propertyWrapper
public struct CSSProperty {
    public let name: String
    public let value: String
    public var wrappedValue: String { "\(name): \(value);" }
}

public struct CSSDeclaration {
    public let text: String
    public init(_ text: String) { self.text = text }
    public var css: String { text }
}

public func declare(_ pairs: (String, String)...) -> String {
    pairs.map { "\($0.0): \($0.1);" }.joined(separator: " ")
}

// MARK: - Selectors

public struct CSSSelector {
    public let selector: String
    public let declarations: String

    public init(_ selector: String, @CSSBlockBuilder _ content: () -> [CSSDeclaration]) {
        self.selector = selector
        self.declarations = content().map(\.css).joined(separator: " ")
    }

    public init(_ selector: String, raw: String) {
        self.selector = selector
        self.declarations = raw
    }

    public var css: String { "\(selector){\(declarations)}" }
}

@resultBuilder
public struct CSSBlockBuilder {
    public static func buildBlock(_ components: CSSDeclaration...) -> [CSSDeclaration] {
        components
    }
}

// MARK: - Stylesheet

public struct Stylesheet {
    public let items: [StylesheetItem]

    public init(@StylesheetBuilder _ content: () -> [StylesheetItem]) {
        self.items = content()
    }

    public func render() -> String {
        items.map { item -> String in
            if let sel = item as? CSSSelector { return sel.css }
            if let raw = item as? RawCSS { return raw.raw }
            return ""
        }.joined(separator: "\n")
    }
}

public protocol StylesheetItem {}
extension CSSSelector: StylesheetItem {}

public struct RawCSS: StylesheetItem {
    public let raw: String
    public init(_ raw: String) { self.raw = raw }
}

@resultBuilder
public struct StylesheetBuilder {
    public static func buildBlock(_ components: StylesheetItem...) -> [StylesheetItem] {
        components
    }
}

// MARK: - Nested Selectors (media, hover, etc.)

public func media(_ query: String, @StylesheetBuilder _ content: () -> [StylesheetItem]) -> RawCSS {
    let inner = content().map { item -> String in
        if let sel = item as? CSSSelector { return sel.css }
        if let raw = item as? RawCSS { return raw.raw }
        return ""
    }.joined(separator: " ")
    return RawCSS("@media (\(query)) {\(inner)}")
}

public func nested(_ parent: String, @StylesheetBuilder _ content: () -> [StylesheetItem]) -> RawCSS {
    let inner = content().map { item -> String in
        if let sel = item as? CSSSelector {
            // Rewrite selector to nest under parent
            let parts = sel.selector.split(separator: ",")
            return parts.map { p in
                let s = p.trimmingCharacters(in: .whitespaces)
                if s.hasPrefix("&") { return "\(parent)\(s.dropFirst())" }
                return "\(parent) \(s)"
            }.joined(separator: ",") + "{\(sel.declarations)}"
        }
        if let raw = item as? RawCSS { return raw.raw }
        return ""
    }.joined(separator: " ")
    return RawCSS(inner)
}

// MARK: - Property Helpers

public func prop(_ name: String, _ value: String) -> CSSDeclaration {
    CSSDeclaration("\(name):\(value);")
}

// Background
public func backgroundColor(_ v: String) -> CSSDeclaration { prop("background-color", v) }
public func background(_ v: String) -> CSSDeclaration { prop("background", v) }
public func backgroundImage(_ v: String) -> CSSDeclaration { prop("background-image", v) }
public func backgroundSize(_ v: String) -> CSSDeclaration { prop("background-size", v) }

// Text
public func color(_ v: String) -> CSSDeclaration { prop("color", v) }
public func fontFamily(_ v: String) -> CSSDeclaration { prop("font-family", v) }
public func fontSize(_ v: String) -> CSSDeclaration { prop("font-size", v) }
public func fontWeight(_ v: String) -> CSSDeclaration { prop("font-weight", v) }
public func fontStyle(_ v: String) -> CSSDeclaration { prop("font-style", v) }
public func lineHeight(_ v: String) -> CSSDeclaration { prop("line-height", v) }
public func textAlign(_ v: String) -> CSSDeclaration { prop("text-align", v) }
public func textDecoration(_ v: String) -> CSSDeclaration { prop("text-decoration", v) }
public func textShadow(_ v: String) -> CSSDeclaration { prop("text-shadow", v) }
public func whiteSpace(_ v: String) -> CSSDeclaration { prop("white-space", v) }
public func wordWrap(_ v: String) -> CSSDeclaration { prop("word-wrap", v) }
public func letterSpacing(_ v: String) -> CSSDeclaration { prop("letter-spacing", v) }

// Box Model
public func margin(_ v: String) -> CSSDeclaration { prop("margin", v) }
public func padding(_ v: String) -> CSSDeclaration { prop("padding", v) }
public func marginTop(_ v: String) -> CSSDeclaration { prop("margin-top", v) }
public func marginBottom(_ v: String) -> CSSDeclaration { prop("margin-bottom", v) }
public func marginLeft(_ v: String) -> CSSDeclaration { prop("margin-left", v) }
public func marginRight(_ v: String) -> CSSDeclaration { prop("margin-right", v) }
public func paddingTop(_ v: String) -> CSSDeclaration { prop("padding-top", v) }
public func paddingBottom(_ v: String) -> CSSDeclaration { prop("padding-bottom", v) }
public func paddingLeft(_ v: String) -> CSSDeclaration { prop("padding-left", v) }
public func paddingRight(_ v: String) -> CSSDeclaration { prop("padding-right", v) }

// Border
public func border(_ v: String) -> CSSDeclaration { prop("border", v) }
public func borderColor(_ v: String) -> CSSDeclaration { prop("border-color", v) }
public func borderWidth(_ v: String) -> CSSDeclaration { prop("border-width", v) }
public func borderRadius(_ v: String) -> CSSDeclaration { prop("border-radius", v) }
public func outline(_ v: String) -> CSSDeclaration { prop("outline", v) }

// Box
public func boxShadow(_ v: String) -> CSSDeclaration { prop("box-shadow", v) }
public func width(_ v: String) -> CSSDeclaration { prop("width", v) }
public func height(_ v: String) -> CSSDeclaration { prop("height", v) }
public func minWidth(_ v: String) -> CSSDeclaration { prop("min-width", v) }
public func minHeight(_ v: String) -> CSSDeclaration { prop("min-height", v) }
public func maxWidth(_ v: String) -> CSSDeclaration { prop("max-width", v) }
public func maxHeight(_ v: String) -> CSSDeclaration { prop("max-height", v) }
public func aspectRatio(_ v: String) -> CSSDeclaration { prop("aspect-ratio", v) }
public func objectFit(_ v: String) -> CSSDeclaration { prop("object-fit", v) }
public func gap(_ v: String) -> CSSDeclaration { prop("gap", v) }

// Position
public func position(_ v: String) -> CSSDeclaration { prop("position", v) }
public func top(_ v: String) -> CSSDeclaration { prop("top", v) }
public func left(_ v: String) -> CSSDeclaration { prop("left", v) }
public func right(_ v: String) -> CSSDeclaration { prop("right", v) }
public func bottom(_ v: String) -> CSSDeclaration { prop("bottom", v) }
public func inset(_ v: String) -> CSSDeclaration { prop("inset", v) }
public func zIndex(_ v: String) -> CSSDeclaration { prop("z-index", v) }

// Display & Flex
public func display(_ v: String) -> CSSDeclaration { prop("display", v) }
public func flexDirection(_ v: String) -> CSSDeclaration { prop("flex-direction", v) }
public func flexWrap(_ v: String) -> CSSDeclaration { prop("flex-wrap", v) }
public func flex(_ v: String) -> CSSDeclaration { prop("flex", v) }
public func flexGrow(_ v: String) -> CSSDeclaration { prop("flex-grow", v) }
public func flexShrink(_ v: String) -> CSSDeclaration { prop("flex-shrink", v) }
public func alignItems(_ v: String) -> CSSDeclaration { prop("align-items", v) }
public func alignItems(_ v: CSSDeclaration) -> CSSDeclaration { v }
public func alignSelf(_ v: String) -> CSSDeclaration { prop("align-self", v) }
public func justifyContent(_ v: String) -> CSSDeclaration { prop("justify-content", v) }
public func placeItems(_ v: String) -> CSSDeclaration { prop("place-items", v) }
public func order(_ v: String) -> CSSDeclaration { prop("order", v) }

// Grid
public func gridTemplateColumns(_ v: String) -> CSSDeclaration { prop("grid-template-columns", v) }
public func gridTemplateAreas(_ v: String) -> CSSDeclaration { prop("grid-template-areas", v) }
public func gridArea(_ v: String) -> CSSDeclaration { prop("grid-area", v) }
public func gridColumn(_ v: String) -> CSSDeclaration { prop("grid-column", v) }

// Overflow & Visibility
public func overflow(_ v: String) -> CSSDeclaration { prop("overflow", v) }
public func visibility(_ v: String) -> CSSDeclaration { prop("visibility", v) }
public func opacity(_ v: String) -> CSSDeclaration { prop("opacity", v) }

// Cursor & Interaction
public func cursor(_ v: String) -> CSSDeclaration { prop("cursor", v) }
public func userSelect(_ v: String) -> CSSDeclaration { prop("user-select", v) }
public func webkitUserSelect(_ v: String) -> CSSDeclaration { prop("-webkit-user-select", v) }
public func webkitAppearance(_ v: String) -> CSSDeclaration { prop("-webkit-appearance", v) }
public func webkitBackdropFilter(_ v: String) -> CSSDeclaration { prop("-webkit-backdrop-filter", v) }
public func borderLeft(_ v: String) -> CSSDeclaration { prop("border-left", v) }
public func willChange(_ v: String) -> CSSDeclaration { prop("will-change", v) }

// Transition & Animation
public func transition(_ v: String) -> CSSDeclaration { prop("transition", v) }
public func transform(_ v: String) -> CSSDeclaration { prop("transform", v) }
public func animation(_ v: String) -> CSSDeclaration { prop("animation", v) }
public func backdropFilter(_ v: String) -> CSSDeclaration { prop("backdrop-filter", v) }

// Misc
public func listStyle(_ v: String) -> CSSDeclaration { prop("list-style", v) }
public func scrollbarWidth(_ v: String) -> CSSDeclaration { prop("scrollbar-width", v) }

// Raw
public func raw(_ v: String) -> CSSDeclaration { CSSDeclaration(v) }
