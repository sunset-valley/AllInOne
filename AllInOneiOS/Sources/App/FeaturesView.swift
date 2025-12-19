import SwiftUI

struct FeaturesView: View {
    @Environment(CategoryManager.self) var categoryManager: CategoryManager
    
    var body: some View {
        List {
            ForEach(categoryManager.categoies, id: \.id) { category in
                Section(category.title) {
                    ForEach(category.features, id: \.id) { feature in
                        NavigationLink(value: feature) {
                            Text(feature.title)
                        }
                    }
                }
            }
        }
        .navigationTitle("Features")
        .navigationDestination(for: Feature.self) { feature in
            if feature.title == "Interactive Transition" {
                BuildInTransitionView()
            } else {
                Text(feature.title)
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
