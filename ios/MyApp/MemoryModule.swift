import Foundation
import React

@objc(MemoryModule)
class MemoryModule: NSObject {

  @objc(requiresMainQueueSetup)
  static func requiresMainQueueSetup() -> Bool {
    return true
  }

  @objc(getMemories:reject:)
  func getMemories(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
     // Mengambil data murni dari UserDefaults, Tanpa iOS 17 Requirement
     let defaults = UserDefaults.standard
     let memories = defaults.array(forKey: "SiriMemories") as? [[String: Any]] ?? []
     
     // Kirim array lansung ke JavaScript React Native
     resolve(memories)
  }
}
