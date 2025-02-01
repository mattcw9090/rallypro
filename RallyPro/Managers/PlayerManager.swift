import SwiftData
import SwiftUI

class PlayerManager: ObservableObject{
    private var modelContext: ModelContext
    
    @Published var allPlayers: [Player] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchAllPlayers()
    }
    
    func fetchAllPlayers() {
        let descriptor = FetchDescriptor<Player>(sortBy: [SortDescriptor(\.name)])
        
        do {
            allPlayers = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching players: \(error)")
        }
    }
}
