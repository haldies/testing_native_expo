import Foundation
import AppIntents
import UIKit

@available(iOS 16.0, *)
struct MyAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddMemoryIntent(),
            phrases: [
                "Add a memory in \(.applicationName)",
                "Save memory to \(.applicationName)"
            ],
            shortTitle: "Add Memory",
            systemImageName: "photo.badge.plus"
        )
    }
    
    static var shortcutTileColor: ShortcutTileColor = .orange
}

// 2. LOGIC INTENT (SIRI)
@available(iOS 16.0, *)
struct AddMemoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Memory"
    
    @Parameter(title: "Choose an image", supportedTypeIdentifiers: ["public.image"])
    var imageFile: IntentFile
    
    @Parameter(title: "Caption")
    var caption: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let imageData = imageFile.data
        
        // Kita menggunakan UserDefaults (Didukung semua versi iOS)
        // SwiftData sangat rawan force close jika iPhone Anda bukan versi terbaru
        let newMemory: [String: Any] = [
            "caption": caption,
            "date": Date().timeIntervalSince1970,
            "imageData": imageData.base64EncodedString()
        ]
        
        let defaults = UserDefaults.standard
        var memories = defaults.array(forKey: "SiriMemories") as? [[String: Any]] ?? []
        memories.insert(newMemory, at: 0) // Simpan di urutan teratas
        defaults.set(memories, forKey: "SiriMemories")
        
        return .result(dialog: "Berhasil! Memory sudah disimpan via Siri.")
    }
}
