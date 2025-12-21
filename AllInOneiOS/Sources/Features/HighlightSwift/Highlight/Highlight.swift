import Foundation

public final class Highlight: Sendable {
  private let hljs = HLJS()

  public init() {}

  public func attributedText(_ text: String, colors: HighlightColors = .light(.xcode))
    async throws -> AttributedString
  {
    try await process(text, mode: .automatic, colors: colors).attributedText
  }

  public func attributedText(
    _ text: String, language: HighlightLanguage, colors: HighlightColors = .light(.xcode)
  )
    async throws -> AttributedString
  {
    try await process(text, mode: .language(language), colors: colors).attributedText
  }

  public func process(
    _ text: String, mode: HighlightMode = .automatic, colors: HighlightColors = .light(.xcode)
  ) async throws -> HighlightResult {
    let hljsResult = try await hljs.highlight(text, mode: mode)
    let isUndefined = hljsResult.value == "undefined"
    var attributedText: AttributedString
    if isUndefined {
      attributedText = AttributedString(stringLiteral: text)
    } else {
      let data = try htmlDataFromText(hljsResult.value, selectors: colors.css)
      attributedText = try attributedTextFromData(data)
    }
    return HighlightResult(
      attributedText: attributedText,
      highlightJSResult: hljsResult,
      backgroundColorHex: colors.background
    )
  }

  private func htmlDataFromText(_ text: String, selectors: String) throws -> Data {
    let html = """
      <style>
      \(selectors)
      </style>
      <pre><code class="hljs">
      \(text.trimmingCharacters(in: .whitespacesAndNewlines))
      </code></pre>
      """
    return html.data(using: .utf8) ?? Data()
  }

  private func attributedTextFromData(_ data: Data) throws -> AttributedString {
    let mutableString = try NSMutableAttributedString(
      data: data,
      options: [
        .documentType: NSAttributedString.DocumentType.html,
        .characterEncoding: String.Encoding.utf8.rawValue,
      ],
      documentAttributes: nil
    )
    mutableString.removeAttribute(
      .font,
      range: NSMakeRange(0, mutableString.length)
    )
    let range = NSRange(location: 0, length: mutableString.length - 1)
    let attributedString = mutableString.attributedSubstring(from: range)
    #if os(macOS)
      return try AttributedString(attributedString, including: \.appKit)
    #else
      return try AttributedString(attributedString, including: \.uiKit)
    #endif
  }
}
