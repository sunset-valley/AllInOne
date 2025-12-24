import Foundation
import SwiftUI

class AVLTreeNode {
  var val: Int
  var left: AVLTreeNode?
  var right: AVLTreeNode?
  var height: Int
  
  init(x: Int) {
    val = x
    height = 0
  }
}

class AVL {
  var root: AVLTreeNode?
  
  func height(node: AVLTreeNode?) -> Int {
    return node?.height ?? -1
  }
  
  func updateHeight(node: AVLTreeNode?) {
    node?.height = max(height(node: node?.left), height(node: node?.right)) + 1
  }
  
  func balanceFactor(node: AVLTreeNode?) -> Int {
    guard let node = node else { return 0}
    return height(node: node.left) - height(node: node.right)
  }
  
  func rightRotate(node: AVLTreeNode?) -> AVLTreeNode? {
    let child = node?.left
    let grandChild = child?.right
    child?.right = node
    node?.left = grandChild
    updateHeight(node: node)
    updateHeight(node: child)
    return child
  }
  
  func leftRotate(node: AVLTreeNode?) -> AVLTreeNode? {
    let child = node?.right
    let grandChild = child?.left
    child?.left = node
    node?.right = grandChild
    updateHeight(node: node)
    updateHeight(node: grandChild)
    return child
  }
  
  func rotate(node: AVLTreeNode?) -> AVLTreeNode? {
    let balanceFactor = balanceFactor(node: node)
    if balanceFactor > 1 {
      // 左偏
      if self.balanceFactor(node: node?.left) >= 0 {
        // right rotate
        return rightRotate(node: node)
      } else {
        node?.left = leftRotate(node: node)
        return rightRotate(node: node)
      }
      
    }
    
    // 右偏
    if balanceFactor < -1 {
      if self.balanceFactor(node: node?.right) <= 0 {
        return leftRotate(node: node)
      } else {
        node?.right = rightRotate(node: node?.right)
        return leftRotate(node: node)
      }
    }
    // 平衡树，无须旋转，直接返回
    return node
  }
  
  func insert(val: Int) {
    root = insertHelper(node: root, val: val)
  }
  
  func insertHelper(node: AVLTreeNode?, val: Int) -> AVLTreeNode? {
    guard let node = node else {
      return AVLTreeNode(x: val)
    }
    
    if val < node.val {
      node.left = insertHelper(node: node.left, val: val)
    } else if val > node.val {
      node.right = insertHelper(node: node.right, val: val)
    } else {
      return node
    }
    updateHeight(node: node)
    return rotate(node: node)
  }
  
  func remove(val: Int) {
    root = removeHelper(node: root, val: val)
  }
  
  func removeHelper(node: AVLTreeNode?, val: Int) -> AVLTreeNode? {
    guard let node = node else {
      return nil
    }
    var n: AVLTreeNode? = node
    
    if val < node.val {
      node.left = removeHelper(node: node.left, val: val)
    } else if val > node.val {
      node.right = removeHelper(node: node.right, val: val)
    } else {
      if node.left == nil || node.right == nil {
        let child = node.left ?? node.right
        if child == nil {
          return nil
        }
        // 直接点数量 1, 直接删除 node
        else {
          n = child
        }
      }
      // 子节点数量2,
      else {
        var temp = node.right
        while temp?.left != nil {
          temp = temp?.left
        }
        node.right = removeHelper(node: node.right, val: val)
        node.val = temp!.val
      }
    }
    updateHeight(node: n)
    return n
  }
}

extension AVL {
  func description() -> String {
    guard let root = root else {
      return "(empty)"
    }
    let (lines, _, _, _) = buildVerticalTree(root)
    return lines.joined(separator: "\n")
  }
  
