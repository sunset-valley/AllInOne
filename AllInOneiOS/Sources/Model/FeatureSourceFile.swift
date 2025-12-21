import Foundation

/// Represents a source code file within a Feature directory
struct FeatureSourceFile: Identifiable, Hashable {
  var id: String { relativePath }

  /// File name, e.g. "BuildInTransitionView.swift"
  let fileName: String

  /// Relative path from FeatureSources directory, e.g. "Transitions/BuildInTransitionView.swift"
  let relativePath: String

  /// Programming language for syntax highlighting
  let language: HighlightLanguage

  var displayName: String { fileName }

  init(fileName: String, relativePath: String, language: HighlightLanguage = .swift) {
    self.fileName = fileName
    self.relativePath = relativePath
    self.language = language
  }
}
