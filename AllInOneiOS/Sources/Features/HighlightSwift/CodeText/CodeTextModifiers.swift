extension CodeText {
  /// Sets the code text style for this code text.
  public func codeTextStyle<S>(_ style: S) -> CodeText where S: CodeTextStyle {
    var content = self
    content.style = style
    return content
  }

  /// Sets the highlight color theme for this code text.
  public func codeTextColors(_ colors: CodeTextColors) -> CodeText {
    var content = self
    content.colors = colors
    return content
  }

  /// Sets the language detection mode for this code text.
  /// See also `highlightLanguage(_:)` to simply set a language.
  public func highlightMode(_ mode: HighlightMode) -> CodeText {
    var content = self
    content.mode = mode
    return content
  }

  /// Sets the language for this code text.
  /// Equivalent to `.highlightMode(.language(...))`
  public func highlightLanguage(_ language: HighlightLanguage) -> CodeText {
    var content = self
    content.mode = .language(language)
    return content
  }

  /// Adds an action to perform after the text has been highlighted or an error occurs.
  public func onHighlightResult(_ perform: @escaping ((Result<HighlightResult, Error>) -> Void))
    -> CodeText
  {
    var content = self
    content.result = perform
    return content
  }
}
