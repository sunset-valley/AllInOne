import Foundation

@Observable class CategoryManager {
    let categories: [Category]
    
    init() {
        categories = [
            .init(title: "Transitions & Animations", features: [
                .init(title: "Build-in Transition", destination: .buildInTransition),
                .init(title: "Pixel", destination: .pixel)
            ]),
            .init(title: "UI", features: [
                .init(title: "NavigationStack", destination: .navigationStack),
                .init(title: "TabView", destination: .tabView),
                .init(title: "ScrollView", destination: .scrollView),
                .init(title: "CoreText", destination: .coreText),
            ]),
            .init(title: "Architecture", features: [
                .init(title: "MVC", destination: .mvc),
                .init(title: "MVVM-C", destination: .mvvmc),
                .init(title: "CleanArchitecture", destination: .cleanArchitecture),
                .init(title: "Redux", destination: .redux),
            ]),
            .init(title: "Receipt", features: [
                .init(title: "Debug View", destination: .debugView),
                .init(title: "Fiction Reader", destination: .fictionReader),
                .init(title: "Comic Reader", destination: .comicReader),
                .init(title: "Cloud Tags", destination: .cloudTags),
            ]),
        ]
    }
}
