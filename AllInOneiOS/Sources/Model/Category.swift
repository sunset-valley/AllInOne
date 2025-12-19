import Foundation

struct Category {
    var `id` = UUID()
    var title: String
    
    var features: [Feature]
}
