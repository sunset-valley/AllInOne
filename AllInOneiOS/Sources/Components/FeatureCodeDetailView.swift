import SwiftUI

/// Displays source code content using CodeText with syntax highlighting
struct FeatureCodeDetailView: View {
  let file: FeatureSourceFile

  @State private var sourceCode: String = ""
  @State private var isLoading = true

  var body: some View {
    Group {
      if isLoading {
        ProgressView("Loading source code...")
      } else if sourceCode.isEmpty {
        ContentUnavailableView(
          "Unable to Load",
          systemImage: "exclamationmark.triangle",
          description: Text("Could not load the source code for this file.")
        )
      } else {
        ScrollView(.horizontal) {
          ScrollView(.vertical) {
            CodeText(sourceCode)
              .codeTextStyle(.plain)
              .codeTextColors(.theme(.xcode))
              .highlightLanguage(file.language)
              .padding()
          }
        }
      }
    }
    .navigationTitle(file.displayName)
    .navigationBarTitleDisplayMode(.inline)
    .task {
      sourceCode = FeatureSourceProvider.shared.readSourceContent(for: file) ?? ""
      isLoading = false
    }
  }
}

#Preview {
  NavigationStack {
    FeatureCodeDetailView(
      file: FeatureSourceFile(
        fileName: "Example.swift",
        relativePath: "Example/Example.swift"
      ))
  }
}
