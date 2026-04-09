import Foundation
import React
import AVFoundation

@objc(MemoryModule)
class MemoryModule: NSObject {

  @objc(requiresMainQueueSetup)
  static func requiresMainQueueSetup() -> Bool {
    return true
  }

  @objc(getMemories:reject:)
  func getMemories(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
     resolve([])
  }

  @objc(refreshShortcuts:reject:)
  func refreshShortcuts(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
     resolve(false)
  }

  @objc(checkMultiCamSupport:reject:)
  func checkMultiCamSupport(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    if #available(iOS 13.0, *) {
      resolve(AVCaptureMultiCamSession.isMultiCamSupported)
    } else {
      resolve(false)
    }
  }
}
