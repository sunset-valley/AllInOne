import SwiftUI

struct AlgorithmsView: View {
  @Environment(AlgorithmCategoryManager.self) var categoryManager: AlgorithmCategoryManager

  var body: some View {
    List {
      ForEach(categoryManager.categories, id: \.id) { category in
        Section(category.title) {
          ForEach(category.features, id: \.id) { feature in
            NavigationLink(value: feature.destination) {
              Text(feature.title)
            }
          }
        }
      }
    }
    .navigationTitle("Algorithms")
    .navigationDestination(for: AlgorithmFeature.Destination.self) { destination in
      switch destination {
        case .dataStructure(let type):
          getDataStructureDestination(type: type)
        default:
          AlgorithmPlaceholderView(destination: destination)
      }
    }
  }
  
  private func getDataStructureDestination(type: AlgorithmFeature.DataStructureType) -> some View {
    BinaryTreeExample()
  }
}

/// Placeholder view for algorithm details - to be implemented later
struct AlgorithmPlaceholderView: View {
  let destination: AlgorithmFeature.Destination

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "cpu")
        .font(.system(size: 60))
        .foregroundStyle(.secondary)

      Text(destinationTitle)
        .font(.title2)
        .fontWeight(.semibold)

      Text("Coming Soon...")
        .foregroundStyle(.secondary)
    }
    .navigationTitle(destinationTitle)
  }

  private var destinationTitle: String {
    switch destination {
    case .sorting(let type):
      return type.rawValue
    case .searching(let type):
      return type.rawValue
    case .dataStructure(let type):
      return type.rawValue
    case .fallback(let title):
      return title
    }
  }
}

#Preview {
  NavigationStack {
    AlgorithmsView()
  }
  .environment(AlgorithmCategoryManager())
}
