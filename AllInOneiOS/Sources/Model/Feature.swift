import Foundation
import SwiftUI

struct Feature: Hashable, Identifiable {
    enum Destination: Hashable {
        case buildInTransition
        case pixel
        case navigationStack
        case tabView
        case scrollView
        case coreText
        case mvc
        case mvvmc
        case cleanArchitecture
        case redux
        case debugView
        case fictionReader
        case comicReader
        case cloudTags
        case fallback(title: String)
    }

    var id = UUID()
    var title: String
    var destination: Destination
}
