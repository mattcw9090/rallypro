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
    
    enum PlayerManagerError: LocalizedError {
        case duplicateName(String)
        case noActiveSession

        var errorDescription: String? {
            switch self {
            case .duplicateName(let name):
                return "A player with the name '\(name)' already exists. Please choose a different name."
            case .noActiveSession:
                return "No active session exists to add the player."
            }
        }
    }
    
    func addPlayer(name: String, status: Player.PlayerStatus, isMale: Bool, latestSession: Session?) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if allPlayers.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            throw PlayerManagerError.duplicateName(trimmedName)
        }
        let newPlayer = Player(name: trimmedName, status: status, isMale: isMale)
        if status == .onWaitlist {
            let currentMaxPosition = allPlayers
                .filter { $0.status == .onWaitlist }
                .compactMap { $0.waitlistPosition }
                .max() ?? 0
            newPlayer.waitlistPosition = currentMaxPosition + 1
        }
        else if status == .playing {
            guard let session = latestSession else {
                throw PlayerManagerError.noActiveSession
            }
            let sessionParticipantsRecord = SessionParticipant(session: session, player: newPlayer)
            modelContext.insert(sessionParticipantsRecord)
        }
        modelContext.insert(newPlayer)
        try modelContext.save()
        fetchAllPlayers()
    }
}
