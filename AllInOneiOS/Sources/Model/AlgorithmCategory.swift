import Foundation

struct AlgorithmCategory: Identifiable {
  var id = UUID()
  var title: String
  var features: [AlgorithmFeature]
}
