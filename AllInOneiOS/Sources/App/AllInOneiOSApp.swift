import SwiftUI

@main
struct AllInOneiOSApp: App {
    let categoryManager = CategoryManager()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                FeaturesView()
            }
            .environment(categoryManager)
        }
    }
}
