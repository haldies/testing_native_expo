import Foundation
import SwiftData
import React

@available(iOS 17.0, *)
@objc(MemoryModule)
class MemoryModule: NSObject {

  @objc(requiresMainQueueSetup)
  static func requiresMainQueueSetup() -> Bool {
    return true
  }

  @objc(getMemories:reject:)
  func getMemories(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    Task { @MainActor in
      do {
        let container = try ModelContainer(for: Memory.self)
        let context = ModelContext(container)
        
        let fetchDescriptor = FetchDescriptor<Memory>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let memories = try context.fetch(fetchDescriptor)
        
        // Convert to Array of Dictionaries for React Native
        let results = memories.map { memory -> [String: Any] in
            let base64String = memory.imageData.base64EncodedString()
            return [
                "caption": memory.caption,
                "date": memory.date.timeIntervalSince1970, // timestamp
                "imageData": base64String // Send as base64 so JS can show it directly
            ]
        }
        
        resolve(results)
      } catch {
        reject("FETCH_ERROR", "Gagal mengambil memori dari SwiftData", error)
      }
    }
  }
}
