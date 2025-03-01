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
    
    // MARK: - Session & Season Creation with Participant Copying

    // Creates a new season along with its first session.
    // If a previous season exists, copies its latest session’s participants into the new session.
    func createNewSeason() throws {
        // Ensure that all existing seasons are complete.
        guard allSeasons.allSatisfy({ $0.isCompleted }) else {
            throw SeasonSessionError.incompletePreviousSeason
        }
        
        // Capture the current latest season (if any) before creating a new one.
        let currentLatestSeason = latestSeason
        let nextSeasonNumber = (currentLatestSeason?.seasonNumber ?? 0) + 1
        let newSeason = Season(seasonNumber: nextSeasonNumber)
        let newSession = Session(sessionNumber: 1, season: newSeason)
        
        modelContext.insert(newSeason)
        modelContext.insert(newSession)
        
        // If there is a previous season, find its latest session and copy its participants.
        if let previousSeason = currentLatestSeason {
            if let previousSession = latestSessionInSeason(previousSeason) {
                copyParticipants(from: previousSession, to: newSession)
            }
        }
        
        try modelContext.save()
        fetchSeasons()
        fetchSessions()
    }
    
    // Adds a new session to the specified season.
    // It finds the previous session (from the same season or, if none, from the previous season)
    // and copies its session participants into the new session.
    func createSession(for season: Season) throws {
        // Find sessions already created for this season.
        let sessionsForSeason = allSessions.filter { $0.season.id == season.id }
        let nextSessionNumber = (sessionsForSeason.sorted { $0.sessionNumber > $1.sessionNumber }.first?.sessionNumber ?? 0) + 1
        
        let newSession = Session(sessionNumber: nextSessionNumber, season: season)
        modelContext.insert(newSession)
        
        // Determine the previous session for copying participants.
        if let previousSession = previousSession(for: season) {
            copyParticipants(from: previousSession, to: newSession)
        }
        
        try modelContext.save()
        fetchSessions()
    }
    
    // MARK: - Helper Methods
    
    /// Returns the latest session for the given season.
    private func latestSessionInSeason(_ season: Season) -> Session? {
        let sessionsForSeason = allSessions.filter { $0.season.id == season.id }
        return sessionsForSeason.sorted { $0.sessionNumber > $1.sessionNumber }.first
    }
    
    /// Determines the "previous" session for a given season.
    /// If the season already has sessions, returns its latest session.
    /// Otherwise, if no sessions exist in this season, returns the latest session from the previous season (if available).
    private func previousSession(for season: Season) -> Session? {
        // Check if the season already has sessions.
        let sessionsForSeason = allSessions.filter { $0.season.id == season.id }
        if let session = sessionsForSeason.sorted(by: { $0.sessionNumber > $1.sessionNumber }).first {
            return session
        }
        // Otherwise, try to find the previous season (by seasonNumber) and its latest session.
        if let previousSeason = allSeasons.first(where: { $0.seasonNumber == season.seasonNumber - 1 }) {
            let sessionsForPreviousSeason = allSessions.filter { $0.season.id == previousSeason.id }
            return sessionsForPreviousSeason.sorted(by: { $0.sessionNumber > $1.sessionNumber }).first
        }
        return nil
    }
    
    /// Copies all SessionParticipant records from a previous session into a new session
    private func copyParticipants(from previousSession: Session, to newSession: Session) {
        // Fetch all session participants from the context.
        let descriptor = FetchDescriptor<SessionParticipant>()
        do {
            let participants = try modelContext.fetch(descriptor)
            // Filter the participants that belong to the previous session.
            let previousParticipants = participants.filter { $0.session.uniqueIdentifier == previousSession.uniqueIdentifier }
            for participant in previousParticipants {
                // Create a new participant record for the new session with the same player,
                // but set the team to nil so that it remains unassigned.
                let newParticipant = SessionParticipant(session: newSession, player: participant.player, team: nil)
                // Optionally, copy over additional properties if needed.
                newParticipant.hasPaid = participant.hasPaid
                modelContext.insert(newParticipant)
            }
        } catch {
            print("Error copying participants from previous session: \(error)")
        }
    }

    
    // Updates a season’s completion state.
    func updateSeasonCompletion(_ season: Season, completed: Bool) throws {
        season.isCompleted = completed
        try modelContext.save()
        fetchSeasons()
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
