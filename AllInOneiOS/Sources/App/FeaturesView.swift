import SwiftUI

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
            switch destination {
            case .buildInTransition:
                BuildInTransitionView()
            case .fallback(let title):
                Text(title)
            default:
                // Placeholder for other destinations
                Text("Not Implemented")
            }
        }
    }
}

#Preview {
    NavigationStack {
        FeaturesView()
    }
    .environment(CategoryManager())
}
