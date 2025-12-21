import SwiftUI

/// Displays a list of source files for a given Feature
struct FeatureFileListView: View {
  let destination: Feature.Destination

  @State private var files: [FeatureSourceFile] = []
  @State private var isLoading = true

  var body: some View {
    Group {
      if isLoading {
        ProgressView("Loading files...")
      } else if files.isEmpty {
        ContentUnavailableView(
          "No Source Files",
          systemImage: "doc.text.magnifyingglass",
          description: Text("No source files found for this feature.")
        )
      } else {
        List(files) { file in
          NavigationLink(value: file) {
            Label {
              VStack(alignment: .leading, spacing: 4) {
                Text(file.displayName)
                  .font(.body)
                Text(file.relativePath)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            } icon: {
              Image(systemName: "swift")
                .foregroundStyle(.orange)
            }
          }
        }
      }
    }
    .navigationTitle("Source Files")
    .task {
      files = FeatureSourceProvider.shared.getSourceFiles(for: destination)
      isLoading = false
    }
  }
}

#Preview {
  NavigationStack {
    FeatureFileListView(destination: .buildInTransition)
  }
}
