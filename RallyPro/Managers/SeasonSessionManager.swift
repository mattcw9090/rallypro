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
    
    // Creates a new season along with its first session.
    func createNewSeason() throws {
        // Ensure that all existing seasons are complete.
        guard allSeasons.allSatisfy({ $0.isCompleted }) else {
            throw SeasonSessionError.incompletePreviousSeason
        }
        
        let nextSeasonNumber = (latestSeason?.seasonNumber ?? 0) + 1
        let newSeason = Season(seasonNumber: nextSeasonNumber)
        let newSession = Session(sessionNumber: 1, season: newSeason)
        
        modelContext.insert(newSeason)
        modelContext.insert(newSession)
        try modelContext.save()
        
        fetchSeasons()
        fetchSessions()
    }
    
    // Adds a new session to the specified season.
    func createSession(for season: Season) throws {
        let nextSessionNumber = (latestSession?.sessionNumber ?? 0) + 1
        let newSession = Session(sessionNumber: nextSessionNumber, season: season)
        modelContext.insert(newSession)
        try modelContext.save()
        
        fetchSessions()
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
