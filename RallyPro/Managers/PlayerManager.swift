import SwiftData
import SwiftUI

class PlayerManager: ObservableObject {
    private var modelContext: ModelContext

    @Published var allPlayers: [Player] = []
    
    var waitlistPlayers: [Player] {
        allPlayers.filter { $0.status == .onWaitlist }
                  .sorted { ($0.waitlistPosition ?? 0) < ($1.waitlistPosition ?? 0) }
    }

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
    
    func searchPlayers(searchText: String) -> [Player] {
        guard !searchText.isEmpty else {
            return allPlayers
        }
        return allPlayers.filter { player in
            player.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func addNewPlayerToWaitlist(_ player: Player) {
        guard player.status == .notInSession else { return }
        let currentMaxPosition = waitlistPlayers
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
    
    func addPlayer(name: String, status: Player.PlayerStatus, isMale: Bool, latestSession: Session?) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if allPlayers.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            throw PlayerManagerError.duplicateName(trimmedName)
        }
        let newPlayer = Player(name: trimmedName, status: status, isMale: isMale)
        if status == .onWaitlist {
            let currentMaxPosition = waitlistPlayers
                .compactMap { $0.waitlistPosition }
                .max() ?? 0
            newPlayer.waitlistPosition = currentMaxPosition + 1
        } else if status == .playing {
            guard let session = latestSession else {
                throw PlayerManagerError.noActiveSession
            }
            let sessionParticipant = SessionParticipant(session: session, player: newPlayer)
            modelContext.insert(sessionParticipant)
        }
        modelContext.insert(newPlayer)
        try modelContext.save()
        fetchAllPlayers()
    }
    
    func updatePlayerInfo(player: Player,
                      newName: String,
                      newStatus: Player.PlayerStatus,
                      newIsMale: Bool,
                      latestSession: Session?) throws {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        if allPlayers.contains(where: { $0.id != player.id && $0.name.lowercased() == trimmedName.lowercased() }) {
            throw PlayerManagerError.duplicateName(trimmedName)
        }
        
        let oldStatus = player.status
        
        switch (oldStatus, newStatus) {
        case (.notInSession, .onWaitlist):
            let maxPosition = waitlistPlayers.compactMap { $0.waitlistPosition }.max() ?? 0
            player.waitlistPosition = maxPosition + 1
        
        case (.onWaitlist, .notInSession):
            if let removedPosition = player.waitlistPosition {
                player.waitlistPosition = nil
                for waitlisted in waitlistPlayers where (waitlisted.waitlistPosition ?? 0) > removedPosition {
                    waitlisted.waitlistPosition = (waitlisted.waitlistPosition ?? 0) - 1
                }
            }
        
        case (.notInSession, .playing), (.onWaitlist, .playing):
            guard let session = latestSession else {
                throw PlayerManagerError.noActiveSession
            }
            if oldStatus == .onWaitlist, let removedPosition = player.waitlistPosition {
                player.waitlistPosition = nil
                for waitlisted in waitlistPlayers where (waitlisted.waitlistPosition ?? 0) > removedPosition {
                    waitlisted.waitlistPosition = (waitlisted.waitlistPosition ?? 0) - 1
                }
            }
            let sessionParticipant = SessionParticipant(session: session, player: player)
            modelContext.insert(sessionParticipant)
        
        case (.playing, .notInSession), (.playing, .onWaitlist):
            guard let session = latestSession else {
                throw PlayerManagerError.noActiveSession
            }
            let descriptor = FetchDescriptor<SessionParticipant>()
            let allParticipants = try modelContext.fetch(descriptor)
            guard let participantRecord = allParticipants.first(where: { $0.session == session && $0.player == player }) else {
                throw PlayerManagerError.participantNotFound
            }
            if participantRecord.team != nil {
                throw PlayerManagerError.participantTeamAssigned
            }
            modelContext.delete(participantRecord)
            if newStatus == .onWaitlist {
                let maxPosition = waitlistPlayers.compactMap { $0.waitlistPosition }.max() ?? 0
                player.waitlistPosition = maxPosition + 1
            }
        
        default:
            break
        }
        
        player.name = trimmedName
        player.status = newStatus
        player.isMale = newIsMale
        
        try modelContext.save()
        fetchAllPlayers()
    }
    
    func movePlayerFromWaitlistToCurrentSession(_ player: Player, session: Session?) throws {
        guard let session = session else {
            throw PlayerManagerError.noActiveSession
        }
        guard let removedPosition = player.waitlistPosition else { return }
        
        player.status = .playing
        player.waitlistPosition = nil
        
        for affectedPlayer in waitlistPlayers where (affectedPlayer.waitlistPosition ?? 0) > removedPosition {
            affectedPlayer.waitlistPosition = (affectedPlayer.waitlistPosition ?? 0) - 1
        }
        
        let sessionParticipant = SessionParticipant(session: session, player: player)
        modelContext.insert(sessionParticipant)
        
        try modelContext.save()
        fetchAllPlayers()
    }
    
    func moveWaitlistPlayerToBottom(_ player: Player) throws {
        guard let currentPosition = player.waitlistPosition else { return }
        
        for belowPlayer in waitlistPlayers where (belowPlayer.waitlistPosition ?? 0) > currentPosition {
            belowPlayer.waitlistPosition = (belowPlayer.waitlistPosition ?? 0) - 1
        }
        
        let newMaxPosition = waitlistPlayers.count
        player.waitlistPosition = newMaxPosition
        
        try modelContext.save()
        fetchAllPlayers()
    }
    
    func removeFromWaitlist(_ player: Player) throws {
        guard let removedPosition = player.waitlistPosition else { return }
        
        player.status = .notInSession
        player.waitlistPosition = nil
        
        for affectedPlayer in waitlistPlayers where (affectedPlayer.waitlistPosition ?? 0) > removedPosition {
            affectedPlayer.waitlistPosition = (affectedPlayer.waitlistPosition ?? 0) - 1
        }
        
        try modelContext.save()
        fetchAllPlayers()
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
