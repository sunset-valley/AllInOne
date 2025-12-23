import SwiftUI

enum TabType: String, CaseIterable {
  case uiFeatures = "UI & Animation"
  case algorithms = "DSA"

  var icon: String {
    switch self {
    case .uiFeatures: return "sparkles.rectangle.stack"
    case .algorithms: return "cpu"
    }
  }

  var title: String { rawValue }
}
