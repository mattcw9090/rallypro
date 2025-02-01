import SwiftData
import SwiftUI

class PlayerManager: ObservableObject {
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

    func filteredPlayers(searchText: String) -> [Player] {
        guard !searchText.isEmpty else {
            return allPlayers
        }
        return allPlayers.filter { player in
            player.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func addToWaitlist(_ player: Player) {
        guard player.status == .notInSession else { return }
        let currentMaxPosition = allPlayers
            .filter { $0.status == .onWaitlist }
            .compactMap { $0.waitlistPosition }
            .max() ?? 0
        player.status = .onWaitlist
        player.waitlistPosition = currentMaxPosition + 1
        
        do {
            try modelContext.save()
            fetchAllPlayers()
        } catch {
            print("Error adding player to waitlist: \(error)")
        }
    }
}
