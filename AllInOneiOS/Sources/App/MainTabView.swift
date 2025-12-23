import SwiftUI

struct MainTabView: View {
  @State private var selectedTab: TabType = .uiFeatures

  var body: some View {
    TabView(selection: $selectedTab) {
      NavigationStack {
        FeaturesView()
      }
      .tabItem {
        Label(TabType.uiFeatures.title, systemImage: TabType.uiFeatures.icon)
      }
      .tag(TabType.uiFeatures)

      NavigationStack {
        AlgorithmsView()
      }
      .tabItem {
        Label(TabType.algorithms.title, systemImage: TabType.algorithms.icon)
      }
      .tag(TabType.algorithms)
    }
  }
}

#Preview {
  MainTabView()
    .environment(CategoryManager())
    .environment(AlgorithmCategoryManager())
}
