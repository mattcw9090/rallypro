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
        case participantTeamAssigned
        case participantNotFound

        var errorDescription: String? {
            switch self {
            case .duplicateName(let name):
                return "A player with the name '\(name)' already exists. Please choose a different name."
            case .noActiveSession:
                return "No active session exists to perform this action."
            case .participantTeamAssigned:
                return "Please unassign the player from the team before changing their status."
            case .participantNotFound:
                return "Player is not found in the current session participants."
            }
        }
    }
    
    /// Creates a new player. (Existing logic remains unchanged.)
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
    
    /// Updates an existing player’s details and handles any status changes.
    func updatePlayer(player: Player,
                      newName: String,
                      newStatus: Player.PlayerStatus,
                      newIsMale: Bool,
                      latestSession: Session?) throws {
        // Trim the new name and ensure uniqueness.
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        if allPlayers.contains(where: { $0.id != player.id && $0.name.lowercased() == trimmedName.lowercased() }) {
            throw PlayerManagerError.duplicateName(trimmedName)
        }
        
        let oldStatus = player.status
        
        switch (oldStatus, newStatus) {
        case (.notInSession, .onWaitlist):
            // When moving from not in session to waitlist,
            // assign the player a waitlist position at the end.
            let waitlistPlayers = allPlayers.filter { $0.status == .onWaitlist }
            let maxPosition = waitlistPlayers.compactMap { $0.waitlistPosition }.max() ?? 0
            player.waitlistPosition = maxPosition + 1
            
        case (.onWaitlist, .notInSession):
            // When leaving the waitlist, remove the position and update others.
            if let removedPosition = player.waitlistPosition {
                player.waitlistPosition = nil
                let waitlistPlayers = allPlayers.filter { $0.status == .onWaitlist }
                for waitlisted in waitlistPlayers {
                    if let pos = waitlisted.waitlistPosition, pos > removedPosition {
                        waitlisted.waitlistPosition = pos - 1
                    }
                }
            }
            
        case (.notInSession, .playing), (.onWaitlist, .playing):
            // To move into playing status, a latest session must exist.
            guard let session = latestSession else {
                throw PlayerManagerError.noActiveSession
            }
            if oldStatus == .onWaitlist, let removedPosition = player.waitlistPosition {
                // If the player was waitlisted, remove them from the waitlist and update positions.
                player.waitlistPosition = nil
                let waitlistPlayers = allPlayers.filter { $0.status == .onWaitlist }
                for waitlisted in waitlistPlayers {
                    if let pos = waitlisted.waitlistPosition, pos > removedPosition {
                        waitlisted.waitlistPosition = pos - 1
                    }
                }
            }
            // Insert a new session participant record.
            let newParticipant = SessionParticipant(session: session, player: player)
            modelContext.insert(newParticipant)
            
        case (.playing, .notInSession), (.playing, .onWaitlist):
            // Removing a player from playing requires deleting the participant record.
            guard let session = latestSession else {
                throw PlayerManagerError.noActiveSession
            }
            // Fetch all session participants without a predicate.
            let descriptor = FetchDescriptor<SessionParticipant>()
            let allParticipants = try modelContext.fetch(descriptor)
            // Now filter in memory.
            guard let participantRecord = allParticipants.first(where: { $0.session == session && $0.player == player }) else {
                throw PlayerManagerError.participantNotFound
            }
            if participantRecord.team != nil {
                throw PlayerManagerError.participantTeamAssigned
            }
            modelContext.delete(participantRecord)
            if newStatus == .onWaitlist {
                // If switching to waitlist, assign a new waitlist position.
                let waitlistPlayers = allPlayers.filter { $0.status == .onWaitlist }
                let maxPosition = waitlistPlayers.compactMap { $0.waitlistPosition }.max() ?? 0
                player.waitlistPosition = maxPosition + 1
            }
            
        default:
            break
        }
        
        // Finally, update the player's basic properties.
        player.name = trimmedName
        player.status = newStatus
        player.isMale = newIsMale
        
        try modelContext.save()
        fetchAllPlayers()
    }
}
