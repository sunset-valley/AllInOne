import Foundation
import SwiftUI

struct Feature: Hashable, Identifiable {
  enum Destination: Hashable {
    case buildInTransition
    case highlightSwift
    case fallback(title: String)

    /// Source code directory path relative to Features folder
    var sourceDirectory: String? {
      switch self {
      case .buildInTransition: return "Transitions"
      case .highlightSwift: return "HighlightSwift"
      case .fallback: return nil
      }
    }
  }

  var id = UUID()
  var title: String
  var destination: Destination
}
