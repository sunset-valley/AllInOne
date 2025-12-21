import SwiftUI
import UIKit

/// Utility to control device orientation programmatically
enum OrientationManager {
  /// Force device to rotate to a specific orientation
  static func rotate(to orientation: UIInterfaceOrientationMask) {
    if #available(iOS 16.0, *) {
      guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
        return
      }
      windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
      windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    } else {
      let orientationValue: UIInterfaceOrientation =
        switch orientation {
        case .landscapeRight: .landscapeRight
        case .landscapeLeft: .landscapeLeft
        case .portrait: .portrait
        default: .portrait
        }
      UIDevice.current.setValue(orientationValue.rawValue, forKey: "orientation")
    }
  }

  /// Lock to portrait only
  static func lockPortrait() {
    rotate(to: .portrait)
  }

  /// Rotate to landscape
  static func rotateLandscape() {
    rotate(to: .landscapeRight)
  }
}
