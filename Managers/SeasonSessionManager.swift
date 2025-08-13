import SwiftData
import SwiftUI

class SeasonSessionManager: ObservableObject {
    private var modelContext: ModelContext

    @Published var allSeasons: [Season] = []
    @Published var allSessions: [Session] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchSeasons()
        fetchSessions()
    }

    func fetchSeasons() {
        let descriptor = FetchDescriptor<Season>(
            sortBy: [SortDescriptor(\.seasonNumber, order: .reverse)]
        )
        do {
            allSeasons = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching seasons: \(error)")
        }
    }

    func fetchSessions() {
        let descriptor = FetchDescriptor<Session>(
            sortBy: [SortDescriptor(\.sessionNumber, order: .reverse)]
        )
        do {
            allSessions = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching sessions: \(error)")
        }
    }

    var latestSeason: Season? {
        allSeasons.first
    }
    
    var latestSession: Session? {
        guard let season = latestSeason else { return nil }
        return allSessions.first { $0.season == season }
    }
    
    func createNewSeason() throws {
        guard allSeasons.allSatisfy({ $0.isCompleted }) else {
            throw SeasonSessionError.incompletePreviousSeason
        }
        
        let currentLatestSeason = latestSeason
        let nextSeasonNumber = (currentLatestSeason?.seasonNumber ?? 0) + 1
        let newSeason = Season(seasonNumber: nextSeasonNumber)
        let newSession = Session(sessionNumber: 1, season: newSeason)
        
        modelContext.insert(newSeason)
        modelContext.insert(newSession)
        
        if let previousSeason = currentLatestSeason {
            if let previousSession = latestSessionInSeason(previousSeason) {
                copyParticipants(from: previousSession, to: newSession)
            }
        }
        
        try modelContext.save()
        fetchSeasons()
        fetchSessions()
    }
    
    func createSession(for season: Season) throws {
        let sessionsForSeason = allSessions.filter { $0.season.id == season.id }
        let nextSessionNumber = (sessionsForSeason.sorted { $0.sessionNumber > $1.sessionNumber }.first?.sessionNumber ?? 0) + 1
        
        let newSession = Session(sessionNumber: nextSessionNumber, season: season)
        modelContext.insert(newSession)
        
        if let previousSession = previousSession(for: season) {
            copyParticipants(from: previousSession, to: newSession)
        }
        
        try modelContext.save()
        fetchSessions()
    }
    
    private func latestSessionInSeason(_ season: Season) -> Session? {
        let sessionsForSeason = allSessions.filter { $0.season.id == season.id }
        return sessionsForSeason.sorted { $0.sessionNumber > $1.sessionNumber }.first
    }
    
    private func previousSession(for season: Season) -> Session? {
        let sessionsForSeason = allSessions.filter { $0.season.id == season.id }
        if let session = sessionsForSeason.sorted(by: { $0.sessionNumber > $1.sessionNumber }).first {
            return session
        }
        if let previousSeason = allSeasons.first(where: { $0.seasonNumber == season.seasonNumber - 1 }) {
            let sessionsForPreviousSeason = allSessions.filter { $0.season.id == previousSeason.id }
            return sessionsForPreviousSeason.sorted(by: { $0.sessionNumber > $1.sessionNumber }).first
        }
        return nil
    }
    
    private func copyParticipants(from previousSession: Session, to newSession: Session) {
        let descriptor = FetchDescriptor<SessionParticipant>()
        do {
            let participants = try modelContext.fetch(descriptor)
            let previousParticipants = participants.filter { $0.session.uniqueIdentifier == previousSession.uniqueIdentifier }
            for participant in previousParticipants {
                let newParticipant = SessionParticipant(session: newSession, player: participant.player, team: nil)
                newParticipant.hasPaid = participant.hasPaid
                modelContext.insert(newParticipant)
            }
        } catch {
            print("Error copying participants from previous session: \(error)")
        }
    }
    
    func updateSeasonCompletion(_ season: Season, completed: Bool) throws {
        season.isCompleted = completed
        try modelContext.save()
        fetchSeasons()
    }
    
    func deleteLatestSession(for season: Season) throws {
        guard let sessionToDelete = latestSessionInSeason(season) else { return }
        
        let descriptor = FetchDescriptor<SessionParticipant>()
        let allParticipants = try modelContext.fetch(descriptor)
        let sessionParticipantsToDelete = allParticipants.filter { $0.session.uniqueIdentifier == sessionToDelete.uniqueIdentifier }
        if !sessionParticipantsToDelete.isEmpty {
            throw SessionDeletionError.sessionHasParticipants
        }
        
        modelContext.delete(sessionToDelete)
        try modelContext.save()
        fetchSessions()
        
        if let newLatestSession = latestSessionInSeason(season) {
            let updatedParticipants = try modelContext.fetch(descriptor)
            let newSessionParticipants = updatedParticipants.filter { $0.session.uniqueIdentifier == newLatestSession.uniqueIdentifier }
            
            for participant in newSessionParticipants {
                let player = participant.player
                switch player.status {
                case .notInSession:
                    player.status = .playing
                case .onWaitlist:
                    if let removedPosition = player.waitlistPosition {
                        player.waitlistPosition = nil
                        player.status = .playing
                        let descriptorPlayers = FetchDescriptor<Player>()
                        let allPlayers = try modelContext.fetch(descriptorPlayers)
                        for p in allPlayers {
                            if p.status == .onWaitlist, let pos = p.waitlistPosition, pos > removedPosition {
                                p.waitlistPosition = pos - 1
                            }
                        }
                    }
                default:
                    break
                }
            }
            try modelContext.save()
            fetchSessions()
        }
    }
}

enum SeasonSessionError: LocalizedError {
    case incompletePreviousSeason

    var errorDescription: String? {
        switch self {
        case .incompletePreviousSeason:
            return "All previous seasons must be marked as completed before adding a new season."
        }
    }
}

enum SessionDeletionError: LocalizedError {
    case sessionHasParticipants

    var errorDescription: String? {
        switch self {
        case .sessionHasParticipants:
            return "The latest session cannot be deleted because it has session participants."
        }
    }
}
