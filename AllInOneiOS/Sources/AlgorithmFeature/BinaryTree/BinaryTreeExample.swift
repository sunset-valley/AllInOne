import SwiftUI

struct BinaryTreeExample: View {
  let binaryTree = BinaryTree()
  let arrayBinaryTree = ArrayBinaryTree(arr: [1,2,3,4,5,6,7])
  let avl = AVL()
  
  @State private var bfsResult1: [Int] = []
  @State private var preResult1: [Int] = []
  @State private var inResult1: [Int] = []
  @State private var postResult1: [Int] = []
  
  @State private var bfsResult2: [Int] = []
  @State private var preResult2: [Int] = []
  @State private var inResult2: [Int] = []
  @State private var postResult2: [Int] = []
  
  @State private var avlResult: [String] = []
  @State private var avlDeleteVal: Int = 0


  var body: some View {
    ScrollView {
      GroupBox("BinaryTree") {
        Text(binaryTree.description())
          .fontDesign(.monospaced)
        
        Text(arrayBinaryTree.description())
          .fontDesign(.monospaced)
      }
      
      GroupBox("Breadth-First Search (BFS)") {
        Button("Get Result") {
          guard let root = binaryTree.root else {
            return
          }
          bfsResult1 = binaryTree.levelOrder(root: root)
          bfsResult2 = arrayBinaryTree.levelOrder()
        }
        
        Text("BinaryTree: \(bfsResult1.compactMap({ "\($0)" }).joined(separator: ", "))")
        Text("ArrayBinaryTree: \(bfsResult2.compactMap({ "\($0)" }).joined(separator: ", "))")
        if !bfsResult1.isEmpty {
          Text(bfsResult1 == bfsResult2 ? "Success" : "Fail")
            .foregroundStyle(bfsResult1 == bfsResult2 ? .green : .red)
        }
      }
      
      GroupBox("depth-First Search (DFS) 1") {
        VStack(spacing: 16) {
          VStack {
            Button("Get PreOrder Result") {
              var l: [Int] = []
              binaryTree.preOrder(root: binaryTree.root, list: &l)
              preResult1 = l
              preResult2 = arrayBinaryTree.preOrder()
            }
            Text("BinaryTree Result: \(preResult1.compactMap({ "\($0)" }).joined(separator: ", "))")
            Text("ArrayBinaryTree Result: \(preResult2.compactMap({ "\($0)" }).joined(separator: ", "))")
            if !preResult1.isEmpty {
              Text(preResult1 == preResult2 ? "Success" : "Fail")
                .foregroundStyle(preResult1 == preResult2 ? .green : .red)
            }
          }
          
          VStack {
            Button("Get InOrder Result") {
              var l: [Int] = []
              binaryTree.inOrder(root: binaryTree.root, list: &l)
              inResult1 = l
              inResult2 = arrayBinaryTree.inOrder()
            }
            Text("BinaryTree Result: \(inResult1.compactMap({ "\($0)" }).joined(separator: ", "))")
            Text("ArrayBinaryTree Result: \(inResult2.compactMap({ "\($0)" }).joined(separator: ", "))")
            if !inResult1.isEmpty {
              Text(inResult1 == inResult2 ? "Success" : "Fail")
                .foregroundStyle(inResult1 == inResult2 ? .green : .red)
            }
          }
          
          
          VStack {
            Button("Get PostOrder Result") {
              var l: [Int] = []
              binaryTree.postOrder(root: binaryTree.root, list: &l)
              postResult1 = l
              postResult2 = arrayBinaryTree.postOrder()
            }
            Text("BinaryTree Result: \(postResult1.compactMap({ "\($0)" }).joined(separator: ", "))")
            Text("ArrayBinaryTree Result: \(postResult2.compactMap({ "\($0)" }).joined(separator: ", "))")
            if !postResult1.isEmpty {
              Text(postResult1 == postResult2 ? "Success" : "Fail")
                .foregroundStyle(postResult1 == postResult2 ? .green : .red)
            }
          }
        }
      }
      
      GroupBox("AVL") {
        HStack {
          Button("Insert") {
            avl.insert(val: Int.random(in: 0..<100))
            avlResult.append(avl.description())
          }
          
          
          Stepper(value: $avlDeleteVal) {
            Button {
              avl.remove(val: avlDeleteVal)
              avlResult.append(avl.description())
            } label: {
              Text("Delete Val:\(avlDeleteVal)")
            }
          }
        }
        
        ForEach(avlResult.enumerated(), id: \.offset) { index, value in
          HStack {
            Text("\(index)")
            Text(value)
              .frame(maxWidth: .infinity)
          }
          Divider()
        }
      }
    }
  }
}

#Preview {
  BinaryTreeExample()
}
