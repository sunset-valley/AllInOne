import SwiftUI

@main
struct AllInOneiOSApp: App {
  let categoryManager = CategoryManager()
  let algorithmCategoryManager = AlgorithmCategoryManager()

  var body: some Scene {
    WindowGroup {
      MainTabView()
        .environment(categoryManager)
        .environment(algorithmCategoryManager)
    }
  }
}
