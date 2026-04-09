import Foundation
import React

@objc(DualCameraViewManager)
class DualCameraViewManager: RCTViewManager {
  
  override func view() -> UIView! {
    if #available(iOS 13.0, *) {
        return DualCameraView()
    } else {
        return UIView()
    }
  }
  
  override static func requiresMainQueueSetup() -> Bool {
    return true
  }
}
