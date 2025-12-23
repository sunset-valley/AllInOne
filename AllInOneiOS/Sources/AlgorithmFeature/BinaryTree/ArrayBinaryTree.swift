import Foundation
import SwiftUI

class ArrayBinaryTree {
  private var tree: [Int?]
  
  /* 构造方法 */
  init(arr: [Int?]) {
    tree = arr
  }
  
  /* 列表容量 */
  func size() -> Int {
    tree.count
  }
  
  /* 获取索引为 i 节点的值 */
  func val(i: Int) -> Int? {
    // 若索引越界，则返回 null ，代表空位
    if i < 0 || i >= size() {
      return nil
    }
    return tree[i]
  }
  
  /* 获取索引为 i 节点的左子节点的索引 */
  func left(i: Int) -> Int {
    2 * i + 1
  }
  
  /* 获取索引为 i 节点的右子节点的索引 */
  func right(i: Int) -> Int {
    2 * i + 2
  }
  
  /* 获取索引为 i 节点的父节点的索引 */
  func parent(i: Int) -> Int {
    (i - 1) / 2
  }
  
  func description() -> String {
    let (lines, _, _, _) = buildVerticalTree(0)
    return lines.joined(separator: "\n")
  }
  
  // 返回值类型: (lines: [String], width: Int, height: Int, center: Int)
  // lines: 当前子树的字符串数组
  // width: 当前块的总宽度
  // height: 当前块的总高度
  // center: 根节点值在第一行字符串中的中心位置索引（用于对齐父节点）
  private func buildVerticalTree(_ index: Int) -> ([String], Int, Int, Int) {
    let valStr = "\(val(i: index) != nil ? "\(val(i: index)!)" : "null")"
    let valWidth = valStr.count
    
    // --- 情况 1: 叶子节点 ---
    if val(i:left(i: index)) == nil && val(i:right(i: index)) == nil {
      return ([valStr], valWidth, 1, valWidth / 2)
    }
    
    // --- 情况 2: 只有左子树 ---
    if let left = val(i:left(i: index)), val(i:right(i: index)) == nil {
      let (leftLines, leftWidth, leftHeight, leftCenter) = buildVerticalTree(self.left(i: index))
      
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
    if val(i:left(i: index)) == nil, let right = val(i:right(i: index)) {
      let (rightLines, rightWidth, rightHeight, rightCenter) = buildVerticalTree(self.right(i: index))
      
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
    if let left = val(i:left(i: index)), let right = val(i:right(i: index)) {
      let (leftLines, leftWidth, leftHeight, leftCenter) = buildVerticalTree(self.left(i: index))
      let (rightLines, rightWidth, rightHeight, rightCenter) = buildVerticalTree(self.right(i: index))
      
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
  
  /* 层序遍历 */
  func levelOrder() -> [Int] {
    var res: [Int] = []
    // 直接遍历数组
    for i in 0 ..< size() {
      if let val = val(i: i) {
        res.append(val)
      }
    }
    return res
  }
  
  /* 深度优先遍历 */
  private func dfs(i: Int, order: String, res: inout [Int]) {
    // 若为空位，则返回
    guard let val = val(i: i) else {
      return
    }
    // 前序遍历
    if order == "pre" {
      res.append(val)
    }
    dfs(i: left(i: i), order: order, res: &res)
    // 中序遍历
    if order == "in" {
      res.append(val)
    }
    dfs(i: right(i: i), order: order, res: &res)
    // 后序遍历
    if order == "post" {
      res.append(val)
    }
  }
  
  /* 前序遍历 */
  func preOrder() -> [Int] {
    var res: [Int] = []
    dfs(i: 0, order: "pre", res: &res)
    return res
  }
  
  /* 中序遍历 */
  func inOrder() -> [Int] {
    var res: [Int] = []
    dfs(i: 0, order: "in", res: &res)
    return res
  }
  
  /* 后序遍历 */
  func postOrder() -> [Int] {
    var res: [Int] = []
    dfs(i: 0, order: "post", res: &res)
    return res
  }
}

#Preview {
  BinaryTreeExample()
}
