import Foundation

struct AlgorithmFeature: Hashable, Identifiable {
  enum Destination: Hashable {
    case sorting(SortingType)
    case searching(SearchingType)
    case dataStructure(DataStructureType)
    case fallback(title: String)

    /// Source code directory path relative to Features folder
    var sourceDirectory: String? {
      switch self {
      case .sorting(let type):
        return "Algorithms/Sorting/\(type.rawValue)"
      case .searching(let type):
        return "Algorithms/Searching/\(type.rawValue)"
      case .dataStructure(let type):
        return "Algorithms/DataStructures/\(type.rawValue)"
      case .fallback:
        return nil
      }
    }
  }

  enum SortingType: String, CaseIterable, Hashable {
    case bubbleSort = "BubbleSort"
    case quickSort = "QuickSort"
    case mergeSort = "MergeSort"
    case heapSort = "HeapSort"
  }

  enum SearchingType: String, CaseIterable, Hashable {
    case binarySearch = "BinarySearch"
    case dfs = "DFS"
    case bfs = "BFS"
  }

  enum DataStructureType: String, CaseIterable, Hashable {
    case binaryTree = "BinaryTree"
    case graph = "Graph"
  }

  var id = UUID()
  var title: String
  var destination: Destination
}
