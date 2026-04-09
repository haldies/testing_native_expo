import Foundation
import React
import AppIntents

@objc(MemoryModule)
class MemoryModule: NSObject {

  @objc(requiresMainQueueSetup)
  static func requiresMainQueueSetup() -> Bool {
    return true
  }

  @objc(getMemories:reject:)
  func getMemories(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
     let defaults = UserDefaults.standard
     let memories = defaults.array(forKey: "SiriMemories") as? [[String: Any]] ?? []
     resolve(memories)
  }

  @objc(refreshShortcuts:reject:)
  func refreshShortcuts(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    if #available(iOS 16.0, *) {
      AppShortcutsCenter.shared.updateAppShortcutParameters()
      resolve(true)
    } else {
      resolve(false)
    }
  }
}
