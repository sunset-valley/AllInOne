import SwiftUI

/// Wrapper for navigating to source code view
struct SourceCodeNavigation: Hashable {
  let destination: Feature.Destination
}

struct FeaturesView: View {
  @Environment(CategoryManager.self) var categoryManager: CategoryManager

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
    .navigationTitle("Features")
    .navigationDestination(for: Feature.Destination.self) { destination in
      Group {
        switch destination {
        case .buildInTransition:
          BuildInTransitionView()
        case .particleDemo:
          ParticleView()
        case .highlightSwift, .fallback:
          Text("Feature: \(String(describing: destination))")
        }
      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          NavigationLink(value: SourceCodeNavigation(destination: destination)) {
            Image(systemName: "doc.text")
          }
        }
      }
    }
    .navigationDestination(for: SourceCodeNavigation.self) { navigation in
      FeatureFileListView(destination: navigation.destination)
    }
    .navigationDestination(for: FeatureSourceFile.self) { file in
      FeatureCodeDetailView(file: file)
    }
  }
}

#Preview {
  NavigationStack {
    FeaturesView()
  }
  .environment(CategoryManager())
}
