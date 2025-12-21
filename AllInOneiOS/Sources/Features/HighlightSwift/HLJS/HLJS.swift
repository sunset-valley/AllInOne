import JavaScriptCore

final actor HLJS {
  private var _hljs: JSValue?
  private var hljs: JSValue? {
    return try? load()
  }

  func highlight(_ text: String, mode: HighlightMode) throws -> HLJSResult {
    switch mode {
    case .automatic:
      return try highlightAuto(text)
    case .languageAlias(let language):
      return try highlight(text, language: language, ignoreIllegals: false)
    case .languageAliasIgnoreIllegal(let language):
      return try highlight(text, language: language, ignoreIllegals: true)
    case .language(let language):
      return try highlight(text, language: language.alias, ignoreIllegals: false)
    case .languageIgnoreIllegal(let language):
      return try highlight(text, language: language.alias, ignoreIllegals: true)
    }
  }

  private func load() throws -> JSValue {
    if let _hljs {
      return _hljs
    }
    guard let context = JSContext() else {
      throw HLJSError.contextIsNil
    }
    let highlightPath = Bundle.main.path(forResource: "highlight.min", ofType: "js")
    guard let highlightPath else {
      throw HLJSError.fileNotFound
    }
    let highlightScript = try String(contentsOfFile: highlightPath, encoding: .utf8)
    context.evaluateScript(highlightScript)
    guard let hljs = context.objectForKeyedSubscript("hljs") else {
      throw HLJSError.hljsNotFound
    }
    self._hljs = hljs
    return hljs
  }

  private func highlight(_ text: String, language: String, ignoreIllegals: Bool) throws
    -> HLJSResult
  {
    let languageOptions: [String: Any] = [
      "language": language,
      "ignoreIllegals": ignoreIllegals,
    ]
    let result = hljs?.invokeMethod("highlight", withArguments: [text, languageOptions])
    return try highlightResult(result)
  }

  private func highlightAuto(_ text: String) throws -> HLJSResult {
    let result = hljs?.invokeMethod("highlightAuto", withArguments: [text])
    return try highlightResult(result)
  }

  private func highlightResult(_ result: JSValue?) throws -> HLJSResult {
    guard let result else {
      throw HLJSError.valueNotFound
    }
    let illegal = result.objectForKeyedSubscript("illegal").toBool()
    let relevance = result.objectForKeyedSubscript("relevance").toInt32()
    guard let value = result.objectForKeyedSubscript("value").toString(),
      let language = result.objectForKeyedSubscript("language").toString()
    else {
      throw HLJSError.valueNotFound
    }
    return HLJSResult(value: value, illegal: illegal, language: language, relevance: relevance)
  }
}
