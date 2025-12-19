import Foundation

@Observable class CategoryManager {
    let categoies: [Category]
    
    init() {
        categoies = [
            .init(title: "Transitions & Animations", features: [
                .init(title: "Interactive Transition"),
                .init(title: "Pixel")
            ]),
            .init(title: "UI", features: [
                .init(title: "NavigationStack"),
                .init(title: "TabView"),
                .init(title: "ScrollView"),
                .init(title: "CoreText"),
            ]),
            .init(title: "Architecture", features: [
                .init(title: "MVC"),
                .init(title: "MVVM-C"),
                .init(title: "CleanArchtecture"),
                .init(title: "Redux"),
            ]),
            .init(title: "Receipt", features: [
                .init(title: "Debug View"),
                .init(title: "Fiction Reader"),
                .init(title: "Comit Reader"),
                .init(title: "Cloud Tags"),
            ]),
        ]
    }
}
