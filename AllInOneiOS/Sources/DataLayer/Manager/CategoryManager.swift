import Foundation

@Observable class CategoryManager {
  let categories: [Category]

  init() {
    categories = [
      .init(
        title: "Transitions & Animations",
        features: [
          .init(title: "Build-in Transition", destination: .buildInTransition)
        ]),
      .init(
        title: "Respect Open Source",
        features: [
          .init(title: "HighlightSwift", destination: .highlightSwift)
        ]),
      .init(
        title: "Metal & Graphics",
        features: [
          .init(title: "Particle Demo", destination: .particleDemo)
        ]),
    ]
  }
}
