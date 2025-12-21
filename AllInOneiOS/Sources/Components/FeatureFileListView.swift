import SwiftUI

/// A node in the directory tree structure
private enum FileTreeNode: Identifiable {
  case directory(name: String, children: [FileTreeNode])
  case file(FeatureSourceFile)

  var id: String {
    switch self {
    case .directory(let name, _): return "dir:\(name)"
    case .file(let file): return file.id
    }
  }

  var name: String {
    switch self {
    case .directory(let name, _): return name
    case .file(let file): return file.fileName
    }
  }
}

/// Displays a list of source files for a given Feature in a directory tree structure
struct FeatureFileListView: View {
  let destination: Feature.Destination

  @State private var files: [FeatureSourceFile] = []
  @State private var isLoading = true
  @State private var expandedDirectories: Set<String> = []

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
        List {
          ForEach(buildTree()) { node in
            FileTreeRow(node: node, expandedDirectories: $expandedDirectories)
          }
        }
        .listStyle(.sidebar)
      }
    }
    .navigationTitle("Source Files")
    .task {
      files = FeatureSourceProvider.shared.getSourceFiles(for: destination)
      // Expand all directories by default
      expandedDirectories = Set(collectDirectoryNames(from: buildTree()))
      isLoading = false
    }
  }

  /// Build a tree structure from flat file list
  private func buildTree() -> [FileTreeNode] {
    var root: [String: Any] = [:]

    for file in files {
      let components = file.relativePath.split(separator: "/").map(String.init)
      insertIntoTree(&root, components: components, file: file)
    }

    return buildNodes(from: root)
  }

  private func insertIntoTree(
    _ tree: inout [String: Any], components: [String], file: FeatureSourceFile
  ) {
    guard !components.isEmpty else { return }

    if components.count == 1 {
      // This is a file
      tree[components[0]] = file
    } else {
      // This is a directory path
      let dirName = components[0]
      var subTree = (tree[dirName] as? [String: Any]) ?? [:]
      insertIntoTree(&subTree, components: Array(components.dropFirst()), file: file)
      tree[dirName] = subTree
    }
  }

  private func buildNodes(from tree: [String: Any]) -> [FileTreeNode] {
    var nodes: [FileTreeNode] = []

    let sortedKeys = tree.keys.sorted { key1, key2 in
      let isDir1 = tree[key1] is [String: Any]
      let isDir2 = tree[key2] is [String: Any]
      if isDir1 != isDir2 {
        return isDir1  // Directories first
      }
      return key1 < key2
    }

    for key in sortedKeys {
      if let subTree = tree[key] as? [String: Any] {
        let children = buildNodes(from: subTree)
        nodes.append(.directory(name: key, children: children))
      } else if let file = tree[key] as? FeatureSourceFile {
        nodes.append(.file(file))
      }
    }

    return nodes
  }

  private func collectDirectoryNames(from nodes: [FileTreeNode]) -> [String] {
    var names: [String] = []
    for node in nodes {
      if case .directory(let name, let children) = node {
        names.append("dir:\(name)")
        names.append(contentsOf: collectDirectoryNames(from: children))
      }
    }
    return names
  }
}

/// A row in the file tree, handling both directories and files
private struct FileTreeRow: View {
  let node: FileTreeNode
  @Binding var expandedDirectories: Set<String>

  var body: some View {
    switch node {
    case .directory(let name, let children):
      DisclosureGroup(
        isExpanded: Binding(
          get: { expandedDirectories.contains(node.id) },
          set: { isExpanded in
            if isExpanded {
              expandedDirectories.insert(node.id)
            } else {
              expandedDirectories.remove(node.id)
            }
          }
        )
      ) {
        ForEach(children) { child in
          FileTreeRow(node: child, expandedDirectories: $expandedDirectories)
        }
      } label: {
        Label(name, systemImage: "folder.fill")
          .foregroundStyle(.blue)
      }

    case .file(let file):
      NavigationLink(value: file) {
        Label {
          Text(file.fileName)
            .font(.body)
        } icon: {
          Image(systemName: "swift")
            .foregroundStyle(.orange)
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    FeatureFileListView(destination: .buildInTransition)
  }
}
