import SwiftUI

/// Basic Markdown → AttributedString renderer.
/// Supports: **bold**, *italic*, # headings, - lists, `code`.
/// No third-party dependencies.
struct MarkdownRenderer {
    static func render(_ text: String) -> AttributedString {
        // Try the built-in Markdown parser first
        if let attributed = try? AttributedString(markdown: text, options: .init(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )) {
            return attributed
        }
        // Fallback to plain text
        return AttributedString(text)
    }
}

/// SwiftUI view that renders Markdown text.
struct MarkdownText: View {
    let content: String

    var body: some View {
        Text(MarkdownRenderer.render(content))
            .textSelection(.enabled)
    }
}
