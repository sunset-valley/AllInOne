import SwiftUI

typealias CodeTextMode = HighlightMode

/// A convenience wrapper for converting code strings to attributed strings with syntax highlighting.
public struct CodeText {
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.highlight) var highlight: Highlight

  @State internal var highlightTask: Task<Void, Never>?
  @State var highlightResult: HighlightResult?

  private let text: String
  var mode: CodeTextMode = .automatic
  var style: CodeTextStyle = .plain
  var colors: CodeTextColors = .theme(.xcode)

  var result: ((Result<HighlightResult, Error>) -> Void)?

  public init(_ text: String, result: HighlightResult? = nil) {
    self.text = text
    self._highlightResult = .init(wrappedValue: result)
  }

  var attributedText: AttributedString {
    highlightResult?.attributedText ?? AttributedString(stringLiteral: text)
  }

  func highlightText(
    mode: HighlightMode? = nil,
    colors: CodeTextColors? = nil,
    colorScheme: ColorScheme? = nil
  ) async {
    let text = self.text
    let mode = mode ?? self.mode
    let colors = colors ?? self.colors
    let scheme = colorScheme ?? self.colorScheme
    let schemeColors = scheme == .dark ? colors.dark : colors.light
    do {
      let highlightResult = try await highlight.process(text, mode: mode, colors: schemeColors)
      self.highlightResult = highlightResult
      result?(.success(highlightResult))
    } catch {
      result?(.failure(error))
    }
  }
}
