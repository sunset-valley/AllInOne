import Foundation

@Observable class AlgorithmCategoryManager {
  let categories: [AlgorithmCategory]

  init() {
    categories = [
//      .init(
//        title: "Sorting",
//        features: [
//          .init(title: "Bubble Sort", destination: .sorting(.bubbleSort)),
//          .init(title: "Quick Sort", destination: .sorting(.quickSort)),
//          .init(title: "Merge Sort", destination: .sorting(.mergeSort)),
//          .init(title: "Heap Sort", destination: .sorting(.heapSort)),
//        ]),
//      .init(
//        title: "Searching",
//        features: [
//          .init(title: "Binary Search", destination: .searching(.binarySearch)),
//          .init(title: "DFS", destination: .searching(.dfs)),
//          .init(title: "BFS", destination: .searching(.bfs)),
//        ]),
      .init(
        title: "Data Structures",
        features: [
          .init(title: "Binary Tree", destination: .dataStructure(.binaryTree)),
          .init(title: "Graph", destination: .dataStructure(.graph)),
        ]),
    ]
  }
}