  // 返回值类型: (lines: [String], width: Int, height: Int, center: Int)
  // lines: 当前子树的字符串数组
  // width: 当前块的总宽度
  // height: 当前块的总高度
  // center: 根节点值在第一行字符串中的中心位置索引（用于对齐父节点）
  private func buildVerticalTree(_ node: AVLTreeNode) -> ([String], Int, Int, Int) {
    let valStr = "\(node.val)"
    let valWidth = valStr.count
    
    // --- 情况 1: 叶子节点 ---
    if node.left == nil && node.right == nil {
      return ([valStr], valWidth, 1, valWidth / 2)
    }
    
    // --- 情况 2: 只有左子树 ---
    if let left = node.left, node.right == nil {
      let (leftLines, leftWidth, leftHeight, leftCenter) = buildVerticalTree(left)
      
      // 计算当前节点相对于左子树的位置
      // 父节点应该稍微向右偏移，以便连线看起来自然
      let padding = 1
      let width = max(valWidth + padding, leftWidth)
      // 根节点的中心位置
      let center = leftCenter + padding
      
      var lines: [String] = []
      
      // 1. 添加当前节点值 (补齐空格)
      let rootLine = String(repeating: " ", count: leftCenter + 1) + valStr
      lines.append(rootLine.padding(toLength: width, withPad: " ", startingAt: 0))
      
      // 2. 添加连线 ( / )
      let connector = String(repeating: " ", count: leftCenter) + "/"
      lines.append(connector.padding(toLength: width, withPad: " ", startingAt: 0))
      
      // 3. 添加左子树的所有行
      for line in leftLines {
        lines.append(line.padding(toLength: width, withPad: " ", startingAt: 0))
      }
      
      return (lines, width, leftHeight + 2, center)
    }
    
    // --- 情况 3: 只有右子树 ---
    if node.left == nil, let right = node.right {
      let (rightLines, rightWidth, rightHeight, rightCenter) = buildVerticalTree(right)
      
      let padding = 1
      let width = max(valWidth + padding, rightWidth)
      // 根节点在连线左侧
      let center = valWidth / 2
      
      var lines: [String] = []
      
      // 1. 添加当前节点值
      let rootLine = valStr + String(repeating: " ", count: rightCenter + 1)
      lines.append(rootLine.padding(toLength: width, withPad: " ", startingAt: 0))
      
      // 2. 添加连线 ( \ )
      let connectorOffset = valWidth // 简单的偏移计算
      let connector = String(repeating: " ", count: connectorOffset) + "\\"
      lines.append(connector.padding(toLength: width, withPad: " ", startingAt: 0))
      
      // 3. 添加右子树的所有行
      for line in rightLines {
        // 右子树需要整体向右偏移以避开根节点区域
        lines.append(String(repeating: " ", count: valWidth + 1) + line)
      }
      
      // 更新宽度，因为上面的 padding 可能会改变实际宽度
      let newWidth = (valWidth + 1) + rightWidth
      return (lines, newWidth, rightHeight + 2, center)
    }
    
    // --- 情况 4: 左右子树都有 (最复杂的情况) ---
    if let left = node.left, let right = node.right {
      let (leftLines, leftWidth, leftHeight, leftCenter) = buildVerticalTree(left)
      let (rightLines, rightWidth, rightHeight, rightCenter) = buildVerticalTree(right)
      
      // 两个子树之间的最小间距
      let spacing = 3
      
      // 计算总宽度
      let width = leftWidth + spacing + rightWidth
      
      // 计算新的根节点应该放在哪里
      // 我们希望根节点位于左子树中心和右子树中心的中点
      // 左子树中心在全局坐标的位置 = leftCenter
      // 右子树中心在全局坐标的位置 = leftWidth + spacing + rightCenter
      let rootCenterPos = (leftCenter + (leftWidth + spacing + rightCenter)) / 2
      
      var lines: [String] = []
      
      // 1. 构建根节点行
      // 确保 valStr 居中于 rootCenterPos
      let rootOffset = max(0, rootCenterPos - valWidth / 2)
      let rootLine = String(repeating: " ", count: rootOffset) + valStr
      lines.append(rootLine.padding(toLength: width, withPad: " ", startingAt: 0))
      
      // 2. 构建连线行 ( /   \ )
      // 左连线位置: leftCenter
      // 右连线位置: leftWidth + spacing + rightCenter
      var connectorLine = Array(String(repeating: " ", count: width))
      if leftCenter < width { connectorLine[leftCenter] = "/" }
      let rightConnectorPos = leftWidth + spacing + rightCenter
      if rightConnectorPos < width { connectorLine[rightConnectorPos] = "\\" }
      
      // 可选：添加中间的连接符 (如:  /-----\ ) 增加美观度，这里只用简单空格
      // 如果需要横杠，可以在 leftCenter+1 到 rightConnectorPos-1 之间填充 "_"
      
      lines.append(String(connectorLine))
      
      // 3. 合并左右子树的行
      let maxSubTreeHeight = max(leftHeight, rightHeight)
      for i in 0..<maxSubTreeHeight {
        var line = ""
        
        // 左部分
        if i < leftLines.count {
          line += leftLines[i]
        } else {
          line += String(repeating: " ", count: leftWidth)
        }
        
        // 间隔
        line += String(repeating: " ", count: spacing)
        
        // 右部分
        if i < rightLines.count {
          line += rightLines[i]
        } else {
          line += String(repeating: " ", count: rightWidth)
        }
        
        lines.append(line)
      }
      
      return (lines, width, lines.count, rootCenterPos)
    }
    
    return ([], 0, 0, 0)
  }
}
