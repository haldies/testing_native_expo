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
  
  @objc func setIsDualMode(_ node: NSNumber, dual: Bool) {
    self.bridge.uiManager.addUIBlock { (uiManager, viewRegistry) in
      let view = viewRegistry?[node] as? DualCameraView
      view?.setIsDualMode(dual)
    }
  }

  @objc func toggleRecording(_ node: NSNumber) {
    self.bridge.uiManager.addUIBlock { (uiManager, viewRegistry) in
        let view = viewRegistry?[node] as? DualCameraView
        view?.toggleRecording()
    }
  }

  @objc func flipCamera(_ node: NSNumber) {
    self.bridge.uiManager.addUIBlock { (uiManager, viewRegistry) in
        let view = viewRegistry?[node] as? DualCameraView
        view?.flipCamera()
    }
  }

  @objc func setFPS(_ node: NSNumber, fps: NSNumber) {
    self.bridge.uiManager.addUIBlock { (uiManager, viewRegistry) in
        let view = viewRegistry?[node] as? DualCameraView
        view?.setFPS(fps.intValue)
    }
  }

  @objc func setResolution(_ node: NSNumber, res: NSString) {
    self.bridge.uiManager.addUIBlock { (uiManager, viewRegistry) in
        let view = viewRegistry?[node] as? DualCameraView
        view?.setResolution(res as String)
    }
  }

  @objc func setIsMirrored(_ node: NSNumber, mirrored: Bool) {
    self.bridge.uiManager.addUIBlock { (uiManager, viewRegistry) in
        let view = viewRegistry?[node] as? DualCameraView
        view?.setIsMirrored(mirrored)
    }
  }

  override static func requiresMainQueueSetup() -> Bool {
    return true
  }
}
