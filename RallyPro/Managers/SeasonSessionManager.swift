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
            sortBy: [SortDescriptor(\Season.seasonNumber, order: .reverse)]
        )
        do {
            allSeasons = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching seasons: \(error)")
        }
    }

    func fetchSessions() {
        let descriptor = FetchDescriptor<Session>(
            sortBy: [SortDescriptor(\Session.sessionNumber, order: .reverse)]
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
}
