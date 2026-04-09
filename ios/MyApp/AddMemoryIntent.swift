import Foundation
import SwiftData
import AppIntents
import UIKit

@available(iOS 17.0, *)
@Model
class Memory {
    var caption: String
    var date: Date
    @Attribute(.externalStorage)
    var imageData: Data
    
    init(caption: String, date: Date = .now, imageData: Data) {
        self.caption = caption
        self.date = date
        self.imageData = imageData
    }
    
    @Transient
    var uiImage: UIImage? {
        UIImage(data: imageData)
    }
}

@available(iOS 17.0, *)
struct AddMemoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Memory"
    
    @Parameter(title: "Choose an image", supportedTypeIdentifiers: ["public.image"])
    var imageFile: IntentFile
    
    @Parameter(title: "Caption")
    var caption: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: Memory.self)
        let context = ModelContext(container)
        
        let imageData = imageFile.data
        let newMemory = Memory(caption: caption, imageData: imageData)
        
        context.insert(newMemory)
        try context.save()
        
        return .result(dialog: "Memory successfully saved via Shortcuts!")
    }
}
