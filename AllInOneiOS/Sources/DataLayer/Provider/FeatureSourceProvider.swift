import Foundation

/// Provider for discovering and reading Feature source code files from Bundle resources
struct FeatureSourceProvider {
  static let shared = FeatureSourceProvider()

  private let fileManager = FileManager.default

  /// Get all source files for a given Feature destination
  func getSourceFiles(for destination: Feature.Destination) -> [FeatureSourceFile] {
    guard let directory = destination.sourceDirectory else { return [] }
    guard let bundlePath = Bundle.main.resourcePath else { return [] }

    let sourcesPath = bundlePath + "/FeatureSources/" + directory
    return listSwiftFiles(at: sourcesPath, basePath: directory)
  }

  /// Read the content of a source file
  func readSourceContent(for file: FeatureSourceFile) -> String? {
    guard let bundlePath = Bundle.main.resourcePath else { return nil }
    let filePath = bundlePath + "/FeatureSources/" + file.relativePath
    return try? String(contentsOfFile: filePath, encoding: .utf8)
  }

  /// Recursively list all Swift files in a directory
  private func listSwiftFiles(at path: String, basePath: String) -> [FeatureSourceFile] {
    var files: [FeatureSourceFile] = []

    guard let contents = try? fileManager.contentsOfDirectory(atPath: path) else {
      return files
    }

    for item in contents.sorted() {
      let fullPath = path + "/" + item
      var isDirectory: ObjCBool = false

      guard fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory) else {
        continue
      }

      if isDirectory.boolValue {
        // Recursively scan subdirectories
        let subPath = basePath + "/" + item
        files.append(contentsOf: listSwiftFiles(at: fullPath, basePath: subPath))
      } else if item.hasSuffix(".swift") || item.hasSuffix(".metal") {
        let relativePath = basePath + "/" + item
        let language = detectLanguage(for: item)
        files.append(
          FeatureSourceFile(
            fileName: item,
            relativePath: relativePath,
            language: language
          ))
      }
    }

    return files
  }

  /// Detect the programming language based on file extension
  private func detectLanguage(for fileName: String) -> HighlightLanguage {
    let ext = (fileName as NSString).pathExtension.lowercased()
    switch ext {
    case "swift": return .swift
    case "metal": return .cPlusPlus
    case "js": return .javaScript
    case "ts": return .typeScript
    case "py": return .python
    case "json": return .json
    case "html": return .html
    case "css": return .css
    default: return .swift
    }
  }
}
